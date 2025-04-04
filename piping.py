import cv2
import sys
import json
import time
import os
import csv


face_classifier = cv2.CascadeClassifier(
    cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
)


face_pos_list = [["x", "y", "w", "h"]]

cap = cv2.VideoCapture("face.mp4")
def detect_bounding_box(vid):
    gray_image = cv2.cvtColor(vid, cv2.COLOR_BGR2GRAY)
    faces = face_classifier.detectMultiScale(gray_image, 1.1, 5, minSize=(40, 40))
    # print(faces)
    max_face = max(faces, key=lambda face: face[2]* face[3])
    max_face = max_face.tolist()
    # for (x, y, w, h) in faces:

    #     cv2.rectangle(vid, (x, y), (x + w, y + h), (0, 255, 0), 4)
    x, y, w, h = max_face
    cv2.rectangle(vid, (x, y), (x + w, y + h), (0, 255, 0), 4)
    # face_pos_list.append()
    return {"x": x,
            "y": y,
            "w": w,
            "h": h}

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



def process_image():
    """Example OpenCV processing with multiple outputs"""
    image_path = "src/african_hat.jpg"
    if not os.path.exists(image_path):
        yield {"error": f"File not found: {image_path}", "path": os.path.abspath(image_path)}
        return

    img = cv2.imread(image_path)
    if img is None:
        yield {"error": "Image not found"}
        return
    
    # First yield basic info
    yield {
        "type": "metadata",
        "dimensions": {
            "width": img.shape[1],
            "height": img.shape[0],
            "channels": img.shape[2] if len(img.shape) > 2 else 1
        }
    }
    
    # Process grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    yield {
        "type": "grayscale_stats",
        "mean": float(gray.mean()),
        "stddev": float(gray.std())
    }
    
    # Process edges (example of longer computation)
    edges = cv2.Canny(gray, 100, 200)
    yield {
        "type": "edge_stats",
        "edge_pixels": int(edges.sum() / 255),
        "computation_time": 0.15  # Simulated processing time
    }


bruh = main()

if __name__ == "__main__":
    try:
        # Stream results as they become available
        for faces in bruh:
            print(json.dumps(faces))  # Each print is one line
            sys.stdout.flush()  # Ensure immediate transmission
            
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)