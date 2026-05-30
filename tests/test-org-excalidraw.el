;;; -*- lexical-binding: t; -*-
(require 'buttercup)

(describe
  "shell command formatting"
  :var ((excal-path "home/excalidraw drawings/my-drawing.excalidraw"))

  (it "formats the open command for macOS"
    (expect (org-excalidraw--shell-cmd-open excal-path 'darwin)
            :to-equal
            "open home/excalidraw\\ drawings/my-drawing.excalidraw"))

  (it "formats the open command for linux"
    (expect (org-excalidraw--shell-cmd-open excal-path 'gnu/linux)
            :to-equal
            "xdg-open home/excalidraw\\ drawings/my-drawing.excalidraw"))

  (it "formats a command compatible with excalirender"
    (expect (org-excalidraw--shell-cmd-to-svg excal-path) :to-equal
            "excalirender home/excalidraw\\ drawings/my-drawing.excalidraw -o home/excalidraw\\ drawings/my-drawing.excalidraw.svg")))

(describe
  "checks external dependencies on initialization"
  (it "requires excalidraw directory to exist"
    (spy-on 'file-directory-p :and-return-value nil)
    (expect (org-excalidraw-initialize) :to-throw)))
