import cv2
import mediapipe as mp
import numpy as np

mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(static_image_mode=False, max_num_faces=1)

cap = cv2.VideoCapture(0)
size = (640, 480)

while True:
    ret, frame = cap.read()
    if not ret:
        break

    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = face_mesh.process(rgb_frame)

    if results.multi_face_landmarks:
        landmarks = results.multi_face_landmarks[0].landmark

        # Get all x and y coordinates
        x_coords = [lm.x * size[0] for lm in landmarks]
        y_coords = [lm.y * size[1] for lm in landmarks]

        # Compute bounding box
        x_min, x_max = int(min(x_coords)), int(max(x_coords))
        y_min, y_max = int(min(y_coords)), int(max(y_coords))

        box_width = x_max - x_min
        box_height = y_max - y_min

        # Draw rectangle
        cv2.rectangle(frame, (x_min, y_min), (x_max, y_max), (0, 255, 0), 2)

        # Draw face position + size
        cv2.putText(frame, f"X: {x_min}, Y: {y_min}", (x_min, y_min-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,0), 1)
        cv2.putText(frame, f"W: {box_width}, H: {box_height}", (x_min, y_min-30), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,0), 1)

    cv2.imshow("Face Position & Size", frame)
    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()