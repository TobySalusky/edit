include path("../common");
include path("../../crust/packs/color_print");
include path("../tcc");
include path("../user_runtime_code_common");

// TODO: on ColorPicker & other temporary mini-windows... bottom-right corner three-diag-lines (expand/shrink)

import rl;
import globals;
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
import textures;
import warn;

import encode_decode;

import clay_lib;
import clay_app;

import color_print;
import std;
import hr_std;
import loaders;

@weak import ui;
import recordings;

import tcc;

c:import "tinyfiledialogs.h";

// Canvas and window

// TODO: implement this
// int edit_version = ReadEditVersion(); // NOTE: initialized
// int oldest_supported_edit_version = 1;

int window_width = GlobalSettings.get_int("window_width", 1200); // loaded from GlobalSettings
int window_height = GlobalSettings.get_int("window_height", 900);
Vec2 window_dimens = v2(window_width, window_height);

int canvas_width = 1200;
int canvas_height = 900;

RenderTexture canvas_temp; // actual texture drawn to, gets flipped vertically to become final `canvas`
RenderTexture canvas;

// Audio

c:Sound fxMP3;

List<Image> imported_images = .();
bool is_video_importing = false;

List<Image> images = .();
int max_images;

// Video

// TODO: max element-used time for composition
float DEFAULT_VIEW_RANGE_MIN_TIME = 30;

float calc_view_range_max_time() -> std.max(DEFAULT_VIEW_RANGE_MIN_TIME, Comp().effective_max_time() * 1.5);
float visual_view_range_max_time = DEFAULT_VIEW_RANGE_MIN_TIME;

enum ApplicationMode {
	Running, Exporting, Paused;
}

ApplicationMode mode = .Running;

enum ExportType {
	FFMPEG_CALL, INTERNAL;
}

ExportType export_type = ExportType.INTERNAL;

float INIT_VOLUME = 0.6;
float master_volume = INIT_VOLUME;
bool muted = false;

bool is_running() -> mode == .Running;
bool is_exporting() -> mode == .Exporting;
bool is_paused() -> mode == .Paused;

bool ui_hidden = false;

// TODO: sort elements? (insertion sort) -> sort-by layer
// NOTE: currently we traverse N times for rendering, N = # of layers used
// Element[] elements = .();

// EditLayer[] layers = .(); // metadata stored per-layer (layers do not directly contain elements!)
// TODO: vid_layers & audio_layers -> combined_layers (negative indices for audio? -> rendering ui purposes?)

// List<Data> data_list = .();

Project^[] projects = {};
int? selected_project_index = none;

bool has_proj() -> match (selected_project_index) {
	int index -> index >= 0 && (index) < projects.size,
	None -> false,
};
Project^ __fake_error_proj = NULL;
Project& Proj() {
	if (!has_proj()) {
		warn(.MISSING_PROJECT, "Requested project, but none was active");
		if (__fake_error_proj == NULL) {
			__fake_error_proj = Project.new();
		}
		return *__fake_error_proj;
	}
	return *projects[selected_project_index.!];
}

bool has_selected_elements() {
	if (!has_comp()) { return false; }

	return !Comp().selection.is_empty();
}

Element& get_primary_selected_element() {
	if (!has_selected_elements()) {
		// TODO:
		panic("get_primary_selected_element failed: TODO, warn and return fake!");
	}
	return Comp().elements.GetRef(Comp().selection[0]);
}

ElementIterable get_selected_elements_iter() {
	// if (!has_selected_elements()) {
	// 	// TODO: 
	// }
	return {
		.comp = ^Comp(),
		.handles = Comp().selection,
	};
}

bool has_comp() {
	if (!has_proj()) { return false; }
	Project& p = Proj();
	return match (p.selected_comp_index) {
		int index -> index >= 0 && (index) < p.comps.size,
		None -> false,
	};
}

Composition^ __fake_error_comp = NULL;
Composition& Comp() {
	if (!has_comp()) {
		warn(.MISSING_COMPOSITION, "Requested composition, but none was active");
		if (__fake_error_comp == NULL) {
			if (__fake_error_proj == NULL) {
				__fake_error_proj = Project.new();
			}
			__fake_error_comp = Composition.new(__fake_error_proj, 1, 1);
		}
		return *__fake_error_comp;
	}
	Project& p = Proj();
	return *p.comps[p.selected_comp_index.!];
}


// Project& proj;
// Composition& comp;
// ElementStorage& elements;
// EditLayer[]& layers;
//
// void update_global_refs() {
// 	let proj_ptr = ^get_proj();
// 	let comp_ptr = ^get_comp();
// 	let elements_ptr = ^comp_ptr#elements;
// 	let layers_ptr = ^comp_ptr#layers;
// 	c:`
// 	proj = proj_ptr;
// 	comp = comp_ptr;
// 	elements = elements_ptr;
// 	layers = layers_ptr;
// 	`;
// }

struct RepeatingTimer {
	float max;
	float t;

	construct(float max_t) -> { .max = max_t, .t = max_t };
	bool DidRepeatWhileUpdating() {
		t = t - delta_time; // TODO: deltaTime?
		defer {
			if (t <= 0) { t = max; }
		}

		return t <= 0;
	}
}

RepeatingTimer check_code_timer = .(0.25);

@[gcc_diagnostic_ignored(.unix = "-Wincompatible-pointer-types-discards-qualifiers", .win32 = "-Wdiscarded-qualifiers")]
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

@[gcc_diagnostic_ignored(.unix = "-Wincompatible-pointer-types-discards-qualifiers", .win32 = "-Wdiscarded-qualifiers")]
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

struct ProjectSaveLoadSettings {
	bool force = false;
}

struct ProjectSave {
	static void Load(Path project_dir_path, ProjectSaveLoadSettings settings = {}) { // TODO: don't leak mem :)
		// let obj = yaml_parser{}.parse_file(project_dir_path/"manifest.yaml");
		//
		// char^ project_name = obj.get_str("project_name");
		// int project_edit_version = obj.get_int("edit_version"); // NOTE: unused currently
		// if (!(project_edit_version >= oldest_supported_edit_version)) {
		// 	println(t"[DEBUG-WARNING]: Project '{project_name}' is of version={project_edit_version}, which is unsupported");
		// 	// if (settings.force) {
		// 	// 	println(t"[DEBUG-WARNING]: Continuing due to `force=true` option, crash possible!");
		// 	// } else {
		// 	// 	println(t"[DEBUG-WARNING]: Skipping Project Load to avoid possible crash!");
		// 	// 	return;
		// 	// }
		// }
		//
		// elements = .(); // clear elements
		// // TODO: will crash program if no elements loaded!!!
		// selected_elem_i = 0;
		//
		// int num_elements = obj.get_int("num_elements");
		// set_max_time(obj.get_float_default("max_time", 30));
		//
		// // obj.delete();
		//
		// let layers_list_obj = yaml_parser{}.parse_file(project_dir_path/"layers.yaml");
		//
		// layers = .();
		// for (int i in 0..layers_list_obj.list.size) {
		// 	let& layer_obj = layers_list_obj.at_obj(i);
		// 	layers.add(EditLayer{
		// 		.visible = layer_obj.get_bool("visible"), // TODO: get_bool
		// 	});
		// }
		//
		// for (int i in 0..num_elements) {
		// 	// TODO: free RectElement!
		// 	AddNewElementAt(Element(RectElement.Make(), "basic_element_for_overwrite", 0, 1, -1, v2(0, 0), v2(200, 150)));
		// 	elements.get(i).Serialize(project_dir_path/t"elements/{i}.yaml", true);
		// 	elements.get(i).LinkDefaultLayers();
		// }
	}

  static void Create(Path project_dir_path, char^ name) {
		// io.mkdir(project_dir_path);
		//
		// yaml_object manifest = {};
		// manifest.put_literal("project_name", name);
		// manifest.put_int("edit_version", edit_version);
		// manifest.put_int("num_elements", elements.size);
		// manifest.put_float("max_time", max_time);
		//
		// manifest.serialize_to(project_dir_path/"manifest.yaml");
		//
		// yaml_object layers_obj = {}; // TODO: free
		// for (let& layer in layers) {
		// 	yaml_object layer_obj = {};
		// 	layer_obj.put_bool("visible", layer.visible);
		// 	layers_obj.push_object(layer_obj);
		// }
		// layers_obj.serialize_to(project_dir_path/"layers.yaml");
		//
		// io.mkdir(project_dir_path/"elements");
		//
		// for (int i in 0..elements.size) {
		// 	elements.get(i).Serialize(project_dir_path/t"elements/{i}.yaml", false);
		// }
	}
}

// adds element, adding it's corresponding layer if necessary (NOTE: will create up to N layers, if placed at layer N...)
// NOTE: direct use discouraged, generally use AddNewElementAt, since that won't cause overlap issues
// void AddLayersTill(int layer) {
// 	while (layer >= layers.size) {
// 		layers.add({
// 			.visible = true
// 		});
// 		vertical_view_range_slider.range.end++;
// 	}
// }

// ElementHandle AddNewElementToFirstOpenLayerAtT(Element elem, EditLayer& layer, bool select_element = false) {
// 	let handle = comp.elements.Add(elem);
// 	layer.element_handles.add(handle); // TODO: sort/organize?
//
// 	if (select_element) {
// 		// comp.se
// 		// TODO: select for comp
// 	}
// 	return handle;
// }

ElementHandle AddNewSelectedElementAt(Element new_elem) { // adds to first available layer at that time
	int index = FirstAvailableLayerIndexAt(new_elem.start_time, new_elem.duration);
	let& layers = Comp().layers;
	if (index == layers.size) {
		layers.add(EditLayer.new(^Comp()));
	}
	let& layer = *layers[index];

	return AddNewElementToLayer(new_elem, layer, true);
}

// bool UNDO_GROUP__begin() -> true;
// void UNDO_GROUP__end(bool _) { }

void SetSelection(ElementHandle handle) {
	ElementHandle[] old_selection = Comp().selection.copy();
	ElementHandle[] new_selection = {};
	new_selection.add(handle);

	Comp().COMMIT_ACTION(SetSelectionAction{
		.selection = new_selection,
	}, SetSelectionAction{
		.selection = old_selection,
	});
}

ElementHandle AddNewElementToLayer(Element new_elem, EditLayer& layer, bool select_element = false) {
	// open $UNDO_GROUP();
	ElementHandle handle = { .id = new_elem.id, .last_index = Comp().elements.impl.size };

	Comp().COMMIT_ACTION(CreateNewElementAction{
		.element = new_elem,
		.layer = ^layer,
	}, DeleteElementAction{
		:handle,
	});

	if (select_element) {
		SetSelection(handle);
	}
	return handle;
}

void DeleteElement(ElementHandle eh) {
	let elem = Comp().elements.GetOptConcrete(eh).! else return;

	Comp().COMMIT_ACTION(DeleteElementAction{
		.handle = eh,
	}, CreateNewElementAction{
		.element = elem,
		.layer = elem.layer,
	});
}

// void AddNewElement(Element elem) {
// 	AddLayersTill(elem.layer);
// 	elements.add(elem);
// 	for (let& elem in elements) { // NOTE: we need to link elements everytime one is added, since their addresses can change!
// 		elem.LinkDefaultLayers();
// 	}
// }

// gets first layer at which there wouldn't be a collision if an element at this time/length were added!
int FirstAvailableLayerIndexAt(float start_time, float duration) {
	let& layers = Comp().layers;
	for (int i in 0..layers.size) {
		bool collision = false;
		let& layer = layers[i];
		for (let& elem in layer#elem_iter()) { // TODO: don't loop over all elements... (just the ones on the right layer pls :D)
			if (elem.layer == layer && elem.CollidesWith(start_time, duration)) {
				collision = true;
				break;
			}
		}
		if (!collision) { return i; }
	}
	return layers.size; // will have to add 1 new layer to accomodate element placement
}

// sets elem to correct layer (NOTE: pass with layer=-1, for clarity)
// void AddNewElementAt(Element elem) {
// 	AddNewElement(elem with { layer = FirstAvailableLayerAt(elem.start_time, elem.duration) });
// }
//
// void AddNewSelectedElementAt(Element elem) {
// 	AddNewElement(elem with { layer = FirstAvailableLayerAt(elem.start_time, elem.duration) });
// 	SelectNewestElement();
// }
//
// void SelectNewestElement() {
// 	selected_elem_i = elements.size - 1;
// }

float new_element_default_duration = 0.5;

bool look_at_controls = false;
bool show_add_element_options = false;

float left_panel_width = GlobalSettings.get_float("left_panel_width", 300);
// void LeftPanelUI() {
// 	d.Rect(v2(0, 0), v2(left_panel_width, window_height), theme.panel);
// 	d.Rect(v2(left_panel_width, 0), v2(1, window_height), theme.panel_border);
//
// 	// Elements List
// 	Vec2 btn_dimens = v2(left_panel_width - 20, 40);
//
// 	if (show_add_element_options) {
// 		Vec2 options_tl = v2(10, window_height - 170);
// 		Vec2 options_dims = v2(left_panel_width - 20, 100);
// 		d.RectR(Rectangle.FromV(options_tl, options_dims).Pad(6), theme.button);
//
// 		// Add media file
// 		Vec2 icon_dimens = v2((left_panel_width - 40) / 3, 80);
// 		Vec2 icon_tl = options_tl + v2(5, 5);
// 		if (Button(icon_tl, icon_dimens, "")) {
// 			char^ file_path = OpenImageFileDialog("Select an image");
// 			if (file_path != NULL) {
// 				Image img = Image.Load(file_path);
// 				defer img.Unload();
//
// 				char^ img_name = c:GetFileNameWithoutExt(file_path);
// 				AddNewElementAt(Element(ImageElement.Make(file_path), strdup(img_name), current_time, new_element_default_duration, -1, v2(0, 0), v2(img.width, img.height)));
// 				SelectNewestElement();
// 				show_add_element_options = false;
// 			}
// 		}
// 		d.TextureAtSizeV(Textures.image_icon, icon_tl, icon_dimens);
//
// 		// Add data
// 		icon_tl = icon_tl + v2((left_panel_width - 40) / 3, 0);
// 		if (Button(icon_tl, icon_dimens, "{data}")) {
// 			char^ file_path = OpenDataFileDialog("Select a data file");
// 			println(t"Selected data file: {file_path}");
// 			if (strlen(file_path) > 0) {
// 				// Load data and apply to keyframe
// 				Data data = Data(file_path);
// 				elements.get(selected_elem_i).ApplyKeyframeData(data);
// 				elements.get(selected_elem_i).ApplyData(Box<Data>.Make(data));
// 				data_list.add(data);
// 				show_add_element_options = false;
// 			}
// 		}
//
// 		// Add arbitrary element (Temporary)
// 		Vec2 plus_tl = options_tl + v2((left_panel_width - 10) / 3 * 2, 5);
// 		if (Button(plus_tl, v2((left_panel_width - 40) / 3, 80), "+")) {
// 			AddNewElementAt(Element(CircleElement.Make(), NULL, current_time, new_element_default_duration, -1, v2(0, 0), v2(100, 100)) with { color = Colors.Green });
// 			SelectNewestElement();
// 		}
// 	}
// 	
// 	// Add Element Button
// 	Vec2 tl = v2(10, window_height - 50);
// 	if (Button(tl, btn_dimens, "+")) {
// 		show_add_element_options = true;
// 	} else if (mouse.LeftClickPressed()) {
// 		show_add_element_options = false;
// 	}
//
// 	d.RectR(.(0, 0, left_panel_width, 32), theme.button);
// 	let& selected_elem = elements.get(selected_elem_i);
// 	d.Text(t"Selected: {selected_elem.name}", 5, 5, 20, Colors.RayWhite);
//
// 	// SlidingFloatTextBox(.("my_f"), my_f);
// }
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

float composition_timeline_height = GlobalSettings.get_float("composition_timeline_height", 180);
PanelExpander composition_timeline_panel_expander = { ^composition_timeline_height, "composition_timeline_height", .min = 100, .reverse = true, .vertical = true };

float asset_manager_panel_width = GlobalSettings.get_float("asset_manager_panel_width", 180);
PanelExpander asset_manager_panel_expander  = { ^asset_manager_panel_width, "asset_manager_panel_width", .min = 100 };

// void CompositionTimelineUI() {
// 	float timeline_view_start = 0;
// 	float timeline_view_duration = max_time;
//
// 	int show_layers = std.maxi(layers.size + 1, 3);
// 	float height = composition_timeline_height;
// 	float layer_height = height / show_layers;
//
// 	float whole_width = window_width as float - left_panel_width;
// 	Vec2 whole_tl = v2(left_panel_width + 1, window_height as float - height);
// 	Vec2 whole_dimens = v2(whole_width, height);
// 	Rectangle whole_rect = Rectangle.FromV(whole_tl, whole_dimens);
// 	d.RectR(whole_rect, theme.panel);
//
// 	float info_width = 32;
//
// 	for (int i in 0..show_layers) { // empty skeleton for layers
// 		float x = whole_tl.x;
// 		float y = whole_rect.b() - (i + 1) as float * layer_height;
// 		Rectangle r = .(x, y, info_width, layer_height);
//
// 		d.RectR(r.Inset(1), theme.button);
// 		d.RectR(.(x, y, whole_width, 1), theme.panel_border);
//
// 		if (layers.size > i) {
// 			// layer info ui -------
// 			let& layer = layers.get(i);
//
// 			if (Button(r.tl(), r.dimen(), "")) {
// 				layer.visible = !layer.visible;
// 			}
//
// 			d.Text(t"L{i}", x as int + 6, y as int + 6, 12, theme.timeline_layer_info_gray);
//
// 			if (layer.visible) {
// 				d.TextureAtRect(Textures.eye_open_icon, r.Inset(6).FitIntoSelfWithAspectRatio(1, 1));
// 			}
// 			// ---------------------
// 		}
// 	}
//
// 	Vec2 tl = whole_tl + v2(info_width, 0);
// 	Vec2 dimens = whole_dimens - v2(info_width, 0);
//
// 	bool pressed_inside = mouse.LeftClickPressed() && mouse.GetPos().InV(tl, dimens);
//
// 	float width = dimens.x;
//
// 	for (int i in 0..elements.size) {
// 		let& elem = elements.get(i);
// 		// elem.TimelineUI();
// 		float x = tl.x + (elem.start_time - timeline_view_start) / timeline_view_duration * width;
// 		float y = whole_rect.b() - (elem.layer + 1) as float * layer_height;
//
// 		float w = elem.duration / timeline_view_duration * width;
//
// 		Rectangle r = .(x, y, w, layer_height);
//
// 		bool has_err = elem.err_msg != NULL;
// 		TimelineElementColorSet color_set = (selected_elem_i == i) ? theme.elem_ui_blue | 
// 			((has_err) ? theme.elem_ui_yellow | theme.elem_ui_pink);
// 		// selected -> blue
// 		// warning -> yellow
// 		// otherwise -> pink
//
// 		d.RectR(r, color_set.border);
// 		d.RectR(r.Inset(1), color_set.bg);
//
// 		char^ name_addendum = "";
// 		if (elem.IsVideo()) {
// 			VideoElement^ vid = (c:elem#content_impl.ptr);
// 			if (vid#loading) { name_addendum = t" (loading{LoadingDotDotDotStr()})"; }
// 		}
// 		d.Text(t"{elem.name}{name_addendum}", x as int + 6, y as int + 6, 12, color_set.text);
// 		d.Text(elem.content_impl#ImplTypeStr(), x as int + 6, (y + layer_height) as int - 18, 12, color_set.text);
//
// 		bool hovering = mouse.GetPos().Between(r.tl(), r.br());
// 		if (has_err) {
// 			Vec2 warning_dimen = v2(16, 16);
// 			d.TextureAtSizeV(Textures.warning_icon, r.br() - warning_dimen - v2(6, 6), warning_dimen);
//
// 			if (hovering) {
// 				Vec2 options_tl = mouse.GetPos() + v2(0, 10);
// 				Vec2 options_dims = c:MeasureTextEx(c:GetFontDefault(), elem.err_msg, 16, 1);
// 				d.RectR(Rectangle.FromV(options_tl, options_dims).Pad(6), theme.button);
// 				d.Text(elem.err_msg, options_tl.x as.., options_tl.y as.., 16, Colors.White);
// 			}
// 		}
//
// 		if (timeline.is_dragging_elem_any()) {
// 			if (timeline.dragging_elem_start || timeline.dragging_elem_end) {
// 				cursor_type = CursorType.ResizeHoriz;
// 			} else {
// 				cursor_type = CursorType.Pointer;
// 			}
// 		} else if (hovering) {
// 			if (mouse.GetPos().Between(r.tl(), r.tl() + v2(10, layer_height))) {
// 				cursor_type = CursorType.ResizeHoriz;
// 			} else if (mouse.GetPos().Between(r.br() - v2(10, layer_height), r.br())) {
// 				cursor_type = CursorType.ResizeHoriz;
// 			} else {
// 				cursor_type = CursorType.Pointer;
// 			}
// 		}
//
//
// 		if (hovering && mouse.LeftClickPressed()) {
// 			selected_elem_i = i;
//
// 			if (mouse.GetPos().Between(r.tl(), r.tl() + v2(10, layer_height))) {
// 				timeline.dragging_elem_start = true;
// 			} else if (mouse.GetPos().Between(r.br() - v2(10, layer_height), r.br())) {
// 				timeline.dragging_elem_end = true;
// 			} else {
// 				timeline.dragging_elem = true;
// 			}
// 			timeline.elem_drag_init_mouse_x = mouse.GetPos().x;
// 			timeline.elem_drag_init_start = elem.start_time;
// 			timeline.elem_drag_init_end = elem.end_time();
// 		}
// 	}
//
// 	d.Rect(whole_rect.bl(), v2(dimens.x, 1), theme.panel_border); // TODO: change
//
// 	d.Rect(tl + v2(dimens.x * current_time / max_time, 0), v2(1, dimens.y), theme.active);
//
// 	// mouse interactions --------------------
// 	if (pressed_inside && !timeline.is_dragging_elem_any()) {
// 		timeline.dragging_caret = true;
// 	}
//
// 	if (mouse.LeftClickDown()) {
// 		float t_on_timeline_unbounded = (mouse.GetPos().x - tl.x) / dimens.x * max_time;
// 		float t_on_timeline_bounded = std.clamp(t_on_timeline_unbounded, 0, max_time);
// 		if (timeline.dragging_caret) {
// 			float new_time = (mouse.GetPos().x - tl.x) / dimens.x * max_time;
// 			if (new_time <= 0) { new_time = 0; }
// 			if (new_time >= max_time) { new_time = max_time; }
// 			SetTime(new_time); // TODO: add snap-to-frame-set-time
// 			SetFrame(current_frame);
// 		} else if (timeline.dragging_elem) {
// 			float og_t_on_timeline = (timeline.elem_drag_init_mouse_x - tl.x) / dimens.x * max_time;
// 			let& selected_elem = elements.get(selected_elem_i);
// 			selected_elem.start_time = SnapToNearestFramesTime(timeline.elem_drag_init_start + (t_on_timeline_unbounded - og_t_on_timeline));
// 			selected_elem.start_time = std.max(0, selected_elem.start_time);
//
// 			selected_elem.layer = (((whole_rect.b() - mouse.GetPos().y) / layer_height) as int);
// 			AddLayersTill(selected_elem.layer);
// 		} else if (timeline.dragging_elem_start) {
// 			float og_t_on_timeline = (timeline.elem_drag_init_mouse_x - tl.x) / dimens.x * max_time;
// 			let& selected_elem = elements.get(selected_elem_i);
// 			selected_elem.start_time = SnapToNearestFramesTime(timeline.elem_drag_init_start + (t_on_timeline_unbounded - og_t_on_timeline));
// 			selected_elem.start_time = std.max(0, selected_elem.start_time);
// 			selected_elem.duration = (timeline.elem_drag_init_end - timeline.elem_drag_init_start) - (selected_elem.start_time - timeline.elem_drag_init_start);
// 		} else if (timeline.dragging_elem_end) {
// 			float og_t_on_timeline = (timeline.elem_drag_init_mouse_x - tl.x) / dimens.x * max_time;
// 			let& selected_elem = elements.get(selected_elem_i);
// 			selected_elem.duration = SnapToNearestFramesTime((timeline.elem_drag_init_end - timeline.elem_drag_init_start) + (t_on_timeline_unbounded - og_t_on_timeline));
// 		}
// 	}
//
// 	if (!mouse.LeftClickDown()) {
// 		timeline.dragging_caret = false;
// 		timeline.dragging_elem = false;
// 		timeline.dragging_elem_start = false;
// 		timeline.dragging_elem_end = false;
//
// 		// CullEmptyLayers();
// 	}
// }

bool keyframe_timeline_dragging = false;
// TODO: move over!

float SnapToNearestFramesTime(float time) ->
	with let& comp = Comp() in
		((time / comp.time_per_frame) as int) as float / comp.frame_rate;

void SetFrame(int frame) {
	let& comp = Comp();
	comp.current_time = comp.time_per_frame * frame;
	comp.current_frame = frame;
	UpdateState();
}

void SetTime(float new_time) {
	let& comp = Comp();
	comp.current_time = new_time;
	comp.current_frame = (comp.current_time / comp.time_per_frame) as int;
	UpdateState();
}

bool ElementIsVisibleNow(Element& elem) ->
	with let& comp = Comp() in
		elem.visible && elem.ActiveAtTime(comp.current_time) && elem.layer#visible;

void UpdateState() {
	let& comp = Comp(); // ensure that comp is not changed within here!
	for (let& elem in comp.elements) {
		if (elem.IsVideo()) {
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

		if (elem.Kind() == .IMAGE_SEQUENCE) {
			ImageSequenceElement^ gif_elem = (c:elem#content_impl.ptr);
			if (gif_elem#textures == NULL) {
				gif_elem#textures = ^comp.proj#resources.Gif(gif_elem#resource_id)#textures;

				if (gif_elem#textures != NULL) {
					elem.duration = gif_elem#textures#size as float * gif_elem#time_per_frame;
				}
// ffprobe -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -of default=noprint_wrappers=1:nokey=1 squid_cry.gif
			}
		}
	}
	for (let& elem in comp.elements) {
		if (ElementIsVisibleNow(elem)) { // QUESTION: should we update non-rendered elements? - currently I say no (may change if we add element dependencies!)
			elem.UpdateState(comp, comp.current_time);
		}
		if (elem.IsVideo()) {
			VideoElement^ vid = (c:elem#content_impl.ptr);
			if (!vid#loaded && !vid#loading && !is_video_importing) {
				vid#loading = true;
				is_video_importing = true;
				go_with(ImportVideoThread, vid);
			}
		}
		// if (elem.linked_to is Some) {
		// 	let linked_elem = Comp().elements.Get(elem.linked_to as Some);
		// 	if (linked_elem != NULL) {
		// 		elem.start_time = linked_elem#start_time;
		// 		elem.duration = linked_elem#duration;
		// 	}
		// }
	}
}

void DrawFrameToCanvas() {
	canvas_temp.Begin();
	d.ClearBackground(theme.bg);
	let& comp = Comp();
	for (let& layer in comp.layers) {
		for (let& elem in layer#elem_iter()) {
			if (ElementIsVisibleNow(elem)) {
				elem.Draw(comp.current_time);
			}
		}
	}

	if (!is_exporting()) {
		for (let& element in get_selected_elements_iter()) {
			element.DrawGizmos();
		}
	}

	canvas_temp.End();

	canvas.Begin(); // rendering to another render texture flips it again haha
		d.Texture(canvas_temp.texture, { 0, 0 });
	canvas.End();
}

void ExportVideoThread() {
	ExportVideo(Comp().frame_rate, "out", "edit_video");

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

// void CullEmptyLayers() {
// 	for (int i = layers.size - 1; i >= 0; i--) {
// 		for (let& elem in elements) {
// 			if (elem.layer == i) { return; }
// 		}
// 		layers.pop_back();
// 		vertical_view_range_slider.range.end--; // NOTE: do this?
// 	}
// }

Vec2 GetMousePosWorldSpace() {
	// TODO: fix this???
	return (mouse.GetPos() - canvas_rect.tl()) / canvas_rect.dimen() * v2(canvas_width, canvas_height);
}

void UpdateWindowSize(int width, int height) {
	window_width = GlobalSettings.set_int("window_width", width);
	window_height = GlobalSettings.set_int("window_height", height);
	window_dimens = v2(width, height);
}

PanelExpander left_panel_expander = { ^left_panel_width, "left_panel_width", .min = 100 };

void DrawExportProgressOverlay() {
	//
	// DrawProgressBar(pbar_tl, pbar_dimens, progress_bg, progress_fg, (export_state.frames_rendered) as float / export_state.total_frames);
	//
	// pbar_tl.y = pbar_tl.y + 30;
	// DrawProgressBar(pbar_tl, pbar_dimens, progress_bg, progress_fg, (export_state.frames_written) as float / export_state.total_frames);
	//
	// pbar_tl.y = pbar_tl.y + 30;
	// Color ffmpeg_load_pulse_color = 
	// 	export_state.is_ffmpegging
	// 		? ColorLerp(progress_bg, progress_fg, Sin01((rl.GetTime() - export_state.start_ffmpeg_time) * 5) * 0.7)
	// 		| progress_bg;
	// d.Rect(pbar_tl, pbar_dimens, ffmpeg_load_pulse_color);
}

void ExportingModal(using ModalState& state) {
	LoadingProgressBar(t"Rendering [{export_state.frames_rendered}/{export_state.total_frames} frames]", (export_state.frames_rendered) as float / export_state.total_frames);
	LoadingProgressBar(t"Encoding [{export_state.frames_written}/{export_state.total_frames} frames]", (export_state.frames_written) as float / export_state.total_frames);
	// TODO: is_ffmpegging
}

void SaveProjectModal(using ModalState& state) {
	if (just_opened) {
		GetTextInput(UiElementID.ID("SaveProjectModal-file-input")).Activate();
	}

	TextInputState^ textbox;

	$clay({
		.layout = {
			.sizing = {
				CLAY_SIZING_GROW(),
				CLAY_SIZING_FIXED(rem(1.5))
			},
			.childAlignment = { .y = CLAY_ALIGN_Y_CENTER }
		}
	}) {
		clay_text("Project Name: ", {
			.fontSize = rem(1),
			.textColor = Colors.White,
		});
		textbox = ^TextBoxMaintained(UiElementID.ID("SaveProjectModal-file-input"), .("SaveProjectModal-file-input"), "", .Grow(), rem(1));
	};

	if (errmsg != NULL) {
		$clay({
			.layout = {
				.sizing = {
					CLAY_SIZING_GROW(),
					CLAY_SIZING_FIXED(rem(1.5))
				},
				.childAlignment = { .y = CLAY_ALIGN_Y_CENTER }
			}
		}) {
			clay_text(errmsg, {
				.fontSize = rem(1),
				.textColor = theme.errmsg,
			});
		};
	}

	if (key.IsPressed(KEY.ENTER) && textbox#is_active()) {
		string buf = string(textbox#buffer);
		string project_name = buf.trim();
		defer project_name.delete();

		Path p = Path("saves")/project_name;
		defer free(p.str);

		if (io.dir_exists(p)) {
			Path new_p = Path("saves")/t"{project_name.str}_old_{rl.GetRandomValue(0, 1000)}";
			defer free(new_p.str);

			if (!io.mv(p, new_p)) {
				state.set_errmsg(f"moving old save from '{p.str}' to '{new_p.str}' failed, write to a different name pls :)");
			} else {
				ProjectSave.Create(p, project_name);
				CloseModal();
			}
		} else {
			ProjectSave.Create(p, project_name);
			CloseModal();
		}
	}
}

void OpenProjectModal(using ModalState& state) {
	if (just_opened) {
		GetTextInput(UiElementID.ID("OpenProjectModal-file-input")).Activate();
	}

	TextInputState^ textbox;

	$clay({
		.layout = {
			.sizing = {
				CLAY_SIZING_GROW(),
				CLAY_SIZING_FIXED(rem(1.5))
			},
			.childAlignment = { .y = CLAY_ALIGN_Y_CENTER }
		}
	}) {
		clay_text("Project Name: ", {
			.fontSize = rem(1),
			.textColor = Colors.White,
		});
		textbox = ^TextBoxMaintained(UiElementID.ID("OpenProjectModal-file-input"), .("OpenProjectModal-file-input"), "", .Grow(), rem(1));
	};

	if (errmsg != NULL) {
		$clay({
			.layout = {
				.sizing = {
					CLAY_SIZING_GROW(),
					CLAY_SIZING_FIXED(rem(1.5))
				},
				.childAlignment = { .y = CLAY_ALIGN_Y_CENTER }
			}
		}) {
			clay_text(errmsg, {
				.fontSize = rem(1),
				.textColor = theme.errmsg,
			});
		};
	}

	if (key.IsPressed(KEY.ENTER) && textbox#is_active()) {
		string buf = string(textbox#buffer);
		string project_name = buf.trim();
		defer project_name.delete();

		Path p = Path("saves")/project_name;
		defer free(p.str);
		if (!io.dir_exists(p)) {
			state.set_errmsg(f"Project Save directory '{p.str}' does not exist");
		} else {
			ProjectSave.Load(Path("saves")/project_name);
			CloseModal();
		}
	}
}

void AddFaceElemModal(using ModalState& state) {
	if (just_opened) {
		GetTextInput(UiElementID.ID("AddFaceElemModal-file-input")).Activate();
	}

	TextInputState^ textbox1;
	TextInputState^ textbox2;
	TextInputState^ textbox3;

	$clay({
		.layout = {
			.sizing = {
				CLAY_SIZING_GROW(),
				CLAY_SIZING_FIXED(rem(2.5)),
			},
			.childAlignment = { .y = CLAY_ALIGN_Y_CENTER },
			.padding = { .bottom = rem(1) }
		}
	}) {
		clay_text("Video File Path: ", {
			.fontSize = rem(1),
			.textColor = Colors.White,
		});
		textbox1 = ^TextBoxMaintained(UiElementID.ID("AddFaceElemModal-file-input"), .("OpenProjectModal-file-input"), "", .Grow(), rem(1));
	};

	$clay({
		.layout = {
			.sizing = {
				CLAY_SIZING_GROW(),
				CLAY_SIZING_FIXED(rem(2.5))
			},
			.childAlignment = { .y = CLAY_ALIGN_Y_CENTER },
			.padding = { .bottom = rem(1) }
		}
	}) {
		clay_text("Closed Mouth Image File Path: ", {
			.fontSize = rem(1),
			.textColor = Colors.White,
		});
		textbox2 = ^TextBoxMaintained(UiElementID.ID("AddFaceElemModal-file-input-2"), .("OpenProjectModal-file-input-2"), "", .Grow(), rem(1));
	};

	$clay({
		.layout = {
			.sizing = {
				CLAY_SIZING_GROW(),
				CLAY_SIZING_FIXED(rem(1.5))
			},
			.childAlignment = { .y = CLAY_ALIGN_Y_CENTER }
		}
	}) {
		clay_text("Open Mouth Image File Path: ", {
			.fontSize = rem(1),
			.textColor = Colors.White,
		});
		textbox3 = ^TextBoxMaintained(UiElementID.ID("AddFaceElemModal-file-input-3"), .("OpenProjectModal-file-input-3"), "", .Grow(), rem(1));
	};

	if (errmsg != NULL) {
		$clay({
			.layout = {
				.sizing = {
					CLAY_SIZING_GROW(),
					CLAY_SIZING_FIXED(rem(1.5))
				},
				.childAlignment = { .y = CLAY_ALIGN_Y_CENTER }
			}
		}) {
			clay_text(errmsg, {
				.fontSize = rem(1),
				.textColor = theme.errmsg,
			});
		};
	}

	if (key.IsPressed(KEY.ENTER)) {
		if (!io.file_exists(textbox1#buffer)) {
			state.set_errmsg(f"Video file '{textbox1#buffer}' does not exist!");
		} else if (!io.file_exists(textbox2#buffer)) {
			state.set_errmsg(f"Closed-mouth Image file '{textbox2#buffer}' does not exist!");
		} else if (!io.file_exists(textbox3#buffer)) {
			state.set_errmsg(f"Open-mouth Image file '{textbox3#buffer}' does not exist!");
		} else {

			// TODO: add face elem using paths!
			CloseModal();
		}
	}
}


// TODO: future e.g: MyCustomElem + ChromaKey(GREEN) + BlahCustomEffect
// TODO: future e.g: my_imgs/*.png, vid.mp4, extra_audio.ogg
void QuickAddModal(using ModalState& state) {
	let& comp = Comp();
	if (just_opened) {
		GetTextInput(UiElementID.ID("QuickAddModal-file-input")).Activate();
	}

	TextInputState^ textbox;

	$clay({
		.layout = {
			.sizing = {
				CLAY_SIZING_GROW(),
				CLAY_SIZING_FIXED(rem(1.5))
			},
			.childAlignment = { .y = CLAY_ALIGN_Y_CENTER }
		}
	}) {
		clay_text("Add: ", {
			.fontSize = rem(1),
			.textColor = Colors.White,
		});
		textbox = ^TextBoxMaintained(UiElementID.ID("QuickAddModal-file-input"), .("QuickAddModal-file-input"), "", .Grow(), rem(1));
	};

	$clay({
		.id = .("scroll-quick-add-container"),
		.layout = {
			.sizing = {
				.width = .portion(1),
				.height = .portion(1),
			},
			.layoutDirection = CLAY_TOP_TO_BOTTOM,
			.childGap = 10,
		},
		.backgroundColor = Colors.Red,
		.clip = {
			.vertical = true,
			.childOffset = v2(0, -(((rl.GetTime() * 20) as int) % 1000)),
		},
	}) {
		for i in 0..20 {
			$clay({
			 .layout = {
				 .sizing = { .grow(), .fixed(rem(1.5)) },
			 },
			 .border = .(1, Colors.Black) 
			}) {};
		}
	};

	if (errmsg != NULL) {
		$clay({
			.layout = {
				.sizing = {
					CLAY_SIZING_GROW(),
					CLAY_SIZING_FIXED(rem(1.5))
				},
				.childAlignment = { .y = CLAY_ALIGN_Y_CENTER }
			}
		}) {
			clay_text(errmsg, {
				.fontSize = rem(1),
				.textColor = theme.errmsg,
			});
		};
	}

	if (key.IsPressed(KEY.ENTER) && textbox#is_active()) {
		string buf = string(textbox#buffer);
		string text = buf.trim();
		defer text.delete();

		if (text == .("rect")) {
			AddNewSelectedElementAt(Element(RectElement.Make(), "rect", comp.current_time, 1, NULL, v2(0, 0), v2(canvas_width, canvas_height)));
		} else if (text == .("circle")) {
			AddNewSelectedElementAt(Element(CircleElement.Make(), "circle", comp.current_time, 1, NULL, v2(0, 0), v2(canvas_width, canvas_height)));
		}

		if (text.contains(".")) {
			if (io.file_exists(text)) {
				ProcessDroppedFile(text, false);
				CloseModal();
			} else {
				state.set_errmsg(f"File does not exist!");
			}
		} else {
			switch (code_man.GetFn(text)) {
				void^ handle -> {
					// fn properly loaded
					let name = strdup(text);
					CustomPureFnElement^ fn_elem = CustomPureFnElement.Make(name);
					AddNewSelectedElementAt(Element(fn_elem, name, comp.current_time, 1, NULL, v2(0, 0), v2(canvas_width, canvas_height)));
					CloseModal();
				},
				char^ err -> {
					state.set_errmsg(f"Custom function error: {err}");
				}
			}
		}


		// if (io.file_exists(textbox#buffer)) {
		//
		// 	// char^ video_path = strdup(textbox#buffer);
		// 	// char^ video_name = strdup(rl.GetFileNameWithoutExt(video_path)); // strdup-ed b/c GetFileNameWithoutExt returns static string
		// 	// VideoElement^ ve = VideoElement.Make(video_path);
		// 	// AddNewElementAt(Element(ve, video_name, current_time, time_per_frame * max_frames, -1, v2(0, 0), v2(canvas_width, canvas_height)));
		// 	// SelectNewestElement();
		// 	// CloseModal();
		// } else {
		// 	state.set_errmsg(f"File does not exist!");
		// }
	}
}

void AddVideoFromPath(char^ path, Vec2 pos = {}) {
	let& comp = Comp();
	if (!io.file_exists(path)) {
		println("[WARNING]: AddVideoFromPath path does not exist!");
		return;
	}

	char^ video_path = strdup(path);
	char^ video_name = strdup(rl.GetFileNameWithoutExt(video_path)); // strdup-ed b/c GetFileNameWithoutExt returns static string
	VideoElement^ ve = VideoElement.Make(video_path);
	// TODO: don't use max_time as length of video!!! get actual timing before spawning Element
	AddNewSelectedElementAt(Element(ve, video_name, comp.current_time, comp.effective_max_time(), NULL, v2(0, 0), v2(canvas_width, canvas_height)));
}

void ImportMovieModal(using ModalState& state) {
	if (just_opened) {
		GetTextInput(UiElementID.ID("ImportMovieModal-file-input")).Activate();
	}

	TextInputState^ textbox;

	$clay({
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
		textbox = ^TextBoxMaintained(UiElementID.ID("ImportMovieModal-file-input"), .("ImportMovieModal-file-input"), "", .Grow(), rem(1));
	};

	if (errmsg != NULL) {
		$clay({
			.layout = {
				.sizing = {
					CLAY_SIZING_GROW(),
					CLAY_SIZING_FIXED(rem(1.5))
				},
				.childAlignment = { .y = CLAY_ALIGN_Y_CENTER }
			}
		}) {
			clay_text(errmsg, {
				.fontSize = rem(1),
				.textColor = theme.errmsg,
			});
		};
	}

	if (key.IsPressed(KEY.ENTER) && textbox#is_active()) {
		if (io.file_exists(textbox#buffer)) {
			// TODO: check extension to see support?
			AddVideoFromPath(textbox#buffer);
			CloseModal();
		} else {
			state.set_errmsg(f"File does not exist!");
		}
	}
}

bool first_frame = true;
// TODO: don't update comp inside method b/c of `comp`... or use Comp()
float delta_time = 1.0 / 60;
void GameTick() {
	{
		delta_time = 
			(hr_once)
				? 1.0 / 60
				| rl.GetFrameTime();
	}

	let& comp = Comp();
	cursor_type = .Default;

	ui_element_activated_this_frame = false;

	if (window_width != rl.GetScreenWidth() || window_height != rl.GetScreenHeight()) {
		UpdateWindowSize(rl.GetScreenWidth(), rl.GetScreenHeight());
	}

	last_mouse_pos = mouse_pos;
	mouse_pos = mouse.GetPos();
	last_ws_mouse_pos = ws_mouse_pos;
	ws_mouse_pos = GetMousePosWorldSpace();

	Clay.SetFrameGlobalData({
		:mouse_pos
	});

	if (check_code_timer.DidRepeatWhileUpdating()) {
		code_man.CheckModifiedTimeAndReloadIfNecessary();
	}

	// d.ClearBackground(theme.bg);
	d.ClearBackground(Colors.Purple); // NOTE: purple to see if any leaks thru!

	if (HotKeys.PlayPause.IsPressed() && has_comp()) {
		if (is_running()) {
			SetMode(.Paused);
			SetFrame(Comp().current_frame);
		} else if (is_paused()) {
			SetMode(.Running);
		}
	}

	if (HotKeys.Mute.IsPressed()) {
		SetMute(!muted);
	}

	// export movie
	if (HotKeys.ExportMovie.IsPressed() && mode != .Exporting && has_comp()) { // NOTE: E (export)
		SetMode(.Exporting);
		export_state = make_export_state(Comp().effective_max_frames());
		SetFrame(0);

		OpenModalFn(ExportingModal);
	}

	if (HotKeys.ToggleHideUIFullscreenPlayback.IsPressed()) {
		ui_hidden = !ui_hidden;
	}

	// if (elements.size > 1 && (HotKeys.DeleteSelection.IsPressed() || HotKeys.AlternativeDeleteSelection.IsPressed())) {
	// 	elements.remove_at(selected_elem_i);
	// 	// CullEmptyLayers();
	// 	if (selected_elem_i == elements.size) { selected_elem_i--; }
	// }

	// if (HotKeys.Temp_ClearTimeline.IsPressed()) {
	// 	elements.get(selected_elem_i).ClearTimelinesCompletely();
	// }

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
		if (has_comp()) {
			float new_time = comp.current_time + delta_time;
			if (new_time > comp.effective_max_time()) { new_time = 0; }
			SetTime(new_time);
		}
	} else if (is_exporting()) {
		if (export_state.frames_rendered < comp.effective_max_frames()) {
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
				SetFrame(comp.current_frame + 1);
			}
			
		}
		if (!export_state.is_ffmpegging && export_state.frames_rendered == comp.effective_max_frames()) {
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
			for (let& element in Comp().elements) {
				if (ElementIsVisibleNow(element) && element.Hovered()) {
					SetSelection(element.handle());
					break;
				}
			}
		}

		if (HotKeys.KeyAtCurrentPosition.IsPressed() && has_selected_elements()) { // NOTE: K (keyframe)
			let& elem = get_primary_selected_element();
			float keyframe_t = std.clamp(comp.current_time - elem.start_time, 0, elem.duration);
			elem.kl_pos().InsertValue(
				keyframe_t,
				ws_mouse_pos
			);
		}

		if (HotKeys.ImportMovie.IsPressed()) {
			OpenModalFn(ImportMovieModal);
		}

		if (HotKeys.QuickAdd.IsPressed()) { // NOTE: A (quick-add)
			OpenModalFn(QuickAddModal);
		}

		if (HotKeys.SaveProject.IsPressed()) {
			OpenModalFn(SaveProjectModal);
		}
		if (HotKeys.OpenProject.IsPressed()) {
			OpenModalFn(OpenProjectModal);
		}

		if (HotKeys.Temp_AddFaceElem.IsPressed()) {
			OpenModalFn(AddFaceElemModal);
		}
	}

	if (!ui_hidden) {
		// LeftPanelUI();
		// CompositionTimelineUI();
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

	loader_result_queue_mutex.lock();
	{
		while (!loader_result_queue.is_empty()) {
			LoaderResult res = loader_result_queue.pop_front();

			switch (res.payload) {
				LoaderResult_Gif it -> {
					
				},
				LoaderResult_Failure it -> {
					warn(it.kind, it.msg);
					// TODO: free it.msg or no...
				},
			}
		}
	}
	loader_result_queue_mutex.unlock();

	hr_once = false;
}

void RenderAfter() {
	// TODO: this shouldn't be in RenderAfter
	rl.SetMouseCursor(cursor_type._to_raylib_cursor_type());
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
	let& comp = Comp();
	from_edit = 
	{
		:images,
		:canvas_width, :canvas_height,
		.STREAM_DURATION = comp.time_per_frame * comp.effective_max_frames(),
		.STREAM_FRAME_RATE = comp.frame_rate
	};
}

// bool ImportVideo(char^ input_file_name_no_path) {
// 	SyncEncodingDecodingEditInfo();
// 	return EncodingDecoding.ImportVideoImpl(input_file_name_no_path, dec_frame_rate, imported_textures);
// }

void ExportVideoThreadMain() {
	ExportVideo(Comp().frame_rate, "out", "edit_video");

	SetMode(.Paused);
	SetFrame(0);
}

void ExportVideo(int framerate, char^ folder_path, char^ output_file_name_no_path) {
	int imgh = canvas.texture.height;
	int imgw = canvas.texture.width;

	SyncEncodingDecodingEditInfo();
	EncodingDecoding.ExportVideoImpl(imgw, imgh, framerate, folder_path, output_file_name_no_path);

	SetMode(.Running);

	CloseModalByFn(ExportingModal); // TODO: close specific modal? (by fn_ptr?)
}

// non-recursive
// void AddImageSequenceFromDir(char^ dir_path, Vec2 pos) {
// 	char^ name = rl.GetFileName(dir_path);
// 	let paths = io.list_dir_files(dir_path, false);
// 	defer paths.delete();
// 	// TODO: sort alphabetically
//
// 	AddImageSequenceFromPaths(name, 0.25, paths, pos);
// }

// NOTE: `name` strdupped
// void AddImageSequenceFromPaths(char^ name, float time_per_frame, char^[] file_paths, Vec2 pos) {
// 	// Handle image file
// 	Vec2 dimens = v2(100, 100); // bad default val TODO:
// 	if (!file_paths.is_empty()) {
// 		Image img = Image.Load(file_paths.front());
// 		defer img.Unload();
// 		dimens = v2(img.width, img.height);
// 	}
//
// 	AddNewSelectedElementAt(Element(ImageSequenceElement.Make(time_per_frame, file_paths), strdup(name), Comp().current_time, new_element_default_duration, NULL, pos, dimens));
// }

void ProcessDroppedFile(char^ file_path_in, bool dropped_via_mouse) {
	char^ file_path = strdup(file_path_in); // TODO: should free? - :check
	bool is_dir = rl.DirectoryExists(file_path);

	Vec2 pos = (dropped_via_mouse && canvas_rect.Contains(ws_mouse_pos)) ? ws_mouse_pos | v2(0, 0);

	if (is_dir) {
		// CURRENTLY WE ASSUME THIS TO BE IMAGE-SEQUENCE
		// AddImageSequenceFromDir(file_path, pos);
		return;
	}

	char^ file_type = rl.GetFileExtension(file_path_in); // static string!! (don't hold)
	// malloced image (the ImageElement is responsible for freeing)
	// ^ TODO: make this ownership clearer!


	if (strcmp(file_type, ".png") == 0 || strcmp(file_type, ".jpg") == 0) {
		// Handle image file
		Image img = Image.Load(file_path);
		defer img.Unload();
		char^ img_name = rl.GetFileNameWithoutExt(file_path);

		AddNewSelectedElementAt(Element(ImageElement.Make(file_path), strdup(img_name), Comp().current_time, new_element_default_duration, NULL, pos, v2(img.width, img.height)));
	} else if (strcmp(file_type, ".gif") == 0) {
		char^ gif_name = rl.GetFileNameWithoutExt(file_path);

		int resource_id = LoaderResult.ProcureID();

		FILE^ fp = io.fopen_opt(file_path, "rb").! else return warn(.MISC, "failed to open gif");
		defer fp#close();

		ulong GIF_HEADER_LEN = 10;
		uchar^ header_buf = malloc(sizeof<uchar> * GIF_HEADER_LEN);
		defer free(header_buf);

		if (fp#read(header_buf, sizeof<uchar>, GIF_HEADER_LEN) != GIF_HEADER_LEN) {
			return warn(.MISC, "failed to read gif header");
		}

		int width = header_buf[7] ~| (header_buf[8] << 8);
		int height = header_buf[9] ~| (header_buf[10] << 8);

		go_with(LoadGif, Box<LoadGifParams>.Make({ .file_path = strdup(file_path), .id = resource_id }) as void^);
		AddNewSelectedElementAt(Element(ImageSequenceElement.Make(0.1, resource_id), strdup(gif_name), Comp().current_time, new_element_default_duration, NULL, pos, v2(width, height)));
	} else if (strcmp(file_type, ".csv") == 0) {
		// // Handle data file
		// Data data = .(file_path);
		// data_list.add(data);
		// elements.get(selected_elem_i).ApplyKeyframeData(data, current_time, (1.0 / frame_rate));
	} else if (strcmp(file_type, ".mp4") == 0) {
		// Handle video file
		AddVideoFromPath(file_path, pos);
	} else {
		println(t"Unsupported file type: {file_type}");
	}
}

void OnFileDropped() {
	FilePathList dropped_file_path_list = FilePathList.Load();
	defer dropped_file_path_list.Unload();

	for (int i in 0..dropped_file_path_list.count) {
		ProcessDroppedFile(dropped_file_path_list.paths[i], true);
	}
}

Rectangle UnCoveredArea() {
	if (ui_hidden) {
		return .(0, 0, window_width, window_height);
	}

	return .(left_panel_width, 0, window_width as float - left_panel_width, window_height as float - (composition_timeline_height));
}

Rectangle canvas_rect = { 0, 0, 0, 0};

enum PanelDragDir {
	Left, Right, Top, Bottom, 
	Expand // only 1 expand per axis!
}

void SidePanel() {
	let& p = Proj();
	let& comp = Comp();
	// TODO: @scope $Panel(...);
	$Panel(left_panel_expander) {
		if (!has_selected_elements()) { return; }

		Element& selected_elem = get_primary_selected_element();

		$clay({
			.layout = {
				.sizing = {
					.width = CLAY_SIZING_GROW(),
					.height = CLAY_SIZING_FIXED(rem(2)),
				},
				.padding = { 8, 8, 2, 2 }
			},
			.backgroundColor = theme.button,
		}) {
			CLAY_TEXT(.(t"Selected: {selected_elem.name}"), CLAY_TEXT_CONFIG({
				.fontSize = rem(1.5),
				.textColor = Colors.White
			}));
		};
		// // vert spacer ---
		// $clay({ .layout = { .sizing = .(0, 16) } }) {};

		float max_elem_time = selected_elem.duration;

		float curr_local_time = std.clamp(comp.current_time - selected_elem.start_time, 0, selected_elem.duration);

		CustomLayerUIParams params = { :max_elem_time, :curr_local_time, .global_time = comp.current_time, .element = selected_elem, :p, :comp };
		selected_elem.UI(params);
	};
}

void AssetManagerUI() {
	$VERT({ .backgroundColor = theme.button, .layout = {.sizing = .Grow()}}) {
		clay_text("Assets", { .fontSize = rem(1), .textColor = Colors.White });
	};
}

void AddExtraEmptyLayerIfNone() {
	let& comp = Comp();
	let& layers = comp.layers;
	if (layers.is_empty() || !layers.back()#element_handles.is_empty()) {
		layers.add(EditLayer.new(^comp));
		comp.vertical_view_range_slider.range.end++;
	}
}

int prev_last_s = 0;
float CompositionTimelineSecondTickerUI_height() -> rem(1);
// returns hovering
bool CompositionTimelineSecondTickerUI(Composition& comp, float layer_info_width, float time_to_width_pixels) {
	bool hovering = false;
	$HORIZ_FIXED(CompositionTimelineSecondTickerUI_height()) {
		$clay({ .layout = { .sizing = .(layer_info_width, 0) } }) {
			// TODO: lil' config/button stuff here?
		};
		Clay_ElementId composition_timeline_ticker_id = .("composition-timeline-ticker");
		float composition_timeline_ticker_right_x = Clay.GetBoundingBox(composition_timeline_ticker_id).br().x;

		$HORIZ_GROW({ .id = composition_timeline_ticker_id }) {
			hovering = Clay.Hovered();
			// draw second ticks
			int last_s = comp.view_range_slider.range.end as int;

			Clay_ElementId last_second_id = .("last-second-timeline-tick");
			for (int s = std.ceil(comp.view_range_slider.range.start); (s) <= last_s; s++) {
				float x = (s as float - comp.view_range_slider.range.start) * time_to_width_pixels;

				Color text_color = theme.panel;
				if (s == last_s) {
					float right_x = Clay.GetBoundingBox(last_second_id).tl().x + 4 + c:MeasureText(t"{last_s}s", rem(0.75));
					if (right_x >= composition_timeline_ticker_right_x) {
						text_color = Colors.Transparent;
					}
					if (last_s != prev_last_s) {
						prev_last_s = last_s;
						text_color = Colors.Transparent;
					}
				}

				$VERT({
					.id = (s == last_s) ? last_second_id | {},
					.border = {
						.color = theme.panel,
						.width = { .left = 1 },
					},
					.layout = {
						.sizing = .(1, rem(1)),
						.padding = { .left = 4 },
					},
					.floating = {
						.offset = { :x },
						.attachTo = CLAY_ATTACH_TO_PARENT,
						.pointerCaptureMode = CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH,
					},
				}) {
					clay_y_grow_spacer();

					clay_text(t"{s}s", {
						.fontSize = rem(0.75),
						.textColor = text_color,
					});
				};
			}
		};
		$clay({ .layout = { .sizing = .(rem(1), rem(1)) } });
	};
	return hovering;
}

void CloseProject(Project& project) {
	for (int i in 0..projects.size) {
		if (^project == projects[i]) {
			projects.remove_at(i);
			selected_project_index = 0;
			warn(.TODO_BETTER_PROJECT_CLOSING);
			return;
		}
	}

	warn(.MISC, "did not find project to close!?");
}

void ProjectBarUI() {
	Project^ maybe_proj = has_proj() ? ^Proj() | NULL;

	$HORIZ_FIXED(rem(1.5), { .backgroundColor = theme.button, .border = .Bottom(1, theme.panel), .layout = { .childAlignment = .CenterY() } }) {
		Project^ do_close_project = NULL;
		for (int project_i in 0..projects.size) {
			Project^ project = projects[project_i];
			Clay_ElementId project_id = .(t"{project}");
			$clay({
				.id = project_id,
				.backgroundColor = (Clay.VisuallyHovered(project_id))
					? theme.panel_highlight
					| (maybe_proj == project)
						? theme.panel
						| theme.panel_disabled,
				.layout = {
					.padding = .XY(4, 2),
					.sizing = {
						.width = CLAY_SIZING_FIT(100),
					},
					.childAlignment = .CenterY()
				}
			}) {
				if (Clay.Pressed()) {
					selected_project_index = project_i;
				}

				clay_text(project#name, { .fontSize = rem(1), .textColor = Colors.White });

				clay_x_grow_spacer();

				if (ClayIconButton(Textures.close_icon)) {
					do_close_project = project;
				}
			};

			clay_x_spacer(4);
		}

		// don't concurrently modify >:0
		if (do_close_project != NULL) {
			CloseProject(*do_close_project);
		}

		$clay({
			.id = .("new-project-btn"),
			.backgroundColor = (Clay.VisuallyHovered(.("new-project-btn")))
				? theme.panel_highlight
				| theme.panel,
			.layout = {
				.padding = .XY(4, 2),
				// .sizing = { .width = CLAY_SIZING_FIT(rem(1) + 4) }
			}
		}) {
			if (Clay.Pressed()) {
				AddNewSelectedProject();
			}

			clay_text("+", { .fontSize = rem(1), .textColor = Colors.White });
		};
	};
}

// Custom logging function
bool rl_info_logging_disabled = false;
c:`typedef const char* const_char_star;`;

@[gcc_diagnostic_ignored(.unix = "-Wformat-security", .win32 = "-Wformat-security")]
void CustomLog(int msgType, c:const_char_star text, c:va_list args) {
	if (msgType == rl.LogLevel.INFO && rl_info_logging_disabled) { return; }

	ColorPrint colourer;

    c:`
    char timeStr[64] = { 0 };
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);

    strftime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", tm_info);
	`;
	char^ sort_name = match (msgType) {
		rl.LogLevel.INFO -> "INFO",
		rl.LogLevel.ERROR -> "ERROR",
		rl.LogLevel.WARNING -> "WARN",
		rl.LogLevel.DEBUG -> "DEBUG",
		else -> "OTHER",
	};
	printf("%s ",
		(msgType == rl.LogLevel.INFO)
		? colourer.yellow(t"[{sort_name}] ({c:timeStr as char^}): ")
		| colourer.red(t"[{sort_name}] ({c:timeStr as char^}): ")
	);

    c:vprintf(text, args);
    printf("\n");
}

// called each frame externally by edit_app
bool DoHotReload() {
	bool should_hr = HotKeys.HotReloadProgram.IsPressed();
	if (io.file_exists("./__crust_do_hr")) {
		should_hr = true;
		io.rm("./__crust_do_hr");
	}

	if (should_hr) {
		PreHotReload();
		return true;
	}
	return false;
}

void PreHotReload() {
	reinitializeClay = true;
	if (CloseAllModals() > 0) { warn(.MISC, "open modals not allowed over hr [stored fn-ptrs]"); }
}

bool hr_once = false; // true for the first frame after hr! NOTE: useful for triggering once off actions where-ever in code :)

// this code is what was loaded
// NOTE: we must reset any callbacks used!
void PostHotReload() {
	tfree();
	rl.SetTraceLogCallback(CustomLog as c:TraceLogCallback);
	hr_once = true;
}

void ExternalHotReloadWarn(char^ msg) {
	warn(ProgramWarningKind.EXTERNAL_HOT_RELOADING, msg);
}

void AddNewSelectedProject() {
	// project-related
	projects.add(Project.new());
	selected_project_index = projects.size - 1;

	// composition-related
	Proj().comps.add(Composition.new(^Proj(), 300, 200));
	Proj().selected_comp_index = 0;

	// element-related
	AddNewSelectedElementAt(Element(RectElement.Make(), "Rect", 0, 2, NULL, v2(0, 0), v2(200, 150)) with { .color = Colors.Blue });
}

char^ TODO_tcc_test() {
	TCCState^ tcc = .new();
	defer tcc#delete();

	char^ error_msg = NULL;

	tcc#set_output_type(TCC_OUTPUT_MEMORY);
	tcc#compile_string("#include <tcclib.h>\n void my_fn(void) { printf(\"yo!!!!\\n\"); }").! else return error_msg;

	return "yippee!";
}

CommandLineArgs cmd_args;
void Init(int argc, char^^ argv) {
	{
		int pid = getpid();
		println(t"---- edit starting ({pid=}) ----");
	}

	//  mutexes ----------------------------------------
	loader_result_queue_mutex.init();
	loader_result_id_counter_mutex.init();
	// /mutexes ----------------------------------------

	cmd_args = .(argc, argv);

	Env.DebugPrint(); // notes environment settings applied

	{ // manage edit_data (we know that edit_data/ must exist!)
		io.rmrf_if_existent(EditPaths.temp_projects);
		io.mkdir(EditPaths.temp_projects);

		io.rmrf_if_existent(EditPaths.temp_crust_in);
		io.mkdir(EditPaths.temp_crust_in);

		io.rmrf_if_existent(EditPaths.temp_c_out);
		io.mkdir(EditPaths.temp_c_out);
	}

	// RAYLIB INITIALIZED HERE (window.init), no loading assets (textures, images, sounds) before this point!!!
	rl_info_logging_disabled = true;
	rl.SetTraceLogLevel(rl.LogLevel.ALL); // we do filtering ourself!
	rl.SetTraceLogCallback(CustomLog as c:TraceLogCallback);
	let window_name = f"CodeComposite{(cmd_args.save_to_project != NULL) ? t" - {cmd_args.save_to_project}" | ""}"; // TODO: free?
	EditClayApp.Init();

	// NOTE: (rae-TODO): FIX weirdness when GetScreenHeight >= actual-screen-height
	// println(t"aa: {rl.GetScreenWidth()} {rl.GetRenderWidth()}");
	// println(t"aa: {rl.GetScreenHeight()} {rl.GetRenderHeight()}");
	// println(t"h: {rl.GetMonitorHeight(0)=} {rl.GetMonitorWidth(0)=}");
	// if ()

	code_man.PreLoadTakeCareOfPreppedReload();
	code_man.Load();

	//  ASSETS LOADING -------------------------
	KeyframeAssets.LoadAssets();
	TexturesLib.LoadAssets();
	ColorPicker.LoadAssets();
	// /ASSETS LOADING -------------------------

	// Audio init and close
	c:InitAudioDevice();
	fxMP3 = c:LoadSound("assets/history.mp3");

	c:SetMasterVolume(master_volume);
	c:PlaySound(fxMP3);

	SetMute(true); // NOTE: CURRENTLY MUTING FOR DEMO

	canvas_temp = RenderTexture(1200, 900);
	canvas = RenderTexture(1200, 900);

	AddNewSelectedProject();

	if (cmd_args.open_project != NULL) {
		println(t"opening: saves/{cmd_args.open_project}");
		ProjectSave.Load(Path("saves")/cmd_args.open_project);
	}

	rl_info_logging_disabled = false;
}

void Deinit() {
	if (cmd_args.save_to_project != NULL) {
		Path p = Path("saves")/cmd_args.save_to_project;
		string project_name = .(cmd_args.save_to_project);

		if (io.dir_exists(p)) {
			Path new_p = Path("saves")/t"{project_name.str}_old_{rl.GetRandomValue(0, 1000)}";
			defer free(new_p.str);

			if (!io.mv(p, new_p)) {
				println(t"moving old save from '{p.str}' to '{new_p.str}' failed... overwriting :(");
			}
		}
		ProjectSave.Create(p, project_name);
	}
	c:UnloadSound(fxMP3);
	c:CloseAudioDevice();
	ImageCache.Unload(); // cleanup loaded images (we should also do this when assets are no longer in use? -- TODO: LCS eviction type thing maybe)
	code_man.Unload();
	GlobalSettings.SaveUpdates();
	EditClayApp.Deinit();
}

@no_hr
bool ticked = false;

void Tick() {
	// rl.BeginDrawing();
	// rl.ClearBackground(Colors.Red);
	// if (!ticked) {
	// 	ticked = true;
	// 	println("./test.txt");
	// 	let text = rl.LoadFileText("./test.txt");
	// 	defer rl.UnloadFileText(text);
	// 	println(text);
	// }
	// rl.EndDrawing();
	EditClayApp.Tick(GameTick, RenderAfter, HotKeys.ClayDebugToggle.IsPressed());
}

int main(int argc, char^^ argv) {
	panic("Wrong main entry point... use wrapper.cr to wrap for now pls :)");
	return 0;
}

// int ReadEditVersion() {
// 	let lines = io.lines_opt("version.txt").! else {
// 		println("[DEBUG-WARNING]: missing version.txt (using version=1)");
// 		return 1;
// 	};
// 	defer lines.delete();
//
// 	return c:atoi(lines.at(0));
// }


// actions & undo/redo-capability --------------------------------------
// ----------------------------------------------------------------------
struct CreateNewElementAction : ActionImpl {
	Element element;
	EditLayer^ layer; // TODO: make serializable!!!

	ActionInfo Info() -> {
		.name = "Create New Element"
	};
	Action into() -> Action(Box<Self>.Make(this));

	void Apply(using ActionArgs& args) {
		let& elem = Comp().elements.Add(element);
		let handle = elem.handle();
		layer#AddElement(elem.handle());
		elem.layer = layer;
		elem.LinkDefaultLayers();
	}
	void delete(ActionDeleteArgs& args) {}
}

struct DeleteElementAction : ActionImpl {
	ElementHandle handle;

	ActionInfo Info() -> {
		.name = "Delete Element"
	};
	Action into() -> Action(Box<Self>.Make(this));

	void Apply(using ActionArgs& args) {
		comp._DeleteElement(handle);
	}
	void delete(ActionDeleteArgs& args) {}
}

struct SetSelectionAction : ActionImpl {
	ElementHandle[] selection; // list memory held by action!!!

	ActionInfo Info() -> {
		.name = "Set Selection"
	};
	Action into() -> Action(Box<Self>.Make(this));

	void Apply(using ActionArgs& args) {
		comp.selection.clear();
		for (let handle in selection) {
			comp.selection.add(handle);
		}
	}
	void delete(ActionDeleteArgs& args) {
		selection.delete();
	}
}
