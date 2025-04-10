import cv2
import dlib
import numpy as np

# Load the pre-trained facial landmark detector
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")

def get_mouth_aspect_ratio(landmarks):
    # Define mouth landmark points
    mouth_points = np.array([
        (landmarks.part(48).x, landmarks.part(48).y),  # Left corner
        (landmarks.part(50).x, landmarks.part(50).y),
        (landmarks.part(52).x, landmarks.part(52).y),
        (landmarks.part(54).x, landmarks.part(54).y),  # Right corner
        (landmarks.part(56).x, landmarks.part(56).y),
        (landmarks.part(58).x, landmarks.part(58).y),
        (landmarks.part(60).x, landmarks.part(60).y),  # Inner left
        (landmarks.part(62).x, landmarks.part(62).y),
        (landmarks.part(64).x, landmarks.part(64).y),  # Inner right
        (landmarks.part(66).x, landmarks.part(66).y)
    ], dtype=np.float32)

    # Compute distances
    vertical_1 = np.linalg.norm(mouth_points[1] - mouth_points[7])
    vertical_2 = np.linalg.norm(mouth_points[2] - mouth_points[6])
    horizontal = np.linalg.norm(mouth_points[0] - mouth_points[3])

    # Compute MAR
    MAR = (vertical_1 + vertical_2) / (2.0 * horizontal)
    return MAR

# Open webcam
cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()
    if not ret:
        break

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    faces = detector(gray)

    for face in faces:
        landmarks = predictor(gray, face)
        MAR = get_mouth_aspect_ratio(landmarks)

        # Define open mouth threshold (adjust as needed)
        threshold = 0.5
        if MAR > threshold:
            
            text = "Mouth Open"
            color = (0, 0, 255)  # Red
        else:
            text = "Mouth Closed"
            color = (0, 255, 0)  # Green

        # Draw text
        cv2.putText(frame, text, (face.left(), face.top()-10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)

    cv2.imshow("Mouth Detection", frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
