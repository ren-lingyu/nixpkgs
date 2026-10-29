;;; org-fmt.el --- Format Org files through native AST serialization -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Parse and serialize Org files using Org's native AST machinery.
;; Custom transformations only remove blank lines owned by headlines and
;; their leading planning, property-drawer and drawer elements.
;;
;; Other normalization is delegated to Org's serializer.  Embedded source
;; languages and custom special blocks receive no additional processing.
;;
;; Usage: org-fmt [--check] [--] FILE...

;;; Code:

(require 'org)
(require 'org-element)

(defun org-fmt--normalize-headlines (ast)
  "Normalize headline header spacing in AST."
  (org-element-map
   ast 'headline
   (lambda (headline)
     (org-element-put-property headline :pre-blank 0)
     (org-element-put-property headline :post-blank 0)
     (let ((section (car (org-element-contents headline))))
       (when (eq (org-element-type section) 'section)
         (let ((elements (org-element-contents section)))
           (while (and elements
                       (memq
                        (org-element-type (car elements))
                        '(planning property-drawer drawer)))
             (org-element-put-property (car elements) :post-blank 0)
             (setq elements (cdr elements))))))))
  ast)

(defun org-fmt--render (file)
  "Render FILE through Org's native AST serializer."
  (with-temp-buffer
    (insert-file-contents file)
    (let ((org-inhibit-startup t)
          (org-src-content-indentation 2)
          (org-tags-column 77)
          (org-odd-levels-only nil))
      (org-mode)
      (org-element-interpret-data
       (org-fmt--normalize-headlines (org-element-parse-buffer))))))

(defun org-fmt--file-bytes (file)
  "Read FILE without modifying its bytes."
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert-file-contents-literally file)
    (buffer-string)))

(defun org-fmt--write-atomically (file result)
  "Replace FILE with RESULT using a nearby temporary file."
  (let ((tmp (make-nearby-temp-file (expand-file-name file))))
    (unwind-protect
        (progn
          (let ((coding-system-for-write 'utf-8-unix))
            (write-region result nil tmp nil 'silent))
          (set-file-modes tmp (file-modes file))
          (rename-file tmp file t)
          (setq tmp nil))
      (when (and tmp (file-exists-p tmp))
        (delete-file tmp)))))

(defun org-fmt--format-file (file check)
  "Format FILE, or compare without writing when CHECK is non-nil.
Return non-nil if changes are necessary."
  (when (file-symlink-p file)
    (error "refusing to modify a symbolic link"))
  (unless (file-regular-p file)
    (error "not a regular file"))
  (let* ((result (org-fmt--render file))
         (changed
          (not
           (equal
            (org-fmt--file-bytes file)
            (encode-coding-string result 'utf-8-unix)))))
    (when changed
      (if check
          (message "org-fmt: needs formatting: %s" file)
        (org-fmt--write-atomically file result)))
    changed))

(defun org-fmt--main (args)
  "Format filenames in ARGS, optionally with --check."
  (let ((check nil)
        (changed nil)
        (failed nil))
    (when (member (car args) '("--help" "-h"))
      (princ "Usage: org-fmt [--check] [--] FILE...\n")
      (kill-emacs 0))
    (when (equal (car args) "--check")
      (setq
       check t
       args (cdr args)))
    (cond
     ((equal (car args) "--")
      (setq args (cdr args)))
     ((and args (string-prefix-p "-" (car args)))
      (message
       "org-fmt: unknown option: %s (use -- before filenames beginning with -)"
       (car args))
      (kill-emacs 2)))
    (unless args
      (message "org-fmt: Usage: org-fmt [--check] [--] FILE...")
      (kill-emacs 2))
    (dolist (file args)
      (condition-case err
          (when (org-fmt--format-file file check)
            (setq changed t))
        (error
         (setq failed t)
         (message "org-fmt: %s: %s"
                  file
                  (error-message-string err)))))
    (kill-emacs
     (cond
      (failed
       2)
      ((and check changed)
       1)
      (t
       0)))))

(org-fmt--main command-line-args-left)

;;; org-fmt.el ends here
