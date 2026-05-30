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
            "excalirender --scale 2 home/excalidraw\\ drawings/my-drawing.excalidraw -o home/excalidraw\\ drawings/my-drawing.excalidraw.svg"))

  (it "formats a png export command"
    (let ((org-excalidraw-export-format "png"))
      (expect (org-excalidraw--shell-cmd-to-image excal-path) :to-equal
              "excalirender --scale 2 home/excalidraw\\ drawings/my-drawing.excalidraw -o home/excalidraw\\ drawings/my-drawing.excalidraw.png")))

  (it "includes extra export arguments"
    (let ((org-excalidraw-export-arguments '("--scale" "2" "--dark" "--background" "#111111")))
      (expect (org-excalidraw--shell-cmd-to-image excal-path) :to-equal
              "excalirender --scale 2 --dark --background \\#111111 home/excalidraw\\ drawings/my-drawing.excalidraw -o home/excalidraw\\ drawings/my-drawing.excalidraw.svg"))))

(describe
  "checks external dependencies on initialization"
  (it "requires excalidraw directory to exist"
    (spy-on 'file-directory-p :and-return-value nil)
    (expect (org-excalidraw-initialize) :to-throw)))
