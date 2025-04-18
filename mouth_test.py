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

        # Get upper and lower lip positions
        top_lip = landmarks[13]
        bottom_lip = landmarks[14]

        top = np.array([top_lip.x * size[0], top_lip.y * size[1]])
        bottom = np.array([bottom_lip.x * size[0], bottom_lip.y * size[1]])

        # Compute Euclidean distance
        mouth_open_dist = np.linalg.norm(top - bottom)

        # Threshold (adjust this value depending on your camera resolution and test results)
        threshold = 15  

        if mouth_open_dist > threshold:
            cv2.putText(frame, "Mouth: OPEN", (30, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
        else:
            cv2.putText(frame, "Mouth: CLOSED", (30, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

    cv2.imshow("Mouth Open Detection", frame)
    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()