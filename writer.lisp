;;
;; Lire - write lire code from list of nodes
;;

(in-package :lire)

(defmethod compose-list ((head node))
  (with-slots (name childs) head
    (cons name (mapcar #'compose-list childs))))

(defmethod compose-poses ((head node))
  (with-slots (x y childs) head
    (let ((canvas (get-canvas *lire*)))
      (cons (if *fragment*
                (let ((p-x (slot-value canvas 'position-x))
                      (p-y (slot-value canvas 'position-y)))
                  (cons (- x p-x) (- y p-y)))
                (cons x y))
            (mapcar #'compose-poses childs)))))

(defmethod nodes-and-poses ((head node))
  (list
   :nodes (compose-list  head)
   :poses (compose-poses head)))

(defun write-lire (nodes)
  (let ((heads (heads nodes)))
    (write-to-string
     (mapcar #'nodes-and-poses heads)
     :pretty t)))

(defun valid-data-p (nodes-and-poses)
  "Stupid and broken check for validity"
  (or (eq nodes-and-poses ())
      (let ((first-tree (car nodes-and-poses)))
        (and (find :nodes first-tree)
             (find :poses first-tree)))))

(defun write-lire-to-file (path)
  (format t "Writing ~s~%" path)
  (handler-case
      (with-open-file (out path
                           :direction :output
                           :if-exists :supersede
                           :if-does-not-exist :create)
        (princ (write-lire (slot-value (get-canvas *lire*) 'nodes)) out))
    (condition (e) (format t "Error while writing: ~a~%" e))))

(defun load-lire-from-file (path)
  (format t "Loading ~s~%" path)
  (let ((nodes-and-poses
         (handler-case
             (with-open-file (in path)
               (read in))
           (condition (e) (format t "Error while loading: ~a~%" e)))))
    (format t "~a~%" nodes-and-poses)
    (if (valid-data-p nodes-and-poses)
        (inject-nodes (get-canvas *lire*) nodes-and-poses :clear t)
        (format t "Error while reading~%"))))
