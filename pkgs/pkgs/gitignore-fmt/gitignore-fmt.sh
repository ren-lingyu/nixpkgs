# Canonicalize the project's three-section .gitignore convention.
# Requires Bash >= 4, GNU coreutils and diffutils.
set -euo pipefail

usage() {
  printf 'Usage: %s [--check] [--] FILE [FILE ...]\n' "${0##*/}" >&2
  exit 2
}

error() {
  printf 'gitignore-fmt: %s\n' "$*" >&2
}

check=0
while (($#)); do
  case $1 in
  --check)
    check=1
    shift
    ;;
  --)
    shift
    break
    ;;
  -*) usage ;;
  *) break ;;
  esac
done
if (($# == 0)); then usage; fi

workdir=$(mktemp -d) || {
  error 'cannot create temporary directory'
  exit 2
}
trap 'rm -rf -- "$workdir"' EXIT
trap 'exit 2' HUP INT TERM

# The caller uses an if condition, so every failing operation must be checked.
render_file() {
  local input=$1 basedir=$2 file=$3
  local segment=0 id=0 last_phase=0 phase group rest line pending='' s
  local seen_star=0 seen_dir=0
  local output_phase='' output_group='' first_record
  local record_phase record_group record_line record_id
  local raw sorted
  local -a comments=() barriers=()

  # Bash read otherwise silently discards NUL bytes.
  if IFS= read -r -d '' line <"$input"; then
    error "unsupported NUL byte in $file"
    return 2
  fi
  : >"$basedir/0" || return 2

  # A blank line breaks comment attachment. A detached comment block is a
  # sorting barrier, so it can be preserved without guessing its meaning.
  while IFS= read -r line || [[ -n $line ]]; do
    # Normalize CRLF to LF, but do not trim Git patterns (whitespace matters).
    line=${line%$'\r'}
    if [[ $line == *$'\037'* ]]; then
      error "unsupported control character in $file"
      return 2
    fi
    if [[ -z $line ]]; then
      if [[ -n $pending ]]; then
        ((segment += 1))
        barriers[segment]=$pending
        pending=''
        : >"$basedir/$segment" || return 2
      fi
      continue
    fi
    if [[ $line == \#* ]]; then
      pending+="$line"$'\n'
      continue
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
        : >"$basedir/$segment" || return 2
      fi
      continue
    fi

    comments[id]=$pending
    pending=''
    printf '%s\037%s\037%s\037%s\n' "$phase" "$group" "$line" "$id" >>"$basedir/$segment" || return 2
    ((id += 1))
  done <"$input" || return 2

  if [[ -n $pending ]]; then
    ((segment += 1))
    barriers[segment]=$pending
    : >"$basedir/$segment" || return 2
  fi

  # The canonical header is fixed, irrespective of what was originally present.
  printf '*\n*/\n' || return 2
  for ((s = 0; s <= segment; s++)); do
    if [[ -n ${barriers[s]-} ]]; then
      printf '\n%s' "${barriers[s]}" || return 2
    fi

    raw=$basedir/$s
    [[ -s $raw ]] || continue
    sorted=$basedir/$s.sorted
    LC_ALL=C sort -s -t $'\037' -k1,1n -k2,2 -k3,3 "$raw" >"$sorted" || return 2
    first_record=1
    output_phase=''
    output_group=''
    while IFS=$'\037' read -r record_phase record_group record_line record_id; do
      if ((first_record)); then
        printf '\n' || return 2
      elif [[ $record_phase != "$output_phase" ]] || { [[ $record_phase == 1 ]] && [[ $record_group != "$output_group" ]]; }; then
        printf '\n' || return 2
      fi
      printf '%s%s\n' "${comments[record_id]-}" "$record_line" || return 2
      output_phase=$record_phase
      output_group=$record_group
      first_record=0
    done <"$sorted" || return 2
  done

}

format_file() (
  local file=$1 basedir=$workdir/$2 replacement='' code
  trap 'if [[ -n $replacement ]]; then rm -f -- "$replacement"; fi' EXIT
  if [[ -L $file ]]; then
    error "symbolic links are not supported: $file"
    return 2
  fi
  if [[ ! -f $file ]]; then
    error "not a regular file: $file"
    return 2
  fi

  mkdir -- "$basedir" || {
    error "cannot create workspace for $file"
    return 2
  }
  cp -- "$file" "$basedir/input" || {
    error "cannot read $file"
    return 2
  }
  render_file "$basedir/input" "$basedir" "$file" >"$basedir/rendered" || {
    error "cannot render $file"
    return 2
  }
  if cmp -s -- "$basedir/input" "$basedir/rendered"; then
    return 0
  else
    code=$?
    if ((code != 1)); then
      error "cannot compare $file"
      return 2
    fi
  fi
  if ((check)); then
    printf 'Not formatted: %s\n' "$file" >&2
    return 1
  fi

  # Write completely before replacing the original; keep its permissions.
  replacement=$(mktemp -- "${file}.gitignore-fmt.XXXXXXXX") || {
    error "cannot create replacement for $file"
    return 2
  }
  cp --preserve=mode -- "$file" "$replacement" || {
    error "cannot preserve permissions for $file"
    return 2
  }
  cat -- "$basedir/rendered" >"$replacement" || {
    error "cannot write replacement for $file"
    return 2
  }
  mv -f -- "$replacement" "$file" || {
    error "cannot replace $file"
    return 2
  }
  replacement=''
  printf 'Formatted: %s\n' "$file" || return 2
)

status=0
index=0
for file in "$@"; do
  if format_file "$file" "$index"; then
    :
  else
    code=$?
    if ((code > status)); then status=$code; fi
  fi
  ((index += 1))
done
exit "$status"
