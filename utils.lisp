;;
;; Lire - utils
;;

;; Move this section to new file

;;
;; Lire-user
;;

(in-package :cl-user)

;; Graham's alambda
(defmacro alambda (parms &body body)
  `(labels ((self ,parms ,@body))
     #'self))

;; end

(in-package :lire)

(defun get-time ()
  (/ (get-internal-real-time)
     internal-time-units-per-second))

;;;
;;  Evaly
;;;

(defun e-eval (form &optional echo)
  (when echo
    (format t "Evaluating new form:~%")
    (format t "  IN  >>>~%    ~s~%" form))
  (ignore-errors
    (let ((result (eval form)))
      (when echo
        (format t "  OUT <<<~%    ~s~%" result))
      result)))

(defun function-symbol-p (symbol)
  (e-eval
   `(not (null (ignore-errors (and (symbolp ',symbol)
                                   (symbol-function ',symbol)))))))

;;;
;;  Math
;;;

(defun lerp (from to amount)
  (+ from (* (- to from) amount)))

(defmacro snap-to-grid (what)
  `(setf ,what
         (let ((half (/ *grid-size* 2)))
           (round (- ,what (- (mod (+ ,what half) *grid-size*) half))))))

;;;
;;  Color
;;;

(defun hsv-to-rgb (h s v)
  (let* ((c (* v s))
         (x (* c (- 1 (abs (- (mod (/ h 60) 2) 1)))))
         (m (- v c))
         (rgb-n (cond ((<= 0   h  60) (list c x 0))
                      ((<= 60  h 120) (list x c 0))
                      ((<= 120 h 180) (list 0 c x))
                      ((<= 180 h 240) (list 0 x c))
                      ((<= 240 h 300) (list x 0 c))
                      ((<= 300 h 360) (list c 0 x)))))
    (mapcar (lambda (x) (+ x m)) rgb-n)))

;;;
;;  Lists
;;;

(defun flatten (l &key (test #'atom))
  (cond ((null l) nil)
        ((funcall test l) (list l))
        (t (loop for a in l nconc (flatten a :test test)))))

;;;
;;  Saving-lisp
;;;

(defun save-lisp ()
  "Make exebutable"
  #+sbcl
  (sb-ext:save-lisp-and-die
   (concatenate 'string
                "builds/Lire-" (software-type) ".exe")
   :toplevel (lambda ()
               (format t "Image loaded.~%")
               (run-lire :threaded nil))
   :executable t
   ;:application-type :gui
   ))

