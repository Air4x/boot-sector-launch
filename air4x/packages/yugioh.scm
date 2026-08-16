(define-module (air4x packages yugioh)
  #:use-module (guix)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix build utils)
  #:use-module (gnu packages game-development)
  #:use-module (gnu packages build-tools)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages games)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pretty-print)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg))

;; fork of irrlicht used for edopro
(define-public edo-irrlicht
  (package
    (inherit irrlicht)
    (name "irrlicht")
    (version "63cb10dcc6e49857ff2549900d8ebfab076ed5d7")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/edo9300/irrlicht1-8-4")
             (recursive? #t)
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "16pnn6mnwwxv70k374n9fwq5m4g3z9zy3m8knap3xn5z4xamljnx"))))
    (arguments
     (substitute-keyword-arguments (package-arguments irrlicht)
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-after 'unpack 'fix-edopro-gl-paths
              (lambda* (#:key inputs #:allow-other-keys)
                (let ((libgl (search-input-file inputs "/lib/libGL.so.1"))
                      (libegl (search-input-file inputs "/lib/libEGL.so.1"))
                      (libwl (search-input-file inputs
                                                "/lib/libwayland-client.so.0"))
                      (libwlc (search-input-file inputs
                               "/lib/libwayland-cursor.so.0"))
                      (libwle (search-input-file inputs
                                                 "/lib/libwayland-egl.so.1"))
                      (libxkb (search-input-file inputs
                                                 "/lib/libxkbcommon.so.0")))
                  (substitute* (find-files "source/Irrlicht" "\\.cpp$")
                    (("\"libGLX\\.so\"")
                     (string-append "\"" libgl "\""))
                    (("\"libGL\\.so\"")
                     (string-append "\"" libgl "\""))
                    (("\"libGL\\.so\\.1\"")
                     (string-append "\"" libgl "\""))
                    (("\"libEGL\\.so\"")
                     (string-append "\"" libegl "\""))
                    (("\"libEGL\\.so\\.1\"")
                     (string-append "\"" libegl "\""))
                    (("\"libwayland-client\\.so\\.0\"")
                     (string-append "\"" libwl "\""))
                    (("\"libwayland-cursor\\.so\\.0\"")
                     (string-append "\"" libwlc "\""))
                    (("\"libwayland-egl\\.so\\.1\"")
                     (string-append "\"" libwle "\""))
                    (("\"libxkbcommon\\.so\\.0\"")
                     (string-append "\"" libxkb "\""))))))))))
    (inputs (modify-inputs (package-inputs irrlicht)
              (prepend wayland wayland-protocols libxkbcommon mesa)))
    (synopsis "3D game engine written in C++ - fork")
    (description "Fork of the Irrlicht Engine for Project Ignis: EDOpro.")
    (home-page "https://github.com/edo9300/irrlicht1-8-4")
    (license license:agpl3+)))

(define-public edo-ocgcore
  (package
    (name "ocgcore")
    ;; We use edopro stable release here to be sure to use a working version of ocgcore
    (version "41.0.2")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/edo9300/edopro")
             (recursive? #t)
             (commit version)))
       (file-name (git-file-name name version))
       ;; same hash of edopro
       (sha256
        (base32 "15lmav10r7nlvi6fmr488zp1s4nlppkipr0rz5kp6jzpvrd1fi36"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'disable-lto
            (lambda _
              (substitute* "premake5.lua"
                (("flags \"LinkTimeOptimization\"")
                 "removeflags \"LinkTimeOptimization\""))))
          (replace 'configure
            (lambda _
              (invoke "premake5" "gmake"
		      "--pics=\"https://pics.projectignis.org:2096/pics/{}.jpg\"")))
          (replace 'build
            (lambda _
              (invoke "make"
                      "config=release_x64"
                      "-j"
                      (number->string (parallel-job-count))
                      "-C"
                      "build"
                      "ocgcoreshared")))
          (delete 'check)
          (replace 'install
            (lambda _
              (let ((lib (string-append #$output "/lib")))
                (mkdir-p lib)
                (install-file "bin/x64/release/libocgcore.so" lib)))))))
    (native-inputs (list lua premake5 pkg-config))
    (inputs (list lua sqlite))
    (home-page "https://github.com/edo9300/ygopro-core")
    (synopsis "OCG Core for EDOpro")
    (description "Fork of OCG Core used in EDOpro.")
    (license license:agpl3+)))

;; (define-public windbot-ignite
;;   (package
;;    (name "windbot-ignite")
;;    (version "20250927")
;;    (source
;;     (origin
;;      (method git-fetch)
;;      (uri (git-reference
;; 	   (url "https://github.com/ProjectIgnis/windbot")
;; 	   (recursive? #f)
;; 	   (commit version)))
;;      (file-name (git-file-name name version))
;;      (sha256
;;       (base32 "1ixbl2ny1yj4k59qxpmm6m6k4davf1hrvw97nbv51b8n0f3g2rg2"))))
;;    (build-system )))

(define-public edopro
  (package
   (name "edopro")
   (version "41.0.2")
   (source
    (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/edo9300/edopro")
           (recursive? #t)
           (commit version)))
     (file-name (git-file-name name version))
     (sha256
      (base32 "15lmav10r7nlvi6fmr488zp1s4nlppkipr0rz5kp6jzpvrd1fi36"))))
   (build-system gnu-build-system)
   (arguments
    (list
     #:phases
     #~(modify-phases %standard-phases
		      ;; We remove lto and tell edopro where to get ocgcore
		      (add-after 'unpack 'disable-lto-and-patch-ocgcore
				 (lambda _
				   (substitute* "premake5.lua"
						(("flags \"LinkTimeOptimization\"")
						 "removeflags \"LinkTimeOptimization\""))
				   (substitute* "gframe/game.cpp"
						(("ocgcore = LoadOCGcore\\(Utils::GetWorkingDirectory\\(\\)\\)")
						 (string-append "ocgcore = LoadOCGcore(\""
								#$edo-ocgcore "/lib/\")")))))

		      (add-before 'configure 'set-irrlicht-path
				  (lambda _
				    ;; Modifies CPLUS_INCLUDE_PATH to find irrlicht headers
				    (setenv "CPLUS_INCLUDE_PATH"
					    (string-append (getenv "CPLUS_INCLUDE_PATH") ":"
							   #$edo-irrlicht "/include/irrlicht"))))
		      (add-after 'set-irrlicht-path 'set-freetype-path
				 (lambda _
				   (setenv "CPLUS_INCLUDE_PATH"
					   (string-append (getenv "CPLUS_INCLUDE_PATH") ":"
							  #$freetype "/include/freetype2"))))
		      (replace 'configure
			       (lambda _
				 ;; Generate GNU Makefiles using premake5
				 (invoke "premake5" "gmake" "--no-core" "--sound=sfml")))
		      (delete 'patch-generated-file-shebangs)
		      (replace 'build
			       (lambda _
				 ;; Use a specific Makefile
				 (invoke "make"
					 "config=release_x64"
					 "-j"
					 (number->string (parallel-job-count))
					 "-C"
					 "build"
					 "ygoprodll")))
		      (delete 'check)
		      (replace 'install
			       (lambda _
				 (let* ((out #$output)
					(bin (string-append out "/bin"))
					(share (string-append out "/share/edopro")))
				   ;; target directory
				   (mkdir-p bin)
				   (mkdir-p share)
				   ;; copying the executable in share
				   (install-file "bin/x64/release/ygoprodll" share)
				   (for-each (lambda (item)
					       (when (file-exists? item)
						 (if (file-is-directory? item)
						     (copy-recursively item
								       (string-append share "/"
										      item))
						     (copy-file item
								(string-append share "/" item)))))
					     '("sfAudio" "config" "notices" "sound" "textures"))
				   (let ((wrapper (string-append bin "/edopro")))
				     (with-output-to-file wrapper
				       (lambda ()
					 (format #t "#!/bin/sh~%")
					 (format #t
						 "DATA_DIR=\"${XDG_DATA_HOME:-$HOME/.local/share}/edopro\"~%")
					 (format #t "if [ ! -d \"$DATA_DIR/fonts\" ]; then~%")
					 (format #t "  echo \"=== MISSING ASSET ===\"~%")
					 (format #t
						 "  echo \"1. Download the last release from Project Ignisd.\"~%")
					 (format #t "  echo \"2. untar the .tar.gz\"~%")
					 (format #t
						 "  echo \"3. Move all the content in: $DATA_DIR\"~%")
					 (format #t "  echo \"restart the program.\"~%")
					 (format #t "  mkdir -p \"$DATA_DIR\"~%")
					 (format #t "  exit 1~%")
					 (format #t "fi~%")
					 (format #t "exec ~a/ygoprodll -C $DATA_DIR \"$@\"~%"
						 share)))
				     (chmod wrapper #o555))))))))
   (native-inputs (list premake5 lua pkg-config))
   (inputs (list edo-irrlicht
                 sqlite
                 libevent
                 curl
                 libgit2
                 fmt
                 nlohmann-json
                 glu
                 freetype
                 libssh2
                 mesa
                 sfml
                 xz
                 edo-ocgcore))
   (home-page "https://projectignis.github.io/")
   (synopsis "Bleeding edge duel emulator")
   (description
    "EDOpro is a modern duel emulator. To make it work you need to download
the release from GitHub and copy all the assets in $DATA_DIR, which
is defined as ${XDG_DATA_DIR:-$HOME/.local/share}edopro.")
   (license license:agpl3+)))

