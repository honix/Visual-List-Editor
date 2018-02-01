;;
;; Lire - window
;;

(in-package :lire)

(defclass lire-window (glut:window)
  ((mouse-x     :initform 0)
   (mouse-y     :initform 0)
   (shift       :initform nil)
   (mouse-left  :initform nil)
   (mouse-right :initform nil)

   (canvas        :initform nil)
   (active-module :initform nil))
  (:default-initargs :width *initial-width* :height *initial-height*
                     :pos-x 100 :pos-y 100
                     :mode '(:double :rgb :stencil :multisample)
                     :tick-interval 16
                     :title "Lire"))

;;;
;;  Window initialization and input binding
;;;

(defmethod initialize-instance :before ((w lire-window) &rest rest)
  (declare (ignore rest))
  (with-slots (canvas active-module) w
    (setf canvas (make-instance 'canvas :window w)
          active-module canvas)))

(defmethod glut:display-window :before ((w lire-window))
  (sdl2-ttf:init)
  (clean-text-hash)
  (gl:clear-color 0.1 0.1 0.1 0)
  (gl:enable :texture-2d :blend)
  (gl:blend-func :src-alpha :one-minus-src-alpha))

(defmethod glut:reshape ((w lire-window) width height)
  (setf (slot-value w 'width) width
        (slot-value w 'height) height)
  (gl:viewport 0 0 width height)
  (gl:matrix-mode :projection)
  (gl:load-identity)
  (let ((hwidth  (/ width 2))
        (hheight (/ height 2)))
    (gl:ortho (- hwidth)  (+ hwidth)
              (+ hheight) (- hheight) 0 1)
    (gl:translate (- hwidth) (- hheight) -1))
  (gl:matrix-mode :modelview))

(defmethod glut:close ((w lire-window))
  (sdl2-ttf:quit))


(defmethod glut:display ((w lire-window))
  (with-simple-restart (display-restart "Display")
    (gl:clear :color-buffer :stencil-buffer-bit)
    
    (process (slot-value w 'canvas))
    ;; (for module in modules do (draw module))
    
    (glut:swap-buffers)))
  
(defmethod glut:idle ((w lire-window))
  ;; Updates
  ;(glut:post-redisplay)
  )

(defmethod glut:tick ((w lire-window))
  (with-simple-restart (tick-restart "Tick")
    (glut:post-redisplay)))

(defmethod mouse-motion ((w lire-window) x y)
  (with-slots (mouse-x mouse-y active-module) w
    (let ((dx (- mouse-x x))
          (dy (- mouse-y y)))
      (setf mouse-x x mouse-y y)
      (motion active-module x y dx dy))))

(defmethod glut:motion ((w lire-window) x y)
  (with-simple-restart (motion-restart "Motion")
    (mouse-motion w x y)))

(defmethod glut:passive-motion ((w lire-window) x y)
  (with-simple-restart (passive-motion-restart "Passive-motion")
    (mouse-motion w x y)))

(defmethod glut:mouse ((w lire-window) button state x y)
  (with-simple-restart (mouse-restart "Mouse")
    (with-slots (mouse-x mouse-y mouse-left mouse-right active-module) w
      (setf mouse-x x mouse-y y)
      (case button
        (:left-button
         (setf mouse-left (eq state :down)))
        (:middle-button
         nil)
        (:right-button
         (setf mouse-right (eq state :down)))
        (:wheel-up
         (mouse-whell active-module 1))
        (:wheel-down
         (mouse-whell active-module -1)))
      (mouse active-module button state x y))))

(defmethod glut:mouse-wheel ((w lire-window) button pressed x y)
  ;; This method works on windows. Linux sends all mouse events to GLUT:MOUSE
  (with-simple-restart (mouse-whell-restart "Mouse-whell")
    (with-slots (active-module) w
      (case pressed
        ((:up   :wheel-up)   (mouse-whell active-module 1))
        ((:down :wheel-down) (mouse-whell active-module -1))))))

(defmethod glut:special ((w lire-window) special-key x y)
  ;; Catches :KEY-F1 :KEY-LEFT-SHIFT :KEY-HOME :KEY-LEFT etc..
  (with-simple-restart (special-key-restart "Special-key")
    (with-slots (active-module shift) w
      (case special-key
        ((:key-left-shift :key-right-shift)
         (setf shift t)))
      (special-key active-module special-key))))

(defmethod glut:special-up ((w lire-window) special-key x y)
  (with-simple-restart (special-key-up-restart "Special-key-up")
    (with-slots (active-module shift) w
      (case special-key
        ((:key-left-shift :key-right-shift)
         (setf shift nil)))
      (special-key-up active-module special-key))))

(defmethod glut:keyboard ((w lire-window) key x y)
  ;; Catches alphanumeric keys + #\Return #\Backspace #\Tab and etc..
  (with-simple-restart (keyboard-restart "Keyboard")
    (with-slots (active-module) w
      (if (graphic-char-p key)
          (keyboard active-module key)
          (special-key active-module key)))))

(defmethod glut:keyboard-up ((w lire-window) key x y)
  (with-simple-restart (keyboard-up-restart "Keyboard-up")
    (with-slots (active-module) w
      (if (graphic-char-p key)
          (keyboard-up active-module key)
          (special-key-up active-module key)))))
