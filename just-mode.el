;;; just-ts-mode.el --- Justfile editing mode -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Sony Corporation of America and Leon Barrett

;; Author: Leon Barrett (leon@barrettnexus.com)
;; Maintainer: Leon Barrett (leon@barrettnexus.com)
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: files languages tools
;; URL: https://github.com/leon-barrett/just-mode.el

;; This file is *NOT* part of GNU Emacs

;; This package is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This package is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this package.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode for editing justfiles, as defined by the tool "just":
;; https://github.com/casey/just

;;; Code:



;; NOTE: This depends on Emacs 29.1 for treesitter.

(require 'prog-mode)
(require 'subr-x)

;; TODO Use nested modes for rule bodies so e.g. we can have Python mode for a Python script.

(defgroup just-ts nil
  "Major mode for editing just files"
  :group 'languages
  :prefix "just-ts-"
  ;; TODO different URL?
  :link '(url-link :tag "Site" "https://github.com/leon-barrett/just-mode.el")
  :link '(url-link :tag "Repository" "https://github.com/leon-barrett/just-mode.el"))

;; (defconst just-builtin-functions
;;   '(
;;     ;; Built-in functions from https://github.com/casey/just/blob/9f03441eef28fd662b33a8f1961e2ee97b60f7ff/src/function.rs#L22
;;     "absolute_path"
;;     "arch"
;;     "capitalize"
;;     "clean"
;;     "env_var"
;;     "env_var_or_default"
;;     "error"
;;     "extension"
;;     "file_name"
;;     "file_stem"
;;     "invocation_directory"
;;     "invocation_directory_native"
;;     "join"
;;     "just_executable"
;;     "justfile"
;;     "justfile_directory"
;;     "kebabcase"
;;     "lowercamelcase"
;;     "lowercase"
;;     "os"
;;     "os_family"
;;     "parent_directory"
;;     "path_exists"
;;     "quote"
;;     "replace"
;;     "replace_regex"
;;     "sha256"
;;     "sha256_file"
;;     "shoutykebabcase"
;;     "shoutysnakecase"
;;     "snakecase"
;;     "titlecase"
;;     "trim"
;;     "trim_end"
;;     "trim_end_match"
;;     "trim_end_matches"
;;     "trim_start"
;;     "trim_start_match"
;;     "trim_start_matches"
;;     "uppercamelcase"
;;     "uppercase"
;;     "uuid"
;;     "without_extension"))

;; (defun just-keyword-regex (keywords)
;;   "Create a regex for a list of keywords.
;; Argument KEYWORDS the list of keywords"
;;   (concat "\\<\\(" (string-join keywords "\\|") "\\)\\>"))

;; (defconst just-font-lock-keywords
;;   `(;; Variable interpolation looks like "{{varname}}"
;;     ("{{[^}\n]*}}" . font-lock-variable-name-face)
;;     ;; File includes
;;     ("^\\(!include\\) \\(.*\\)"
;;      (1 font-lock-keyword-face)
;;      (2 font-lock-string-face))
;;     ;; Setting, exporting, and aliasing
;;     ("^\\(alias\\|set\\|export\\) +\\([^ \n]*\\)"
;;      (1 font-lock-keyword-face)
;;      (2 font-lock-variable-name-face))
;;     ;; Variable assignment looks like "varname :="
;;     ("^\\([^ \n]*\\) *:=" 1 font-lock-variable-name-face)
;;     ;; Highlight variable interpolation in shell scripts like "${varname}"
;;     ("\\${\\([^}\n]*\\)}" 1 font-lock-variable-name-face)
;;     ;; Highlight rules like "rulename:"
;;     ;; TODO highlight arguments to rules. I would have done it, but it was hard so I gave up for now.
;;     ("^\\(@?\\)\\([^ @:\n]+\\).*:\\([^=\n]\\|$\\)"
;;      (1 font-lock-negation-char-face)
;;      (2 font-lock-function-name-face))
;;     ;; Keywords
;;     (,(just-keyword-regex '("if" "else")) . font-lock-keyword-face)
;;     ;; Built-in functions
;;     (,(just-keyword-regex just-builtin-functions) . font-lock-constant-face)))

;; (defconst just-mode-syntax-table
;;   (let ((syntax-table (make-syntax-table)))
;;     ;; # starts comments
;;     (modify-syntax-entry ?# "<" syntax-table)
;;     ;; endline ends comments
;;     (modify-syntax-entry ?\n ">" syntax-table)
;;     ;; underscores and dashes don't break words
;;     (modify-syntax-entry ?_ "w" syntax-table)
;;     (modify-syntax-entry ?- "w" syntax-table)
;;     ;; backticks are like quotes in shell
;;     (modify-syntax-entry ?` "\"" syntax-table)
;;     ;; single quotes are allowed
;;     (modify-syntax-entry ?' "\"" syntax-table)
;;     syntax-table))

;; (defun just-untab-region (N)
;;   "Untab a selected region using `indent-rigidly'.
;; Argument N number of untabs to perform"
;;   (interactive "p")
;;   (let ((begin (if (use-region-p)
;;                  (region-beginning)
;;                  (line-beginning-position)))
;;         (end (if (use-region-p)
;;                  (region-end)
;;                  (line-end-position))))
;;     (indent-rigidly begin end (* N -4))))

(defcustom just-ts-executable "just"
  "Location of just executable."
  :type 'file
  :group 'just
  :safe 'stringp)

(defun just-ts-format-buffer ()
  "Formats your buffer containing justfile."
  (interactive)
  (let ((exit-code (call-process just-ts-executable nil nil nil "--unstable" "--fmt")))
    (if (eq exit-code 0)
        (revert-buffer :ignore-auto :noconfirm)
        (message "Formatted")
      (message "Format failed with exit code %s" exit-code))))

;; from https://www.emacswiki.org/emacs/BackspaceWhitespaceToTabStop
;; (which is licensed GPL 2 or later)
(defvar just-ts-indent-offset 4 "My indentation offset.")
(defun just-ts-backspace-whitespace-to-tab-stop ()
  "Delete whitespace backwards to the next tab-stop, otherwise delete one character."
  (interactive)
  (if (or indent-tabs-mode
          (region-active-p)
          (save-excursion
            (> (point) (progn (back-to-indentation)
                              (point)))))
      (call-interactively #'backward-delete-char-untabify)
    (let ((movement (% (current-column) just-ts-indent-offset))
          (p (point)))
      (when (= movement 0) (setq movement just-ts-indent-offset))
      ;; Account for edge case near beginning of buffer
      (setq movement (min (- p 1) movement))
      (save-match-data
        (if (string-match "[^\t ]*\\([\t ]+\\)$" (buffer-substring-no-properties (- p movement) p))
            (backward-delete-char (- (match-end 1) (match-beginning 1)))
          (call-interactively #'backward-delete-char))))))

;; (defun just-ts-indent-line ()
;;   "Indent bodies of rules by the previous indent, or by `tab-width'."
;;   (interactive)
;;   (and abbrev-mode (= (char-syntax (preceding-char)) ?w)
;;        (expand-abbrev))
;;   (if (> (current-column) (current-indentation))
;;       ;; Don't indent when hitting tab in the middle of a line.
;;       'noindent
;;     (skip-chars-forward " \t")
;;     (indent-to
;;      (if (= (line-number-at-pos) (prog-first-column))
;;          (prog-first-column)
;;        (save-excursion
;;          (forward-line -1)
;;          (skip-chars-forward " \t")
;;          (let* ((previous-indentation (current-column))
;;                 (previous-line-is-empty (and (bolp) (eolp)))
;;                 (previous-line-contents (buffer-substring-no-properties (line-beginning-position) (line-end-position)))
;;                 (previous-line-is-rule (string-match "^[^ \t#:][^#:]*:\\([^=].*\\|$\\)" previous-line-contents)))
;;            (cond (previous-line-is-empty (prog-first-column))
;;                  (previous-line-is-rule (+ (prog-first-column) tab-width))
;;                  (t previous-indentation))))))))

(defvar just-ts-font-lock-rules
  '(:language just
    :feature comment
    ((comment) @font-lock-comment-face)

    :language just
    :feature keyword
    ((["set" "alias" "export" "if" "else" "import" "export" "shell" "&&" "mod"] @font-lock-keyword-face))

    :language just
    :feature builtin
    ((boolean) @font-lock-builtin-face)

    :language just
    :feature string
    ((string) @font-lock-string-face)

    :language just
    :feature string-interpolation
    ((external_command) @font-lock-preprocessor-face)

    :language just
    :feature string-interpolation
    ((interpolation) @font-lock-preprocessor-face)

    :language just
    :feature definition
    ((module name: (identifier) @font-lock-function-name-face))

    :language just
    :feature definition
    ((recipe_header "@"* @font-lock-function-name-face name: (identifier) @font-lock-function-name-face))

    :language just
    :feature variable
    ((parameter name: (identifier) @font-lock-variable-name-face))

    :language just
    :feature variable
    ((dependency name: (identifier) @font-lock-function-call-face))

    :language just
    :feature variable
    ((dependency_expression name: (identifier) @font-lock-function-call-face))

    :language just
    :feature assignment
    ((alias left: (identifier) @font-lock-function-name-face) right: (identifier) @font-lock-function-call-face)

    :language just
    :feature assignment
    ((assignment left: (identifier) @font-lock-variable-name-face))

    :language just
    :feature assignment
    ((setting left: (identifier) @font-lock-variable-name-face))

    :language just
    :feature variable
    ((function_call name: (identifier) @font-lock-function-call-face))

    :language just
    :feature variable
    ((attribute) @font-lock-variable-name-face)

    :language just
    :feature shebang
    ((shebang) @font-lock-preprocessor-face)

    ))

;; Common feature names, for many programming languages, include definition,
;; type, assignment, builtin, constant, keyword, string-interpolation, comment,
;; doc, string, operator, preprocessor, escape-sequence, and key. Major modes
;; are free to subdivide or extend these common features.

(defun just-ts-setup ()
  "Setup treesit for just-ts-mode."
  (setq-local treesit-font-lock-feature-list
              '((comment builtin keyword string string-interpolation)
                (definition assignment shebang)
                (variable)))
  (setq-local treesit-font-lock-settings
              (apply #'treesit-font-lock-rules
                     just-ts-font-lock-rules))

  ;; (setq-local treesit-simple-indent-rules just-ts-indent-rules)

  (treesit-major-mode-setup))

;;;###autoload
(define-derived-mode just-ts-mode prog-mode "Justfile[ts]"
  "Major mode for editing standard Justfiles using treesitter."

  ;; :syntax-table just-ts-mode-syntax-table

  ;; Font lock.
  (setq font-lock-defaults nil)

  (when (treesit-ready-p 'just)
    (treesit-parser-create 'just)
    (just-ts-setup)))



(provide 'just-ts-mode)

;;;###autoload
(add-to-list 'auto-mode-alist '("/[Jj]ustfile\\'" . just-ts-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.[Jj]ust\\(file\\)?\\'" . just-ts-mode))

;;; just-ts-mode.el ends here
