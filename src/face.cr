import std;
c:import "json.h";

struct Face {
	int x;
	int y;
	int w;
	int h;
	int m;
	int roll;
	int pitch;
	int yaw;
	int frame_width;
	int frame_height;
	int frame_rate;
}

List<Face> cv_pipe() {
	
	List<Face> face_data = .();

	c:c:`
    FILE *pipe = popen("python piping.py white_lotus_short.mp4", "r");
    if (!pipe) {
        fprintf(stderr, "Failed to launch Python script: %s\n", strerror(errno));
    }

    printf("OpenCV Results:\n");
    printf("----------------\n");
    
    // Read all output lines
    char *line = NULL;
    size_t len = 0;
    size_t read;


    
    while ((read = getline(&line, &len, pipe)) != -1) {
        // Remove trailing newline if present
        if (line[read - 1] == '\n')
            line[read - 1] = '\0';

        

		struct json_value_s *root = json_parse(line, strlen(line));
    
		struct json_object_s* object = json_value_as_object(root);
		struct json_object_element_s* x_element = object->start;
		struct json_number_s* x_number = json_value_as_number(x_element->value);
		int x = atoi(x_number->number);

		struct json_object_element_s* y_element = x_element->next;
		struct json_number_s* y_number = json_value_as_number(y_element->value);
		int y = atoi(y_number->number);

		struct json_object_element_s* w_element = y_element->next;
		struct json_number_s* w_number = json_value_as_number(w_element->value);
		int w = atoi(w_number->number);

		struct json_object_element_s* h_element = w_element->next;
		struct json_number_s* h_number = json_value_as_number(h_element->value);
		int h = atoi(h_number->number);

		struct json_object_element_s* m_element = h_element->next;
		struct json_number_s* m_number = json_value_as_number(m_element->value);
		int m = atoi(m_number->number);

		struct json_object_element_s* roll_element = m_element->next;
		struct json_number_s* roll_number = json_value_as_number(roll_element->value);
		int roll = atoi(roll_number->number);

		struct json_object_element_s* pitch_element = roll_element->next;
		struct json_number_s* pitch_number = json_value_as_number(pitch_element->value);
		int pitch = atoi(pitch_number->number);
		
		struct json_object_element_s* yaw_element = pitch_element->next;
		struct json_number_s* yaw_number = json_value_as_number(yaw_element->value);
		int yaw = atoi(yaw_number->number);

		struct json_object_element_s* frame_width_element = yaw_element->next;
		struct json_number_s* frame_width_number = json_value_as_number(frame_width_element->value);
		int frame_width = atoi(frame_width_number->number);

		struct json_object_element_s* frame_height_element = frame_width_element->next;
		struct json_number_s* frame_height_number = json_value_as_number(frame_height_element->value);
		int frame_height = atoi(frame_height_number->number);

		struct json_object_element_s* frame_rate_element = frame_height_element->next;
		struct json_number_s* frame_rate_number = json_value_as_number(frame_rate_element->value);
		int frame_rate = atoi(frame_rate_number->number);

        printf("Received: %s\n", line);
        printf("x: %d y: %d w: %d h: %d m: %d\n", x, w, y, h, m);

		Face f = {x, y, w, h, m, roll, pitch, yaw, frame_width, frame_height, frame_rate};
		`;
		face_data.add(c:f);
		c:c:`
    }
    
    free(line);
    
    // Check for errors
    int status = pclose(pipe);
    if (status == -1) {
        perror("Error closing pipe");
    }
	`;
    return face_data;
}