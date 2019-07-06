;; um
;;
;; http://www.gigamonkeys.com/book/
;; https://cs.gmu.edu/~sean/lisp/LispTutorial.html
;;
;; C-c C-c compile
;; C-c C-k compile and load current buffer's file
;; C-c C-z switch to REPL
;; , gets a slime commans prompt where you can type quit
;; (in the debugger) q gets you back
;; C-c C-l load file into slime

(defun hello-world ()
  (format t "hello there, world"))

(defvar *db* nil)

(defun make-task (project task)
  (list :project project :task task))

(defun add-task (task)
  (push task *db*))

(defun dump-db ()
  (dolist (task *db*)
    (format t "~{~a=~a,~a=~a~}~%" task)))

(defun prompt-read (prompt)
  (format *query-io* "~a: " prompt)
  (force-output *query-io*)
  (read-line *query-io*))

(defun prompt-for-task ()
  (make-task
   (prompt-read "Project")
   (prompt-read "Task")))

(defun add-tasks ()
  (loop (add-task (prompt-for-task))
     (if (not (y-or-n-p "Another? [y/n]: ")) (return))))

(defun save-db (filename)
  (with-open-file (out filename
		       :direction :output
		       :if-exists :supersede)
    (with-standard-io-syntax
      (print *db* out))))

(defun load-db (filename)
  (with-open-file (in filename)
    (with-standard-io-syntax
      (setf *db* (read in)))))
