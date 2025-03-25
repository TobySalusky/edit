import cv2
import csv


face_classifier = cv2.CascadeClassifier(
    cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
)


face_pos_list = [["x", "y", "w", "h"]]

cap = cv2.VideoCapture("face.mp4")
def detect_bounding_box(vid):
    gray_image = cv2.cvtColor(vid, cv2.COLOR_BGR2GRAY)
    faces = face_classifier.detectMultiScale(gray_image, 1.1, 5, minSize=(40, 40))
    print(faces)
    max_face = max(faces, key=lambda face: face[2]* face[3])
    # for (x, y, w, h) in faces:

    #     cv2.rectangle(vid, (x, y), (x + w, y + h), (0, 255, 0), 4)
    x, y, w, h = max_face
    cv2.rectangle(vid, (x, y), (x + w, y + h), (0, 255, 0), 4)
    face_pos_list.append(max_face)
    return faces

def write_csv(data):
    with open("face.csv", 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(data)

while cap.isOpened():
    result, video_frame = cap.read()  # read frames from the video
    if result is False:
        break  # terminate the loop if the frame is not read successfully

    faces = detect_bounding_box(
        video_frame
    )  # apply the function we created to the video frame

    cv2.imshow(
        "My Face Detection Project", video_frame
    )  # display the processed frame in a window named "My Face Detection Project"

    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()

write_csv(face_pos_list)
