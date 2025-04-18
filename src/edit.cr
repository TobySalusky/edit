import rl;
import theming;
import timer;
import thread;
import element;
import ui_elements;
import maths;
import data;
import keyframing;

import std;
import map;

import dylib;
import code_manager;
import script_interface;

import yaml;
import global_settings;
import hotkey;
import cursor;

import encode_decode;

import clay_lib;
import clay_app;

c:import "tinyfiledialogs.h";

// Canvas and window

int window_width = GlobalSettings.get_int("window_width", 1200); // loaded from GlobalSettings
int window_height = GlobalSettings.get_int("window_height", 900);
Vec2 window_dimens = v2(window_width, window_height);

int canvas_width = 1200;
int canvas_height = 900;

RenderTexture canvas_temp; // actual texture drawn to, gets flipped vertically to become final `canvas`
RenderTexture canvas;

Texture eye_open_icon;
Texture eye_closed_icon;
Texture warning_icon;
Texture image_icon;

Texture play_icon;
Texture pause_icon;
Texture muted_icon;
Texture unmuted_icon;

// Audio

c:Sound fxMP3;

List<Image> imported_images = .();
bool is_video_importing = false;

List<Image> images = .();
int max_images;

// Video

int frame_rate = 60;

int current_frame = 0;
float current_time = 0;
float max_time = 5;
int max_frames = (max_time * frame_rate) as int;
float time_per_frame = 1.0 / frame_rate;

float STREAM_DURATION = time_per_frame * max_frames;
int STREAM_FRAME_RATE = frame_rate;

float dec_frame_rate = frame_rate;

enum ApplicationMode {
	Running, Exporting, Paused;
	bool operator:==(Self other) -> this as int == other as int;
}

ApplicationMode mode = .Running;

enum ExportType {
	FFMPEG_CALL, INTERNAL;
	bool operator:==(Self other) -> this as int == other as int;
}

ExportType export_type = ExportType.INTERNAL;

float INIT_VOLUME = 0.6;
float master_volume = INIT_VOLUME;
bool muted = false;

bool is_running() -> mode == ApplicationMode.Running;
bool is_exporting() -> mode == .Exporting;
bool is_paused() -> mode == .Paused;

bool ui_hidden = false;

// TODO: sort elements? (insertion sort) -> sort-by layer
// NOTE: currently we traverse N times for rendering, N = # of layers used
List<Element> elements = .();

List<Layer> layers = .(); // metadata stored per-layer (layers do not directly contain elements!)
// TODO: vid_layers & audio_layers -> combined_layers (negative indices for audio? -> rendering ui purposes?)

List<Data> data_list = .();

int selected_elem_i = 0;


struct RepeatingTimer {
	float max;
	float t;

	construct(float max_t) -> { .max = max_t, .t = max_t };
	bool DidRepeatWhileUpdating() {
		t = t - rl.GetFrameTime(); // TODO: deltaTime?
		defer {
			if (t <= 0) { t = max; }
		}

		return t <= 0;
	}
}

RepeatingTimer check_code_timer = .(0.25);

char^ LoadingDotDotDotStr() {
	float ps = rl.GetTime() - (rl.GetTime() as int);
	return t"loading.{(ps > 0.33) ? "." | ""}{(ps > 0.66) ? "." | ""}";
}

char^ OpenImageFileDialog(char^ title) {
	char^^ filters = malloc(sizeof<char^> * 3);
	filters[0] = "*.png";
	filters[1] = "*.jpg";
	filters[2] = "*.gif";
	defer free(filters);

	c:c:`char const* const* c_filters = (char const* const*) filters;`;

    char^ filePath = c:tinyfd_openFileDialog(
        title,
        "",
        3,
        c:c_filters,
        "image files",
        0
    );
    return (filePath != NULL) ? filePath | "";
}

char^ OpenDataFileDialog(char^ title) {
	char^^ filters = malloc(sizeof<char^> * 1);
	filters[0] = "*.csv";
	defer free(filters);

	c:c:`char const* const* c_filters = (char const* const*) filters;`;

	char^ filePath = c:tinyfd_openFileDialog(
		title,
		"",
		1,
		c:c_filters,
		"data files",
		0
	);
	return (filePath != NULL) ? filePath | "";
}

struct CommandLineArgs {
	char^ open_project;
	char^ save_to_project;

	construct(int argc, char^^ argv) {
		char^ open_project = NULL;
		char^ save_to_project = NULL;

		for (int i in 0..argc) {
			if (str_eq("-o", argv[i])) {
				if (i+1 >= argc) { panic("-o requires parameter:project-name (local to ./saves/)"); }
				// TODO: asserts backwards (in crust)!!
				// assert(argc > i + 1,t);
				open_project = argv[i + 1];
			} else if (str_eq("-s", argv[i])) {
				if (i+1 >= argc) { panic("-s requires parameter:project-name (local to ./saves/)"); }
			// println(t"hi: {argc=} {i+1=}");
				// assert(argc <= i + 1, "-s requires parameter:project-name (local to ./saves/)");
				save_to_project = argv[i + 1];
			}
		}

		return {
			:open_project,
			:save_to_project,
		};
	}
}

struct ProjectSave {
	static void Load(Path project_dir_path) { // TODO: don't leak mem :)
		elements = .(); // clear elements
		selected_elem_i = 0;
		
		let obj = yaml_parser{}.parse_file(project_dir_path/"manifest.yaml");

		char^ project_name = obj.get_str("project_name");
		char^ edit_version = obj.get_str("edit_version");
		int num_elements = obj.get_int("num_elements");

		// obj.delete();

		let layers_list_obj = yaml_parser{}.parse_file(project_dir_path/"layers.yaml");

		layers = .();
		for (int i in 0..layers_list_obj.list.size) {
			let& layer_obj = layers_list_obj.at_obj(i);
			layers.add(Layer{
				.visible = layer_obj.get_bool("visible"), // TODO: get_bool
			});
		}

		for (int i in 0..num_elements) {
			// TODO: free RectElement!
			AddNewElementAt(Element(RectElement.Make(), "basic_element_for_overwrite", 0, 1, -1, v2(0, 0), v2(200, 150)));
			elements.get(i).Serialize(project_dir_path/t"elements/{i}.yaml", true);
		}
	}

  static void Create(Path project_dir_path, char^ name) {
		io.mkdir(project_dir_path);

		yaml_object manifest = make_yaml_object();
		manifest.put_literal("project_name", name);
		manifest.put_literal("edit_version", "0.0.1");
		manifest.put_int("num_elements", elements.size);

		manifest.serialize_to(project_dir_path/"manifest.yaml");

		yaml_object layers_obj = make_yaml_object(); // TODO: free
		for (let& layer in layers) {
			let layer_obj = make_yaml_object();
			layer_obj.put_bool("visible", layer.visible);
			layers_obj.push_object(layer_obj);
		}
		layers_obj.serialize_to(project_dir_path/"layers.yaml");

		io.mkdir(project_dir_path/"elements");

		for (int i in 0..elements.size) {
			elements.get(i).Serialize(project_dir_path/t"elements/{i}.yaml", false);
		}
	}
}

// adds element, adding it's corresponding layer if necessary (NOTE: will create up to N layers, if placed at layer N...)
// NOTE: direct use discouraged, generally use AddNewElementAt, since that won't cause overlap issues
void AddLayersTill(int layer) {
	while (layer >= layers.size) {
		layers.add({
			.visible = true
		});
	}
}

void AddNewElement(Element elem) {
	AddLayersTill(elem.layer);
	elements.add(elem);
	for (let& elem in elements) { // NOTE: we need to link elements everytime one is added, since their addresses can change!
		elem.LinkDefaultLayers();
	}
}

// gets first layer at which there wouldn't be a collision if an element at this time/length were added!
int FirstAvailableLayerAt(float start_time, float duration) {
	for (int i in 0..layers.size) {
		bool collision = false;
		for (let& elem in elements) { // TODO: don't loop over all elements... (just the ones on the right layer pls :D)
			if (elem.layer == i && elem.CollidesWith(start_time, duration)) {
				collision = true;
				break;
			}
		}
		if (!collision) { return i; }
	}
	return layers.size; // will have to add 1 new layer to accomodate element placement
}

// sets elem to correct layer (NOTE: pass with layer=-1, for clarity)
void AddNewElementAt(Element elem) {
	AddNewElement(elem with { layer = FirstAvailableLayerAt(elem.start_time, elem.duration) });
}

void SelectNewestElement() {
	selected_elem_i = elements.size - 1;
}

float new_element_default_duration = 0.5;

bool look_at_controls = false;
bool show_add_element_options = false;

float left_panel_width = GlobalSettings.get_float("left_panel_width", 300);
void LeftPanelUI() {
	d.Rect(v2(0, 0), v2(left_panel_width, window_height), theme.panel);
	d.Rect(v2(left_panel_width, 0), v2(1, window_height), theme.panel_border);

	// Elements List
	Vec2 btn_dimens = v2(left_panel_width - 20, 40);

	if (show_add_element_options) {
		Vec2 options_tl = v2(10, window_height - 170);
		Vec2 options_dims = v2(left_panel_width - 20, 100);
		d.RectR(Rectangle.FromV(options_tl, options_dims).Pad(6), theme.button);

		// Add media file
		Vec2 icon_dimens = v2((left_panel_width - 40) / 3, 80);
		Vec2 icon_tl = options_tl + v2(5, 5);
		if (Button(icon_tl, icon_dimens, "")) {
			char^ file_path = OpenImageFileDialog("Select an image");
			if (file_path != NULL) {
				Image img = Image.Load(file_path);
				defer img.Unload();

				char^ img_name = c:GetFileNameWithoutExt(file_path);
				AddNewElementAt(Element(ImageElement.Make(file_path), strdup(img_name), current_time, new_element_default_duration, -1, v2(0, 0), v2(img.width, img.height)));
				SelectNewestElement();
				show_add_element_options = false;
			}
		}
		d.TextureAtSizeV(image_icon, icon_tl, icon_dimens);

		// Add data
		icon_tl = icon_tl + v2((left_panel_width - 40) / 3, 0);
		if (Button(icon_tl, icon_dimens, "{data}")) {
			char^ file_path = OpenDataFileDialog("Select a data file");
			println(t"Selected data file: {file_path}");
			if (strlen(file_path) > 0) {
				// Load data and apply to keyframe
				Data data = Data(file_path);
				elements.get(selected_elem_i).ApplyKeyframeData(data);
				// elements.get(selected_elem_i).ApplyData(Box<Data>.Make(data));
				data_list.add(data);
				show_add_element_options = false;
			}
		}

		// Add arbitrary element (Temporary)
		Vec2 plus_tl = options_tl + v2((left_panel_width - 10) / 3 * 2, 5);
		if (Button(plus_tl, v2((left_panel_width - 40) / 3, 80), "+")) {
			AddNewElementAt(Element(CircleElement.Make(), NULL, current_time, new_element_default_duration, -1, v2(0, 0), v2(100, 100)) with { color = Colors.Green });
			SelectNewestElement();
		}
	}
	
	// Add Element Button
	Vec2 tl = v2(10, window_height - 50);
	if (Button(tl, btn_dimens, "+")) {
		show_add_element_options = true;
	} else if (mouse.LeftClickPressed()) {
		show_add_element_options = false;
	}

	d.RectR(.(0, 0, left_panel_width, 32), theme.button);
	let& selected_elem = elements.get(selected_elem_i);
	d.Text(t"Selected: {selected_elem.name}", 5, 5, 20, Colors.RayWhite);
	// KeyframeTimelineUI();

	// SlidingFloatTextBox(.("my_f"), my_f);
}
// float my_f = 10;

struct TimelineState {
	bool dragging_elem;
	bool dragging_elem_start;
	bool dragging_elem_end;

	bool is_dragging_elem_any() -> dragging_elem || dragging_elem_end || dragging_elem_start;

	float elem_drag_init_mouse_x;
	float elem_drag_init_start;
	float elem_drag_init_end;

	bool dragging_caret;
}
TimelineState timeline = {
	.dragging_elem = false,
	.dragging_elem_start = false,
	.dragging_elem_end = false,
	.elem_drag_init_mouse_x = 0,
	.elem_drag_init_start = 0,
	.elem_drag_init_end = 0,
	.dragging_caret = false,
};

int keyframe_timeline_ui_height = 100;
int element_timeline_ui_height = 180;
void ElementTimelineUI() {
	float timeline_view_start = 0;
	float timeline_view_duration = max_time;

	int show_layers = std.maxi(layers.size + 1, 3);
	float height = element_timeline_ui_height;
	float layer_height = height / show_layers;

	float whole_width = window_width as float - left_panel_width;
	Vec2 whole_tl = v2(left_panel_width + 1, window_height as float - height);
	Vec2 whole_dimens = v2(whole_width, height);
	Rectangle whole_rect = Rectangle.FromV(whole_tl, whole_dimens);
	d.RectR(whole_rect, theme.panel);

	float info_width = 32;

	for (int i in 0..show_layers) { // empty skeleton for layers
		float x = whole_tl.x;
		float y = whole_rect.b() - (i + 1) as float * layer_height;
		Rectangle r = .(x, y, info_width, layer_height);

		d.RectR(r.Inset(1), theme.button);
		d.RectR(.(x, y, whole_width, 1), theme.panel_border);

		if (layers.size > i) {
			// layer info ui -------
			let& layer = layers.get(i);

			if (Button(r.tl(), r.dimen(), "")) {
				layer.visible = !layer.visible;
			}

			d.Text(t"L{i}", x as int + 6, y as int + 6, 12, theme.timeline_layer_info_gray);

			if (layer.visible) {
				d.TextureAtRect(eye_open_icon, r.Inset(6).FitIntoSelfWithAspectRatio(1, 1));
			}
			// ---------------------
		}
	}

	Vec2 tl = whole_tl + v2(info_width, 0);
	Vec2 dimens = whole_dimens - v2(info_width, 0);

	bool pressed_inside = mouse.LeftClickPressed() && mouse.GetPos().InV(tl, dimens);

	float width = dimens.x;

	for (int i in 0..elements.size) {
		let& elem = elements.get(i);
		// elem.TimelineUI();
		float x = tl.x + (elem.start_time - timeline_view_start) / timeline_view_duration * width;
		float y = whole_rect.b() - (elem.layer + 1) as float * layer_height;

		float w = elem.duration / timeline_view_duration * width;

		Rectangle r = .(x, y, w, layer_height);

		bool has_err = elem.err_msg != NULL;
		TimelineElementColorSet color_set = (selected_elem_i == i) ? theme.elem_ui_blue | 
			(has_err ? theme.elem_ui_yellow | theme.elem_ui_pink);
		// selected -> blue
		// warning -> yellow
		// otherwise -> pink

		d.RectR(r, color_set.border);
		d.RectR(r.Inset(1), color_set.bg);

		char^ name_addendum = "";
		if (elem.content_impl#Kind() == KIND_VIDEO) {
			VideoElement^ vid = (c:elem#content_impl.ptr);
			if (vid#loading) { name_addendum = t" ({LoadingDotDotDotStr()})"; }
		}
		d.Text(t"{elem.name}{name_addendum}", x as int + 6, y as int + 6, 12, color_set.text);
		d.Text(elem.content_impl#ImplTypeStr(), x as int + 6, (y + layer_height) as int - 18, 12, color_set.text);

		bool hovering = mouse.GetPos().Between(r.tl(), r.br());
		if (has_err) {
			Vec2 warning_dimen = v2(16, 16);
			d.TextureAtSizeV(warning_icon, r.br() - warning_dimen - v2(6, 6), warning_dimen);

			if (hovering) {
				Vec2 options_tl = mouse.GetPos() + v2(0, 10);
				Vec2 options_dims = c:MeasureTextEx(c:GetFontDefault(), elem.err_msg, 16, 1);
				d.RectR(Rectangle.FromV(options_tl, options_dims).Pad(6), theme.button);
				d.Text(elem.err_msg, options_tl.x as.., options_tl.y as.., 16, Colors.White);
			}
		}

		if (timeline.is_dragging_elem_any()) {
			if (timeline.dragging_elem_start || timeline.dragging_elem_end) {
				cursor_type = CursorType.ResizeHoriz;
			} else {
				cursor_type = CursorType.SlideLeftRight;
			}
		} else if (hovering) {
			if (mouse.GetPos().Between(r.tl(), r.tl() + v2(10, layer_height))) {
				cursor_type = CursorType.ResizeHoriz;
			} else if (mouse.GetPos().Between(r.br() - v2(10, layer_height), r.br())) {
				cursor_type = CursorType.ResizeHoriz;
			} else {
				cursor_type = CursorType.SlideLeftRight;
			}
		}


		if (hovering && mouse.LeftClickPressed()) {
			selected_elem_i = i;

			if (mouse.GetPos().Between(r.tl(), r.tl() + v2(10, layer_height))) {
				timeline.dragging_elem_start = true;
			} else if (mouse.GetPos().Between(r.br() - v2(10, layer_height), r.br())) {
				timeline.dragging_elem_end = true;
			} else {
				timeline.dragging_elem = true;
			}
			timeline.elem_drag_init_mouse_x = mouse.GetPos().x;
			timeline.elem_drag_init_start = elem.start_time;
			timeline.elem_drag_init_end = elem.end_time();
		}
	}

	d.Rect(whole_rect.bl(), v2(dimens.x, 1), theme.panel_border); // TODO: change

	d.Rect(tl + v2(dimens.x * current_time / max_time, 0), v2(1, dimens.y), theme.active);

	// mouse interactions --------------------
	if (pressed_inside && !timeline.is_dragging_elem_any()) {
		timeline.dragging_caret = true;
	}

	if (mouse.LeftClickDown()) {
		float t_on_timeline_unbounded = (mouse.GetPos().x - tl.x) / dimens.x * max_time;
		float t_on_timeline_bounded = std.clamp(t_on_timeline_unbounded, 0, max_time);
		if (timeline.dragging_caret) {
			float new_time = (mouse.GetPos().x - tl.x) / dimens.x * max_time;
			if (new_time <= 0) { new_time = 0; }
			if (new_time >= max_time) { new_time = max_time; }
			SetTime(new_time); // TODO: add snap-to-frame-set-time
			SetFrame(current_frame);
		} else if (timeline.dragging_elem) {
			float og_t_on_timeline = (timeline.elem_drag_init_mouse_x - tl.x) / dimens.x * max_time;
			let& selected_elem = elements.get(selected_elem_i);
			selected_elem.start_time = SnapToNearestFramesTime(timeline.elem_drag_init_start + (t_on_timeline_unbounded - og_t_on_timeline));
			selected_elem.start_time = std.max(0, selected_elem.start_time);

			selected_elem.layer = (((whole_rect.b() - mouse.GetPos().y) / layer_height) as int);
			AddLayersTill(selected_elem.layer);
		} else if (timeline.dragging_elem_start) {
			float og_t_on_timeline = (timeline.elem_drag_init_mouse_x - tl.x) / dimens.x * max_time;
			let& selected_elem = elements.get(selected_elem_i);
			selected_elem.start_time = SnapToNearestFramesTime(timeline.elem_drag_init_start + (t_on_timeline_unbounded - og_t_on_timeline));
			selected_elem.start_time = std.max(0, selected_elem.start_time);
			selected_elem.duration = (timeline.elem_drag_init_end - timeline.elem_drag_init_start) - (selected_elem.start_time - timeline.elem_drag_init_start);
		} else if (timeline.dragging_elem_end) {
			float og_t_on_timeline = (timeline.elem_drag_init_mouse_x - tl.x) / dimens.x * max_time;
			let& selected_elem = elements.get(selected_elem_i);
			selected_elem.duration = SnapToNearestFramesTime((timeline.elem_drag_init_end - timeline.elem_drag_init_start) + (t_on_timeline_unbounded - og_t_on_timeline));
		}
	}

	if (!mouse.LeftClickDown()) {
		timeline.dragging_caret = false;
		timeline.dragging_elem = false;
		timeline.dragging_elem_start = false;
		timeline.dragging_elem_end = false;

		CullEmptyLayers();
	}
}

bool keyframe_timeline_dragging = false;
// TODO: move over!
void KeyframeTimelineUI() {
	int info_width = 100;
	// int width = window_width - left_panel_width - info_width;
	int width = left_panel_width as ..;
	int height = keyframe_timeline_ui_height;

	int y_start = 32;
	Vec2 info_tl = v2(0, y_start);

	Vec2 tl = v2(info_width, y_start);
	Vec2 dimens = v2(width - info_width, height);


	//  info -------------------
	d.Rect(info_tl, v2(info_width, height), theme.panel);
	// d.Rect(tl + v2(info_width - 1, 0), v2(1, height), theme.panel_border);
	// /info -------------------

	//  ui -------------------
	d.Rect(tl, dimens, theme.panel);
	d.Rect(tl, v2(dimens.x, 1), theme.panel_border);

	let& selected_elem = elements.get(selected_elem_i);

	d.Rect(tl + v2(dimens.x * std.clamp((current_time - selected_elem.start_time) / selected_elem.duration, 0, 1), 0), v2(1, dimens.y), theme.active);

	int i = 0;


	int kl_height = height / 5;
	Vec2 kl_dimens = v2(dimens.x, kl_height);
	float max_elem_time = selected_elem.duration;

	float curr_lt = current_time - selected_elem.start_time;
	// KeyframeLayerUI_Float(selected_elem.kl_pos_x, tl, kl_dimens, max_elem_time, curr_lt, "x", i); i++;
	// KeyframeLayerUI_Float(selected_elem.kl_pos_y, tl, kl_dimens, max_elem_time, curr_lt, "y", i); i++;
	// KeyframeLayerUI_Float(selected_elem.kl_scale, tl, kl_dimens, max_elem_time, curr_lt, "scale", i); i++;
	// KeyframeLayerUI_Float(selected_elem.kl_rotation, tl, kl_dimens, max_elem_time, curr_lt, "angle", i); i++;
	// KeyframeLayerUI_Float(selected_elem.kl_opacity, tl, kl_dimens, max_elem_time, curr_lt, "opacity", i); i++;

	// .UI(max_elem_time, curr_lt, layer.name, i);
	if (mouse.LeftClickPressed() && mouse.GetPos().InV(tl, dimens)) {
		keyframe_timeline_dragging = true;
	}

	if (mouse.LeftClickDown() && keyframe_timeline_dragging) {
		float new_time = std.clamp(((mouse.GetPos().x - tl.x) / dimens.x), 0, 1) * selected_elem.duration + selected_elem.start_time;
		if (new_time <= 0) { new_time = 0; }
		if (new_time >= max_time) { new_time = max_time; }
		SetTime(new_time); // TODO: add snap-to-frame-set-time
		SetFrame(current_frame);
	}

	if (!mouse.LeftClickDown()) {
		keyframe_timeline_dragging = false;
	}
	//  /ui -------------------
}

float SnapToNearestFramesTime(float time) -> ((time / time_per_frame) as int) as float / frame_rate;

void SetFrame(int frame) {
	current_time = time_per_frame * frame;
	current_frame = frame;
	UpdateState();
}

void SetTime(float new_time) {
	current_time = new_time;
	current_frame = (current_time / time_per_frame) as int;
	UpdateState();
}

bool ElementIsVisibleNow(Element& elem) {
	return elem.visible && elem.ActiveAtTime(current_time) && layers.get(elem.layer).visible;
}

void UpdateState() {
	for (let& elem in elements) {
		if (elem.content_impl#Kind() == KIND_VIDEO) {
			VideoElement^ vid = (c:elem#content_impl.ptr);
			if (!vid#loaded && vid#loading && !is_video_importing) {
				// convert images to textures
				for (int i in 0..imported_images.size) {
					Image& img = imported_images.get(i);
					Texture tex = c:LoadTextureFromImage(img);
					vid#frames.add(tex);
					img.Unload();
				}
				// free image list
				imported_images.delete();
				imported_images = .();

				vid#loaded = true;
				vid#loading = false;
			}
		}
	}
	for (let& elem in elements) {
		if (ElementIsVisibleNow(elem)) { // QUESTION: should we update non-rendered elements? - currently I say no (may change if we add element dependencies!)
			elem.UpdateState(current_time);
		}
		if (elem.content_impl#Kind() == KIND_VIDEO) {
			VideoElement^ vid = (c:elem#content_impl.ptr);
			if (!vid#loaded && !vid#loading && !is_video_importing) {
				vid#loading = true;
				is_video_importing = true;
				go_with(ImportVideoThread, vid);
			}
		}
	}
}

void DrawFrameToCanvas() {
	canvas_temp.Begin();
	d.ClearBackground(theme.bg);
	for (int i in 0..layers.size) {
		for (let& elem in elements) {
			if (elem.layer == i && ElementIsVisibleNow(elem)) {
				elem.Draw(current_time);
			}
		}
	}

	if (!is_exporting()) {
		elements.get(selected_elem_i).DrawGizmos();
	}

	canvas_temp.End();

	canvas.Begin(); // rendering to another render texture flips it again haha
		d.Texture(canvas_temp.texture, { 0, 0 });
	canvas.End();
}

void ExportVideoThread() {
	ExportVideo(frame_rate, "out", "edit_video");

	SetMode(.Paused);
	SetFrame(0);
}

// Currently, we do not support multiple simulataneous import threads
// or overwritten video elements
void ImportVideoThread(void^ user_data) {
	VideoElement^ vid = user_data;
	EncodingDecoding.ImportVideoImpl(strdup(vid#video_file_path), vid#dec_fr, imported_images);
	is_video_importing = false;
}

void DrawProgressBar(Vec2 tl, Vec2 dimens, Color bg, Color fg, float amount) {
	d.Rect(tl, dimens, bg);
	d.Rect(tl, dimens * v2(amount, 1), fg);
}

void DrawExportProgressOverlay() {
	Color shadow = hex("00000077");
	d.Rect(v2(0, 0), window_dimens, shadow);

	float width = 0.5 * window_width;
	float height = 20 * 5 + 2 * 10;
	Vec2 tl = window_dimens * v2(0.25, 0.5) - v2(0, height / 2);
	Vec2 dimens = v2(width, height);
	d.Rect(tl - v2(4, -1), dimens + v2(8, 3), hex("00000033"));
	d.Rect(tl - v2(1, 1), dimens + v2(2, 2), Colors.Black);
	d.Rect(tl, dimens, theme.panel);

	Color progress_bg = hex("262626"); // gray
	Color progress_fg = hex("afc7af"); // green

	Vec2 pbar_tl = v2(tl.x + 20, tl.y + 20);
	Vec2 pbar_dimens = v2(width - 40, 20);

	DrawProgressBar(pbar_tl, pbar_dimens, progress_bg, progress_fg, (export_state.frames_rendered) as float / export_state.total_frames);

	pbar_tl.y = pbar_tl.y + 30;
	DrawProgressBar(pbar_tl, pbar_dimens, progress_bg, progress_fg, (export_state.frames_written) as float / export_state.total_frames);

	pbar_tl.y = pbar_tl.y + 30;
	Color ffmpeg_load_pulse_color = 
		export_state.is_ffmpegging
			? ColorLerp(progress_bg, progress_fg, Sin01((rl.GetTime() - export_state.start_ffmpeg_time) * 5) * 0.7)
			| progress_bg;
	d.Rect(pbar_tl, pbar_dimens, ffmpeg_load_pulse_color);
}

void SetMute(bool mute) {
	if (mute) {
		c:SetMasterVolume(0.0);
	} else {
		c:SetMasterVolume(master_volume);
	}
	muted = mute;
}

void SetMode(ApplicationMode new_mode) {
	mode = new_mode;
	switch (new_mode) { // mode change side effects
		.Running -> {
			c:ResumeSound(fxMP3);
		},
		else -> {
			c:PauseSound(fxMP3);
		},
	}
}

void CullEmptyLayers() {
	for (int i = layers.size - 1; i >= 0; i--;) {
		for (let& elem in elements) {
			if (elem.layer == i) { return; }
		}
		layers.pop_back();
	}
}

Vec2 GetMousePosWorldSpace() {
	// TODO: fix this???
	let canvas_rect = canvas_rect;
	return (mouse.GetPos() - canvas_rect.tl()) / (canvas_rect.dimen() / window_dimens);
}

void UpdateWindowSize(int width, int height) {
	window_width = GlobalSettings.set_int("window_width", width);
	window_height = GlobalSettings.set_int("window_height", height);
	window_dimens = v2(width, height);
}

PanelExpander left_panel_expander = { ^left_panel_width, "left_panel_width", .min = 100 };

char^ ImportMovieModal_errmsg = NULL;
void ImportMovieModalJustOpened() {
	ImportMovieModal_set_errmsg(NULL);

	GetTextInput(UiElementID.ID("ImportMovieModal-file-input")).Activate();
}
void ImportMovieModal_set_errmsg(char^ malloced_err_msg) {
	if (ImportMovieModal_errmsg != NULL) { free(ImportMovieModal_errmsg); }
	ImportMovieModal_errmsg = malloced_err_msg;
}
void ImportMovieModal() {
	TextInputState^ textbox;

	#clay({
		.layout = {
			.sizing = {
				CLAY_SIZING_GROW(),
				CLAY_SIZING_FIXED(rem(1.5))
			},
			.childAlignment = { .y = CLAY_ALIGN_Y_CENTER }
		}
	}) {
		clay_text("Video File Path: ", {
			.fontSize = rem(1),
			.textColor = Colors.White,
		});
		textbox = ^TextBoxMaintained(UiElementID.ID("ImportMovieModal-file-input"), .("ImportMovieModal-file-input"), "", Clay_Sizing.Grow(), rem(1));
	}

	if (ImportMovieModal_errmsg != NULL) {
		#clay({
			.layout = {
				.sizing = {
					CLAY_SIZING_GROW(),
					CLAY_SIZING_FIXED(rem(1.5))
				},
				.childAlignment = { .y = CLAY_ALIGN_Y_CENTER }
			}
		}) {
			clay_text(ImportMovieModal_errmsg, {
				.fontSize = rem(1),
				.textColor = theme.errmsg,
			});
		}
	}

	if (key.IsPressed(KEY.ENTER) && textbox#is_active()) {
		if (io.file_exists(textbox#buffer)) {
			char^ video_path = strdup(textbox#buffer);
			char^ video_name = strdup(rl.GetFileNameWithoutExt(video_path)); // strdup-ed b/c GetFileNameWithoutExt returns static string
			VideoElement^ ve = VideoElement.Make(video_path);
			AddNewElementAt(Element(ve, video_name, current_time, time_per_frame * max_frames, -1, v2(0, 0), v2(canvas_width, canvas_height)));
			SelectNewestElement();
			CloseModal();
		} else {
			ImportMovieModal_set_errmsg(f"File does not exist!");
		}
	}
}

bool first_frame = true;
void GameTick() {
	cursor_type = .Default;

	ui_element_activated_this_frame = false;

	if (window_width != rl.GetScreenWidth() || window_height != rl.GetScreenHeight()) {
		UpdateWindowSize(rl.GetScreenWidth(), rl.GetScreenHeight());
	}

	mp_world_space = GetMousePosWorldSpace();

	if (check_code_timer.DidRepeatWhileUpdating()) {
		code_man.CheckModifiedTimeAndReloadIfNecessary();
	}

	// d.ClearBackground(theme.bg);
	d.ClearBackground(Colors.Black);

	if (HotKeys.PlayPause.IsPressed()) {
		if (is_running()) {
			SetMode(.Paused);
			SetFrame(current_frame);
		} else if (is_paused()) {
			SetMode(.Running);
		}
	}

	if (HotKeys.Mute.IsPressed()) {
		SetMute(!muted);
	}

	// export movie
	if (HotKeys.ExportMovie.IsPressed()) { // NOTE: E (export)
		SetMode(.Exporting);
		export_state = make_export_state(max_frames);
		SetFrame(0);
	}

	if (HotKeys.ToggleHideUIFullscreenPlayback.IsPressed()) {
		ui_hidden = !ui_hidden;
	}

	if (elements.size > 1 && HotKeys.Temp_DeleteElement.IsPressed()) {
		elements.remove_at(selected_elem_i);
		CullEmptyLayers();
		if (selected_elem_i == elements.size) { selected_elem_i--; }
	}

	if (HotKeys.Temp_ClearTimeline.IsPressed()) {
		elements.get(selected_elem_i).ClearTimelinesCompletely();
	}

	// if (HotKeys.Temp_ReloadCode.IsPressed()) {
	// 	code_man.Reload();
	// }

	// if (HotKeys.Temp_AddElementCool.IsPressed()) {
	// 	elements.add(make_cool_fn_element());
	// }
	//
	// if (HotKeys.Temp_AddElementCircle.IsPressed()) {
	// 	elements.add(make_element());
	// }

	// :hotkey:use:global

	// if (!is_paused()) {
	UpdateState();
	// }

	DrawFrameToCanvas();

	if (is_running()) {
		float new_time = current_time + rl.GetFrameTime();
		if (new_time > max_time) { new_time = 0; }
		SetTime(new_time);
	} else if (is_exporting()) {
		if (export_state.frames_rendered < max_frames) {
			// Images of format type: PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 == 7 (by raylib.h)
			// Appears equivalent to PIX_FMT_RGBA of FFMPEG
			Image img = rl.LoadImageFromTexture(canvas.texture);
			if (export_type == ExportType.INTERNAL) {
				// c:ImageFlipVertical(^img); NOTE: rae commented out, don't think we need now but may be wrong :) (have not checked)
				c:c:`
				//pthread_mutex_lock(&images_lock);
				//while (images.size >= images.capacity) {
				//	pthread_cond_wait(&less, &images_lock);
				//}
				`;
				images.add(img);
				c:c:`
				//pthread_cond_signal(&more);
				//pthread_mutex_unlock(&images_lock);
				`;

				export_state.frames_rendered++;
				SetFrame(current_frame + 1);
			}
			
		}
		if (!export_state.is_ffmpegging && export_state.frames_rendered == max_frames) {
			export_state.is_ffmpegging = true;
			export_state.start_ffmpeg_time = c:GetTime();
			go(ExportVideoThread);
		}
	}

	// let canvas_rect = CanvasRect();
	// d.TextureAtRect(canvas, canvas_rect);
	// d.RectOutlineR(canvas_rect, theme.bg);

	if (!is_exporting()) {
		if (mouse.LeftClickPressed()) {
			// TODO:(toby) go down in layer!!!, not by i
			for (int i = elements.size - 1; i >= 0; i--;) {
				if (ElementIsVisibleNow(elements.get(i)) && elements.get(i).Hovered()) {
					selected_elem_i = i;
					break;
				}
			}
		}

		if (HotKeys.KeyAtCurrentPosition.IsPressed() || HotKeys.Alternative_KeyAtCurrentPosition.IsPressed()) { // NOTE: K (keyframe)
			let& elem = elements.get(selected_elem_i);
			float keyframe_t = std.clamp(current_time - elem.start_time, 0, elem.duration);
			elem.kl_pos().InsertValue(
				keyframe_t,
				mp_world_space
			);
		}

		if (HotKeys.ImportMovie.IsPressed()) {
			ImportMovieModalJustOpened();
			OpenModalFn(ImportMovieModal);
		}
	}

	if (HotKeys.Temp_LeftSidebar_Less.IsPressed()) {
		left_panel_width = GlobalSettings.set_float("left_panel_width", left_panel_width - 50);
	}

	if (HotKeys.Temp_LeftSidebar_More.IsPressed()) {
		left_panel_width = GlobalSettings.set_float("left_panel_width", left_panel_width + 50);
	}

	if (!ui_hidden) {
		LeftPanelUI();
		ElementTimelineUI();
	}
	// VideoPlayPauseMuteUI(PlaceVideoPlayPauseMuteUI()); // TODO: fade out when non-interacted in ui-hidden mode!

	if (is_exporting()) {
		DrawExportProgressOverlay();
	}

	if (mouse.LeftClickPressed() && !ui_element_activated_this_frame) {
		focused_ui_elem_id = UiElementID.ID(NULL);
	}

	LayoutUI();
	if (first_frame || rl.IsWindowResized()) {
		Clay.EndLayout(); // throw out initial render
		Clay.BeginLayout();
		LayoutUI();
		first_frame = false;
	}
}

void RenderAfter() {
	if (cursor_type != .Default) {
		Cursor.Hide();
		d.TextureAtRect(cursor_type.GetTexture(), RectCenter(mouse.GetPos(), Vec2_one.scale(40)));
	} else {
		Cursor.Show();
	}
}

float video_play_pause_mute_ui_height = 32;

// Vec2 PlaceVideoPlayPauseMuteUI() {
// 	let canvas_rect = CanvasRect();
// 	return v2(canvas_rect.center().x, canvas_rect.b() - (video_play_pause_mute_ui_height / 2 + 10));
// }
//
// void VideoPlayPauseMuteUI(Vec2 center_pos) {
// 	// play/pause (center) | mute
// 	float b_size = video_play_pause_mute_ui_height;
// 	Vec2 b_dim = v2(b_size, b_size);
// 	Vec2 ref = center_pos - b_dim.divide(2);
// 	Vec2 x_delta = v2(b_size + 10, 0);
// 	
// 	if (ButtonIcon(ref, b_dim, mode == .Paused ? play_icon | pause_icon)) {
// 		SetMode((mode == .Paused) ? ApplicationMode.Running | ApplicationMode.Paused);
// 	}
//
// 	if (ButtonIcon(ref + x_delta, b_dim, muted ? muted_icon | unmuted_icon)) {
// 		SetMute(!muted);
// 	}
// }

void SyncEncodingDecodingEditInfo() {
	from_edit = {
		:images,
		:canvas_width, :canvas_height,
		.STREAM_DURATION = time_per_frame * max_frames,
		.STREAM_FRAME_RATE = frame_rate
	};
}

// bool ImportVideo(char^ input_file_name_no_path) {
// 	SyncEncodingDecodingEditInfo();
// 	return EncodingDecoding.ImportVideoImpl(input_file_name_no_path, dec_frame_rate, imported_textures);
// }

void ExportVideoThreadMain() {
	ExportVideo(frame_rate, "out", "edit_video");

	SetMode(.Paused);
	SetFrame(0);
}

void ExportVideo(int framerate, char^ folder_path, char^ output_file_name_no_path) {
	int imgh = canvas.texture.height;
	int imgw = canvas.texture.width;

	SyncEncodingDecodingEditInfo();
	EncodingDecoding.ExportVideoImpl(imgw, imgh, framerate, folder_path, output_file_name_no_path);

	SetMode(.Running);
}

void OnFileDropped() {
	FilePathList dropped_file_path_list = FilePathList.Load();
	defer dropped_file_path_list.Unload();

	for (int i in 0..dropped_file_path_list.count) {
		char^ file_type = c:GetFileExtension(dropped_file_path_list.paths[i]);
		char^ file_path = strdup(dropped_file_path_list.paths[i]);
		// malloced image (the ImageElement is responsible for freeing)
		// ^ TODO: make this ownership clearer!
		println(t"File dropped: {strcmp(file_type, ".png")}");
		if (strcmp(file_type, ".png") == 0 || strcmp(file_type, ".gif") == 0 || strcmp(file_type, ".jpg") == 0) {
			// Handle image file
			Image img = Image.Load(file_path);
			defer img.Unload();
			char^ img_name = c:GetFileNameWithoutExt(file_path);
			AddNewElementAt(Element(ImageElement.Make(file_path), strdup(img_name), current_time, new_element_default_duration, -1, mouse.GetPos(), v2(img.width, img.height)));
			SelectNewestElement();

		} else if (strcmp(file_type, ".csv") == 0) {
			// Handle data file
			Data data = Data(file_path);
			data_list.add(data);
			elements.get(selected_elem_i).ApplyKeyframeData(data, current_time, (1.0 / frame_rate));
		} else if (strcmp(file_type, ".mp4") == 0) {
			// Handle video file
			char^ video_name = c:GetFileNameWithoutExt(file_path);
			AddNewElementAt(Element(VideoElement.Make(file_path), strdup(video_name), current_time, 1, -1, v2(0, 0), v2(canvas_width, canvas_height)));
			SelectNewestElement();
		} else {
			println(t"Unsupported file type: {file_type}");
		}

	}
}

Rectangle UnCoveredArea() {
	if (ui_hidden) {
		return .(0, 0, window_width, window_height);
	}

	return .(left_panel_width, 0, window_width as float - left_panel_width, window_height - (element_timeline_ui_height));
}

Rectangle canvas_rect = { 0, 0, 0, 0};

enum PanelDragDir {
	Left, Right, Top, Bottom, 
	Expand // only 1 expand per axis!
}
void SidePanelContents() {
	Element& selected = elements.get(selected_elem_i);

	CLAY_TEXT(.(t"Selected: {selected.name}"), CLAY_TEXT_CONFIG({
		.fontSize = 32,
		.textColor = Colors.White
	}));
	// // vert spacer ---
	// #clay({ .layout = { .sizing = .(0, 16) } }) {}

	let& selected_elem = elements.get(selected_elem_i);
	float max_elem_time = selected_elem.duration;

	float curr_local_time = current_time - selected_elem.start_time;

	selected_elem.default_layers.UI({ :max_elem_time, :curr_local_time });

	if (selected_elem.content_impl#CustomLayersList() != NULL) {
		selected_elem.content_impl#CustomLayersList()#UI({ :max_elem_time, :curr_local_time });
	}
}

void SidePanel() {

	#clay({
		.id = CLAY_ID("side-panel"),
		.layout = {
			.sizing = { CLAY_SIZING_FIXED(left_panel_width), CLAY_SIZING_GROW() },
		},
		.backgroundColor = theme.panel,
	}) {
		#clay({
			.layout = {
				.sizing = {
					.width = CLAY_SIZING_PERCENT(1),
					.height = CLAY_SIZING_PERCENT(1),
				},  
				.layoutDirection = CLAY_TOP_TO_BOTTOM,
			},
		}) {
			SidePanelContents();
		}

		left_panel_expander.Update();
	}
}

void LayoutUI() {
	// File drop listener
	if (rl.IsFileDropped()) {
		OnFileDropped();
	}

    #clay({
		.id = CLAY_ID("main"),
		.layout = {
			.sizing = .(window_width, window_height - element_timeline_ui_height),
			// .padding = { .left = left_panel_width as int }
		}, 
		.backgroundColor = Colors.Transparent,
	}) {
		SidePanel();

		#clay({
			.id = CLAY_ID("video-area-wrapper"),
			.layout = {
				.sizing = { CLAY_SIZING_GROW(), CLAY_SIZING_GROW() },
				.padding = .(16), 
				.childGap = 16,
				.childAlignment = { CLAY_ALIGN_X_CENTER, CLAY_ALIGN_Y_CENTER },
			}, 
			.backgroundColor = Colors.Black,
		}) {
			// NOTE: wrong on first render (render twice for first frame to avoid)
			let parent_bounds = Clay.GetElementData(CLAY_ID("video-area-wrapper")).boundingBox;
			parent_bounds.width -= 32; // 16 padding on each side!
			parent_bounds.height -= 32;

			// manually fit this element, since aspect-ratio image scaling causes it to overflow on GROW mode... :/
			Rectangle fitted = parent_bounds.FitIntoSelfWithAspectRatio(canvas.width(), canvas.height());

			#clay({
				.id = CLAY_ID("video"),
				.floating = {
					.attachTo = CLAY_ATTACH_TO_PARENT,
					.attachPoints = {
						.element = CLAY_ATTACH_POINT_CENTER_CENTER,
						.parent = CLAY_ATTACH_POINT_CENTER_CENTER,
					}
				},
				.layout = {
					.sizing = .(fitted.width, fitted.height),
				}, 
				.image = .(canvas.texture),
			}) {
				canvas_rect = Clay.GetElementData(CLAY_ID("video")).boundingBox;
			}
		}

		DisplayModals();
	}
}

// void El(int i) {
// 	#clay({
// 		.id = CLAY_IDI("El", i),
// 		.layout = { 
// 			.sizing = {
// 				.width = CLAY_SIZING_FIT(),
// 				.height = CLAY_SIZING_FIT(),
// 			}
// 		},
// 		.backgroundColor = Colors.Green
// 	}) {
// 		#clay({
// 			.id = CLAY_IDI_LOCAL("img", i), // TODO: ???
// 			.layout = { 
// 				.sizing = {
// 					.width = CLAY_SIZING_FIXED(64),
// 					.height = CLAY_SIZING_FIXED(64),
// 				}
// 			},
// 			.image = .(warning_icon),
// 		}) {}
//
// 		CLAY_TEXT(.(t"hi {i}"), CLAY_TEXT_CONFIG({
// 			.fontSize = 64
// 		}));
// 	}
// }

int main(int argc, char^^ argv) {
	CommandLineArgs args = .(argc, argv);
	Env.DebugPrint();

	// RAYLIB INITIALIZED HERE (window.init), no loading assets (textures, images, sounds) before this point!!!
	EditClayApp.Init(window_width, window_height, f"CodeComposite{(args.save_to_project != NULL) ? t" - {args.save_to_project}" | ""}");
	defer EditClayApp.Deinit();

	// NOTE: (rae-TODO): FIX weirdness when GetScreenHeight >= actual-screen-height
	// println(t"aa: {rl.GetScreenWidth()} {rl.GetRenderWidth()}");
	// println(t"aa: {rl.GetScreenHeight()} {rl.GetRenderHeight()}");

	defer GlobalSettings.SaveUpdates();

	code_man.PreLoadTakeCareOfPreppedReload();
	code_man.Load();
	defer code_man.Unload();

	defer ImageCache.Unload(); // cleanup loaded images (we should also do this when assets are no longer in use? -- TODO: LCS eviction type thing maybe)

	CursorType.LoadAssets();
	KeyframeAssets.LoadAssets();

	// Audio init and close
	c:InitAudioDevice();
	defer c:CloseAudioDevice();
	fxMP3 = c:LoadSound("assets/history.mp3");
	defer c:UnloadSound(fxMP3);

	c:SetMasterVolume(master_volume);
	c:PlaySound(fxMP3);

	SetMute(true); // NOTE: CURRENTLY MUTING FOR DEMO

	canvas_temp = make_render_texture(1200, 900);
	canvas = make_render_texture(1200, 900);

	eye_open_icon = rl.LoadTexture(t"assets/eye_open.png");
	eye_closed_icon = rl.LoadTexture(t"assets/eye_closed.png");
	warning_icon = rl.LoadTexture(t"assets/warning_dark.png");
	image_icon = rl.LoadTexture(t"assets/image.png");

	play_icon = rl.LoadTexture(t"assets/play.png");
	pause_icon = rl.LoadTexture(t"assets/pause.png");
	muted_icon = rl.LoadTexture(t"assets/muted.png");
	unmuted_icon = rl.LoadTexture(t"assets/unmuted.png");

	images.reserve(max_frames);

	//AddNewElementAt(Element(CustomPureFnElement.Make("bar_chart"), "bar_chart", 0, 5, -1, v2(100, 100), v2(1000, 500)) with { color = Colors.Blue });
	AddNewElementAt(Element(RectElement.Make(), "Rect", 0, 1, -1, v2(0, 0), v2(200, 150)) with { color = Colors.Blue });
	// AddNewElementAt(Element(CustomPureFnElement.Make("perlin_field"), "perlin_field", 1, 2, -1, v2(0, 0), v2(100, 100)));
	// AddNewElementAt(Element(CustomPureFnElement.Make("nonexistent"), "nonexistent", 1, 0.5, -1, v2(0, 0), v2(100, 100)));
	// AddNewElementAt(Element(CustomPureFnElement.Make("cool_effect"), "cool_effect", 3, 2, -1, v2(0, 0), v2(100, 100)));
	// AddNewElementAt(Element(CustomPureFnElement.Make("PointSwarm"), "PointSwarm", 0, 3, -1, v2(0, 0), v2(100, 100)));
	AddNewElementAt(Element(CustomPureFnElement.Make("StringWheel"), "StringWheel", 0, 3, -1, v2(0, 0), v2(100, 100)));

	// AddNewElementAt(Element(CustomPureFnElement.Make("MyFx"), "MyFx", 0, 2, -1, v2(0, 0), v2(100, 100)));
	// AddNewElementAt(Element(CustomPureFnElement.Make("MyFx2"), "MyFx2", 2, 2, -1, v2(0, 0), v2(100, 100)));
	// AddNewElementAt(Element(CustomPureFnElement.Make("bar_chart"), "bar_chart", 0, 5, -1, v2(100, 100), v2(1000, 500)) with { color = Colors.Blue });

	selected_elem_i = 0;

	if (args.open_project != NULL) {
		println(t"opening: saves/{args.open_project}");
		ProjectSave.Load(Path("saves")/args.open_project);
	}

	defer {
		if (args.save_to_project != NULL) {
			ProjectSave.Create(Path("saves")/args.save_to_project, args.save_to_project);
		}
	}

	EditClayApp.MainLoop(GameTick, RenderAfter);

    return 0;
}
