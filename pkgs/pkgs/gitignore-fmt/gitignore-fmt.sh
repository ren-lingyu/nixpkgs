# Canonicalize the project's three-section .gitignore convention.
# Requires Bash >= 4 and GNU coreutils (sort, cmp, mktemp, cat).
set -euo pipefail

usage() {
  printf 'Usage: %s [--check] FILE [FILE ...]\n' "${0##*/}" >&2
  exit 2
}

check=0
if [[ ${1-} == --check ]]; then
  check=1
  shift
fi
if (($# == 0)); then usage; fi

workdir=$(mktemp -d)
trap 'rm -rf -- "$workdir"' EXIT

format_file() {
  local file=$1 idx=$2
  local basedir=$workdir/$idx
  local segment=0 id=0 last_phase=0 phase group rest line pending='' s
  local seen_star=0 seen_dir=0
  local output_phase='' output_group='' first_record
  local record_phase record_group record_line record_id
  local raw sorted rendered
  local -a comments=() barriers=()

  if [[ ! -f $file ]]; then
    printf 'gitignore-fmt: not a regular file: %s\n' "$file" >&2
    return 2
  fi

  mkdir -p -- "$basedir"
  rendered=$basedir/rendered
  : >"$basedir/0"

  # A blank line breaks comment attachment. A detached comment block is a
  # sorting barrier, so it can be preserved without guessing its meaning.
  while IFS= read -r line || [[ -n $line ]]; do
    # Normalize CRLF to LF, but do not trim Git patterns (whitespace matters).
    line=${line%$'\r'}
    if [[ -z $line ]]; then
      if [[ -n $pending ]]; then
        ((segment += 1))
        barriers[segment]=$pending
        pending=''
        : >"$basedir/$segment"
      fi
      continue
    fi
    if [[ $line == \#* ]]; then
      pending+="$line"$'\n'
      continue
    fi
    if [[ $line == *$'\037'* ]]; then
      printf 'gitignore-fmt: unsupported control character in %s: %q\n' "$file" "$line" >&2
      return 2
    fi

    group=''
    case $line in
    '*')
      phase=0
      if ((seen_star)); then
        printf 'gitignore-fmt: duplicate * header: %s\n' "$file" >&2
        return 2
      fi
      seen_star=1
      ;;
    '*/')
      phase=0
      if ((seen_dir)); then
        printf 'gitignore-fmt: duplicate */ header: %s\n' "$file" >&2
        return 2
      fi
      seen_dir=1
      ;;
    '!'*)
      phase=1
      if [[ $line == '!' ]]; then
        printf 'gitignore-fmt: empty negation: %s\n' "$file" >&2
        return 2
      fi
      if [[ $line != '!/'* ]]; then
        line="!/${line:1}"
      fi
      rest=${line:2}
      if [[ -z $rest ]]; then
        printf 'gitignore-fmt: empty negation path: %s\n' "$file" >&2
        return 2
      fi
      # Root entries share the empty key. Everything below a top-level
      # directory (including the directory itself) shares its first part.
      if [[ $rest == */* ]]; then
        group=${rest%%/*}
      fi
      ;;
    *) phase=2 ;;
    esac

    if ((phase < last_phase)); then
      printf 'gitignore-fmt: invalid section order in %s: %s\n' "$file" "$line" >&2
      return 2
    fi
    last_phase=$phase

    if ((phase == 0)); then
      # The two fixed header lines must come first in output. Any leading
      # comments on them become detached, rather than moving above the header.
      if [[ -n $pending ]]; then
        ((segment += 1))
        barriers[segment]=$pending
        pending=''
        : >"$basedir/$segment"
      fi
      continue
    fi

    comments[id]=$pending
    pending=''
    printf '%s\037%s\037%s\037%s\n' "$phase" "$group" "$line" "$id" >>"$basedir/$segment"
    ((id += 1))
  done <"$file"

  if [[ -n $pending ]]; then
    ((segment += 1))
    barriers[segment]=$pending
    : >"$basedir/$segment"
  fi

  # The canonical header is fixed, irrespective of what was originally present.
  printf '*\n*/\n' >"$rendered"
  for ((s = 0; s <= segment; s++)); do
    if [[ -n ${barriers[s]-} ]]; then
      printf '\n%s' "${barriers[s]}" >>"$rendered"
    fi

    raw=$basedir/$s
    [[ -s $raw ]] || continue
    sorted=$basedir/$s.sorted
    LC_ALL=C sort -s -t $'\037' -k1,1n -k2,2 -k3,3 "$raw" >"$sorted"
    first_record=1
    output_phase=''
    output_group=''
    while IFS=$'\037' read -r record_phase record_group record_line record_id; do
      if ((first_record)); then
        printf '\n' >>"$rendered"
      elif [[ $record_phase != "$output_phase" ]] || { [[ $record_phase == 1 ]] && [[ $record_group != "$output_group" ]]; }; then
        printf '\n' >>"$rendered"
      fi
      printf '%s%s\n' "${comments[record_id]-}" "$record_line" >>"$rendered"
      output_phase=$record_phase
      output_group=$record_group
      first_record=0
    done <"$sorted"
  done

  if ! cmp -s -- "$file" "$rendered"; then
    if ((check)); then
      printf 'Not formatted: %s\n' "$file" >&2
      return 1
    fi
    cat -- "$rendered" >"$file"
    printf 'Formatted: %s\n' "$file"
  fi
}

status=0
index=0
for file in "$@"; do
  if format_file "$file" "$index"; then
    :
  else
    code=$?
    ((code > status)) && status=$code
  fi
  ((index += 1))
done
exit "$status"
