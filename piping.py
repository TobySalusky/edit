import cv2
import sys
import json

import numpy as np
import mediapipe as mp


mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(static_image_mode=False, max_num_faces=1)

# 3D model points (in arbitrary units)
model_points = np.array([
    (0.0, 0.0, 0.0),         # Nose tip
    (0.0, -330.0, -65.0),    # Chin
    (-225.0, 170.0, -135.0), # Left eye left corner
    (225.0, 170.0, -135.0),  # Right eye right corner
    (-150.0, -150.0, -125.0),# Left mouth corner
    (150.0, -150.0, -125.0)  # Right mouth corner
])


file_path = sys.argv[1]
# file_path = "C:/Users\data\Downloads/riko.mp4"
# file_path = "C:/Users\data\Downloads\gojo_toji.mp4"

cap = cv2.VideoCapture(file_path)

# Camera internals
frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
frame_rate = int(cap.get(cv2.CAP_PROP_FPS))
size = (frame_width, frame_height)
focal_length = size[1]
center = (size[1] / 2, size[0] / 2)
camera_matrix = np.array([
    [focal_length, 0, center[0]],
    [0, focal_length, center[1]],
    [0, 0, 1]
], dtype="double")
dist_coeffs = np.zeros((4, 1))  # Assuming no lens distortion





def main():
    while cap.isOpened():
        x_min, y_min, box_width, box_height, mouth_open_dist, roll, pitch, yaw, threshold = [0] * 9
        result, frame = cap.read()  # read frames from the video
        if result is False:
            break  # terminate the loop if the frame is not read successfully

        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = face_mesh.process(rgb_frame)

        if results.multi_face_landmarks:
            landmarks = results.multi_face_landmarks[0].landmark

            # Get the 2D image points for the 6 model points
            image_points = np.array([
                (landmarks[1].x * size[0], landmarks[1].y * size[1]),   # Nose tip
                (landmarks[152].x * size[0], landmarks[152].y * size[1]), # Chin
                (landmarks[263].x * size[0], landmarks[263].y * size[1]), # Left eye left corner
                (landmarks[33].x * size[0], landmarks[33].y * size[1]),   # Right eye right corner
                (landmarks[287].x * size[0], landmarks[287].y * size[1]), # Left mouth corner
                (landmarks[57].x * size[0], landmarks[57].y * size[1])    # Right mouth corner
            ], dtype="double")

            # Solve PnP
            success, rotation_vector, translation_vector = cv2.solvePnP(
                model_points, image_points, camera_matrix, dist_coeffs, flags=cv2.SOLVEPNP_ITERATIVE)

            # Convert rotation vector to rotation matrix
            rotation_mat, _ = cv2.Rodrigues(rotation_vector)
            angles, _, _, _, _, _ = cv2.RQDecomp3x3(rotation_mat)

            pitch, yaw, roll = angles

            cv2.putText(frame, f"Pitch: {pitch:.2f}", (30, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0,255,0), 2)
            cv2.putText(frame, f"Yaw: {yaw:.2f}", (30, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0,255,0), 2)
            cv2.putText(frame, f"Roll: {roll:.2f}", (30, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0,255,0), 2)


            # face box
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


            # mouth 
                    # Get upper and lower lip positions
            top_lip = landmarks[13]
            bottom_lip = landmarks[14]

            top = np.array([top_lip.x * size[0], top_lip.y * size[1]])
            bottom = np.array([bottom_lip.x * size[0], bottom_lip.y * size[1]])

            # Compute Euclidean distance
            mouth_open_dist = np.linalg.norm(top - bottom)

            # Threshold (adjust this value depending on your camera resolution and test results)
            threshold = 10

            if mouth_open_dist > threshold:
                cv2.putText(frame, "Mouth: OPEN", (30, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
            else:
                cv2.putText(frame, "Mouth: CLOSED", (30, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

        faces = {"x": x_min,
                "y": y_min,
                "w": box_width,
                "h": box_height,
                "mouth": int(bool(mouth_open_dist > threshold)),
                "roll": int(roll),
                "pitch": int(pitch),
                "yaw": int(yaw),
                "frame_width": frame_width,
                "frame_height": frame_height,
                "frame_rate": frame_rate}


        cv2.imshow("Face Rotation", frame)
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