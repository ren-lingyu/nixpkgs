''
  ;;; -*- lexical-binding: t; -*-
  ;; Compare semantic projections, excluding positions and blank counts.
  ;; Babel's light reader extracts code without executing it or loading languages.
  (require 'org)
  (require 'org-element)
  (require 'ob-core)
  (require 'subr-x)

  (defun org-fmt-test-clean (value)
    (cond ((stringp value) (substring-no-properties value))
          ((consp value) (mapcar #'org-fmt-test-clean value))
          (t value)))

  (defun org-fmt-test-timestamp (timestamp)
    (when timestamp
      (mapcar (lambda (key) (org-element-property key timestamp))
              '(:type :year-start :month-start :day-start :hour-start :minute-start
                :year-end :month-end :day-end :hour-end :minute-end
                :repeater-type :repeater-value :repeater-unit
                :warning-type :warning-value :warning-unit))))

  (defun org-fmt-test-projection (file)
    (with-temp-buffer
      (insert-file-contents file)
      (org-mode)
      (let ((ast (org-element-parse-buffer)) result)
        (org-element-map ast org-element-all-elements
          (lambda (node)
            (let* ((type (org-element-type node))
                   (keys
                    (pcase type
                      ('headline '(:level :raw-value :todo-keyword :priority :tags
                                   :commentedp :archivedp))
                      ('node-property '(:key :value))
                      ('drawer '(:drawer-name))
                      ('plain-list '(:type))
                      ('item '(:checkbox :counter))
                      ('footnote-definition '(:label))
                      ('keyword '(:key :value))
                      ('special-block '(:type))
                      ('export-block '(:type :value))
                      ('example-block '(:value))
                      ('table '(:type :tblfm))
                      ('table-row '(:type))
                      (_ nil)))
                   (values (mapcar (lambda (key) (org-element-property key node)) keys)))
              (pcase type
                ('item
                 ;; Org renumbers an ordered bullet with an explicit [@counter].
                 ;; Keep its delimiter/style and the parsed counter, not spelling.
                 (push (replace-regexp-in-string
                        "^[0-9]+" "" (org-element-property :bullet node)) values)
                 (push (org-element-interpret-data (org-element-property :tag node)) values))
                ('planning
                 (setq values (mapcar
                               (lambda (key)
                                 (org-fmt-test-timestamp (org-element-property key node)))
                               '(:closed :scheduled :deadline))))
                ('src-block
                 (goto-char (org-element-property :begin node))
                 (let ((info (org-babel-get-src-block-info 'light)))
                   (setq values (list (nth 0 info) (nth 1 info)
                                      (org-element-property :switches node)
                                      (org-element-property :parameters node)))))
                ((or 'paragraph 'table-cell)
                 (setq values (list (string-trim
                                     (org-element-interpret-data
                                      (org-element-contents node)))))))
              (push (list type values
                          ;; Preserve containment, especially list/footnote scope.
                          (mapcar (lambda (parent)
                                    (list (org-element-type parent)
                                          (org-element-property :raw-value parent)))
                                  (org-element-lineage node))
                          (org-element-property :name node)
                          (org-element-property :attr_html node)
                          (org-element-property :attr_latex node)
                          (org-element-property :header node)
                          (mapcar (lambda (caption)
                                    (org-element-interpret-data caption))
                                  (org-element-property :caption node)))
                    result))))
        (org-fmt-test-clean (nreverse result)))))

  (let* ((files command-line-args-left)
         (before (org-fmt-test-projection (car files)))
         (after (org-fmt-test-projection (cadr files))))
    (unless (equal before after)
      (princ (format "Semantic mismatch\nBEFORE: %S\nAFTER: %S\n" before after))
      (kill-emacs 1)))
''
