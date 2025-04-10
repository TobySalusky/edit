import cv2
import sys
import json
import time
import os
import csv

import dlib
import numpy as np



face_classifier = cv2.CascadeClassifier(
    cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
)

detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")

face_pos_list = [["x", "y", "w", "h"]]

cap = cv2.VideoCapture("open_mouth.mp4")
threshold = 0.45

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


def detect_bounding_box(vid):
    gray_image = cv2.cvtColor(vid, cv2.COLOR_BGR2GRAY)
    other_face = detector(gray_image)

    if other_face:
        landmarks = predictor(gray_image, other_face[0])
        MAR = get_mouth_aspect_ratio(landmarks)

        mouth_open = int(bool(MAR > threshold))
    else:
        MAR = 0
        mouth_open = False
        mouth_open = 0

    faces = face_classifier.detectMultiScale(gray_image, 1.1, 5, minSize=(40, 40))
    # print(faces)
    if MAR > threshold:
            
            text = "Mouth Open"
            color = (0, 0, 255)  # Red
    else:
        text = "Mouth Closed"
        color = (0, 255, 0)  # Green

    # Draw text
    if other_face:
        cv2.putText(vid, text, (other_face[0].left(), other_face[0].top()-10),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)

    if len(faces) > 0:
        max_face = max(faces, key=lambda face: face[2]* face[3])
        max_face = max_face.tolist()
    else:
        max_face = (0, 0, 0, 0)
    for (x, y, w, h) in faces:

        cv2.rectangle(vid, (x, y), (x + w, y + h), (0, 255, 0), 4)
    x, y, w, h = max_face
    cv2.rectangle(vid, (x, y), (x + w, y + h), (0, 255, 0), 4)
    # face_pos_list.append()
    return {"x": x,
            "y": y,
            "w": w,
            "h": h,
            "m": mouth_open}

def write_csv(data):
    with open("face.csv", 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(data)

def main():
    while cap.isOpened():
        result, video_frame = cap.read()  # read frames from the video
        if result is False:
            break  # terminate the loop if the frame is not read successfully

        faces = detect_bounding_box(
            video_frame
        )  # apply the function we created to the video frame

        # cv2.imshow(
        #     "My Face Detection Project", video_frame
        # )  # display the processed frame in a window named "My Face Detection Project"

        if cv2.waitKey(1) & 0xFF == ord("q"):
            break
        
        yield faces


    cap.release()
    cv2.destroyAllWindows()

# write_csv(face_pos_list)


bruh = main()


# for faces in bruh:
#     print(json.dumps(faces))  # Each print is one line
#     sys.stdout.flush()  # Ensure immediate transmission

if __name__ == "__main__":
    try:
        # Stream results as they become available
        for faces in bruh:
            print(json.dumps(faces))  # Each print is one line
            sys.stdout.flush()  # Ensure immediate transmission
            
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)