;;; org-excalidraw.el --- Tools for working with excalidraw drawings -*- lexical-binding: t; -*-
;; Copyright (C) 2022 David Wilson

;; Author:  David Wilson <wdavew@gmail.com>
;; URL: https://github.com/wdavew/org-excalidraw
;; Created: 2022
;; Version: 0.1.0
;; Keywords: convenience, outlines
;; Package-Requires: ((org "9.3") (emacs "26.1"))

;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;;; org-excalidraw.el is a package to for embedding excalidraw drawings into Emacs.
;;; it adds an org-mode link type for excalidraw files to support inline display
;;; and opening the diagrams from Emacs for editing.

;;; Code:
(require 'cl-lib)
(require 'filenotify)
(require 'org-id)
(require 'ol)
(require 'subr-x)

(defun org-excalidraw--default-base ()
  "Get default JSON template used for new excalidraw files."
  "{
    \"type\": \"excalidraw\",
    \"version\": 2,
    \"source\": \"https://excalidraw.com\",
    \"elements\": [],
    \"appState\": {
      \"gridSize\": null,
      \"viewBackgroundColor\": \"#ffffff\"
    },
    \"files\": {}
  }
")

(defgroup org-excalidraw nil
  "Customization options for org-excalidraw."
  :group 'org
  :prefix "org-excalidraw-")

(defcustom org-excalidraw-directory "~/org-excalidraw"
  "Directory to store excalidraw files."
  :type 'string
  :group 'org-excalidraw)

(defcustom org-excalidraw-base (org-excalidraw--default-base)
  "JSON string representing base excalidraw template for new files."
  :type 'string
  :group 'org-excalidraw)

(defcustom org-excalidraw-export-program "excalirender"
  "Program used to export excalidraw files to image previews."
  :type 'string
  :group 'org-excalidraw)

(defcustom org-excalidraw-export-format "svg"
  "Image format used for rendered excalidraw previews."
  :type '(choice (const "svg") (const "png"))
  :group 'org-excalidraw)

(defcustom org-excalidraw-export-arguments '("--scale" "2")
  "Additional arguments passed to `org-excalidraw-export-program'."
  :type '(repeat string)
  :group 'org-excalidraw)

(defun org-excalidraw--validate-excalidraw-file (path)
  "Validate the excalidraw file at PATH is usable."
  (unless (string-suffix-p ".excalidraw" path)
    (error
     "Excalidraw file must have .excalidraw extension")))

(defun org-excalidraw--preview-path (path)
  "Return rendered preview path for excalidraw file at PATH."
  (concat path "." org-excalidraw-export-format))

(defun org-excalidraw--shell-cmd-to-image (path)
  "Construct shell cmd for converting excalidraw file with PATH to an image."
  (string-join
   (append
    (list (shell-quote-argument org-excalidraw-export-program))
    (mapcar #'shell-quote-argument org-excalidraw-export-arguments)
    (list (shell-quote-argument path)
          "-o"
          (shell-quote-argument (org-excalidraw--preview-path path))))
   " "))

(defun org-excalidraw--shell-cmd-to-svg (path)
  "Construct shell cmd for converting excalidraw file with PATH to an image."
  (org-excalidraw--shell-cmd-to-image path))

(defun org-excalidraw--shell-cmd-open (path os-type)
  "Construct shell cmd to open excalidraw file with PATH for OS-TYPE."
  (if (eq os-type 'darwin)
      (concat "open " (shell-quote-argument path))
    (concat "xdg-open " (shell-quote-argument path))))

(defun org-excalidraw--open-file-from-preview (path)
  "Open corresponding .excalidraw file for preview image located at PATH."
  (let ((excal-file-path (replace-regexp-in-string "\\.\\(svg\\|png\\)\\'" "" path)))
    (org-excalidraw--validate-excalidraw-file excal-file-path)
    (shell-command (org-excalidraw--shell-cmd-open excal-file-path system-type))))

(defun org-excalidraw--open-preview-file (path _link)
  "Open corresponding .excalidraw file for preview image at PATH."
  (org-excalidraw--open-file-from-preview path))

(defun org-excalidraw--open-file-from-svg (path)
  "Open corresponding .excalidraw file for svg located at PATH."
  (org-excalidraw--open-file-from-preview path))

(defun org-excalidraw--handle-file-change (event)
  "Handle file update EVENT to convert files to preview images."
  (when (string-equal (cadr event)  "renamed")
    (let ((filename (cadddr event)))
      (when (string-suffix-p ".excalidraw" filename)
        (shell-command (concat (org-excalidraw--shell-cmd-to-image filename) " 2> /dev/null") nil nil)
        (org-display-inline-images)))))

;;;###
;;;autoload
(defun org-excalidraw-create-drawing ()
  "Create an excalidraw drawing and insert an 'org-mode' link to it at Point."
  (interactive)
  (let* ((filename (format "%s.excalidraw" (org-id-uuid)))
         (path (expand-file-name filename org-excalidraw-directory))
         (link (format "[[file:%s]]" (org-excalidraw--preview-path path))))
    (org-excalidraw--validate-excalidraw-file path)
    (insert link)
    (with-temp-file path (insert org-excalidraw-base))
    (shell-command (org-excalidraw--shell-cmd-open path system-type))))


;;;###autoload
(defun org-excalidraw-initialize ()
  "Setup excalidraw.el. Call this after 'org-mode initialization."
  (interactive)
  (unless (file-directory-p org-excalidraw-directory)
    (error
     "Excalidraw directory %s does not exist"
     org-excalidraw-directory))
  (push '("\\.excalidraw\\.\\(?:svg\\|png\\)\\'" . org-excalidraw--open-preview-file) org-file-apps)
  (file-notify-add-watch org-excalidraw-directory '(change) 'org-excalidraw--handle-file-change))


(provide 'org-excalidraw)
;;; org-excalidraw.el ends here
