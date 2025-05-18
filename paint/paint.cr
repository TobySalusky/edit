import rl;

import layer_list;
import theming;
import timer;
import thread;
import floodfill;
import settings;
import undo;

import std;
import list;

// int window_width = 1024;
// int window_height = 720;
int window_width = 1200;
int window_height = 900;

int canvas_width = 1200;
int canvas_height = 900;

float pi = 3.14159;
float radians(float deg) -> (deg * (pi / 180.0));
float degrees(float rad) -> (rad * (180.0 / pi));

RenderTexture canvas;
RenderTexture rt;
RenderTexture swap;
RenderTexture diff;
RenderTexture layer_temp; // for preview effects in layer space (eg: inserted into layer-stack drawing order -- above whatever is on current layer)

RenderTexture pixel; // should just be texture - do not render to - use for shader effects (since they need FragTexCoords to change correctly, which do not for rects)

Image img;
bool img_ready = false;

float delta_time;

Vec2 last_mouse_pos; // TODO: don't allow init-ing from below vars?
Vec2 mouse_pos;

Vec2 ws_mouse_pos; // worldspace
Vec2 ws_last_mouse_pos;

List<Layer> layers;

// functional shaders
Shader erase_shader;
Shader clip_shader;

// graphical/UI shaders
Shader color_picker_block_shader;
Shader color_picker_ring_shader;

int ToolKind_BRUSH = 0;
int ToolKind_ERASER = 1;
int ToolKind_CLIPPING_BRUSH = 2;
int ToolKind_FILL_BUCKET = 3;
int ToolKind_EYE_DROPPER = 4;
int ToolKind_SELECT_RECT = 5;
int ToolKind_SELECT_LASSO = 6;

int USE_COND_L_PRESS = 0;
int USE_COND_L_DOWN = 1;

interface Tool {
	char^ CursorAppearance();
	void SetRad(float new_rad); // should have empty default...
	float VisibleRad(); // -1 if not-applicable
	int UseCond(); // L-press / L-down
	bool AddUndoOnStartUse();
	void Use();
	void Preview();
}

struct Tool_Pen : Tool {
	float rad;

	float VisibleRad() -> rad;
	void SetRad(float new_rad) { rad = new_rad; }

	char^ CursorAppearance() -> "pencil";
	int UseCond() -> USE_COND_L_DOWN;
	bool AddUndoOnStartUse() -> true;

	void Use() {
		rt.Begin();
			d.Texture(diff, Vec2_zero);
		rt.End();
	}

	void Preview() {}
}

struct Tool_Eraser : Tool {
	float rad;

	float VisibleRad() -> rad;
	void SetRad(float new_rad) { rad = new_rad; } 

	char^ CursorAppearance() -> "eraser";
	int UseCond() -> USE_COND_L_DOWN;
	bool AddUndoOnStartUse() -> true;

	void Use() {
		IntoSwap();

		rt.Begin();
		erase_shader.Begin();
		erase_shader.SetRenderTexture("mask", diff);
			d.Texture(swap, Vec2_zero);
			d.Texture(diff, Vec2_zero);
		erase_shader.End();
		rt.End();
	}

	void Preview() {}
}

// struct Tool_ClippingBrush : Tool {
// 	float rad;
//
// 	float VisibleRad() -> rad;
// 	void SetRad(float new_rad) { rad = new_rad; } 
//
// 	char^ CursorAppearance() -> "eraser";
// 	int UseCond() -> USE_COND_L_DOWN;
// 	bool AddUndoOnStartUse() -> true;
//
// 	void Use() {
// 		rt.Begin();
// 		clip_shader.Begin();
// 		clip_shader.SetRenderTexture("clip", rt);
// 			d.Texture(diff, Vec2_zero);
// 		clip_shader.End();
// 		rt.End();
// 	}
// }

// T generic_fn<T>() {
// 	T^ a = malloc(sizeof<T>);
// 	return a;
// }

// T^ box<T>(T obj) {
// 	T^ obj_ptr = malloc(sizeof<T>);
// 	*obj_ptr = obj;
//
// 	return obj_ptr;
// }

struct Tool_Bucket : Tool {
	float VisibleRad() -> -1;
	void SetRad(float new_rad) {} 

	char^ CursorAppearance() -> "bucket";
	int UseCond() -> USE_COND_L_PRESS;
	bool AddUndoOnStartUse() -> true;

	void Use() {
		AddLayerContentUndo();
		Image guide = c:LoadImageFromTexture(canvas.texture);
		defer guide.delete();

		Image fill_img = FloodFill(guide, { .x = c:float_to_int(ws_mouse_pos.x), .y = c:float_to_int(ws_mouse_pos.y) }, brush_color);
		defer fill_img.delete();

		Texture fill_texture = c:LoadTextureFromImage(fill_img);
		defer fill_texture.delete();

		rt.Begin();
			c:DrawTexture(fill_texture, 0, 0, Colors.White);
		rt.End();
	}

	void Preview() {}
}

struct Tool_EyeDropper : Tool {
	float VisibleRad() -> -1;
	void SetRad(float new_rad) {} 

	char^ CursorAppearance() -> "eyedropper";
	int UseCond() -> USE_COND_L_PRESS;
	bool AddUndoOnStartUse() -> false;

	void Use() {
		Image sample_image = c:LoadImageFromTexture(canvas.texture);
		defer sample_image.delete();

		Vec2 clamped = ws_mouse_pos.clamp(Vec2_zero, v2(canvas_width - 1, canvas_height - 1));
		brush_color = sample_image.getXY(c:float_to_int(clamped.x), canvas_height - 1 - c:float_to_int(clamped.y));
		// TODO: set color on color wheel!
	}

	void Preview() {}
}

struct Tool_Line : Tool {
	float VisibleRad() -> -1;
	void SetRad(float new_rad) {} 

	char^ CursorAppearance() -> "eyedropper"; // TODO: !
	int UseCond() -> USE_COND_L_DOWN;
	bool AddUndoOnStartUse() -> true;

	void Use() { // TODO: apply-on-up
		
	}

	void Preview() {
		
	}
}

struct Tool_SelectRect : Tool {
	float VisibleRad() -> -1;
	void SetRad(float new_rad) {} 

	char^ CursorAppearance() -> "select_rect"; // TODO: !
	int UseCond() -> USE_COND_L_DOWN;
	bool AddUndoOnStartUse() -> true;

	void Use() {
		
	}

	void Preview() {
		
	}
}

struct Tool_SelectLasso : Tool {
	float VisibleRad() -> -1;
	void SetRad(float new_rad) {} 

	char^ CursorAppearance() -> "select_lasso"; // TODO: !
	int UseCond() -> USE_COND_L_DOWN;
	bool AddUndoOnStartUse() -> true;

	void Use() {
		
	}

	void Preview() {
		
	}
}

struct Tool_Move : Tool {
	float VisibleRad() -> -1;
	void SetRad(float new_rad) {} 

	char^ CursorAppearance() -> "eyedropper"; // TODO: !
	int UseCond() -> USE_COND_L_DOWN;
	bool AddUndoOnStartUse() -> true;

	void Use() {
		
	}

	void Preview() {
		
	}
}

struct Tool_QuickText : Tool {
	float VisibleRad() -> -1;
	void SetRad(float new_rad) {} 

	char^ CursorAppearance() -> "eyedropper"; // TODO: !
	int UseCond() -> USE_COND_L_DOWN; // TODO: use-on-confirmation
	bool AddUndoOnStartUse() -> true;

	void Use() { // TODO: apply-on-up
		
	}

	void Preview() {
		
	}
}

// tools ---
Tool_Pen pen = {
	.rad = 2
};
Tool_Eraser eraser = {
	.rad = 10
};
Tool_Bucket bucket = {};
Tool_EyeDropper eye_dropper = {};
// ---------
Tool^ tool = ^pen;

Color brush_color = c:BLACK;

// undos -----------
List<Undo^> undos = make_undo_list();

// specific opts ---
char^ export_on_exit_to = NULL;
bool export_movie_on_exit = false;
// ---------------------------------
Vec2 view_translate = Vec2_zero;
float view_scale = 1;

Vec2 to_worldspace(Vec2 screenspace) -> (screenspace - view_translate).divide(view_scale);

Vec2 to_screenspace(Vec2 worldspace) -> worldspace.scale(view_scale) + view_translate;

void CenterCanvasToRect(Rectangle rect) {
	float horiz_scale = rect.width / canvas_width;
	float vert_scale = rect.height / canvas_height;
	view_scale = (horiz_scale > vert_scale) ? vert_scale | horiz_scale;
	view_translate = RectCenter(rect.center(), v2(canvas_width, canvas_height).scale(view_scale)).tl();
}

// TODO: un-hardcode
void CenterCanvas() -> CenterCanvasToRect({ .x = left_panel_width + 10, .y = 10, .width = window_width - left_panel_width - 20, .height = window_height - 20 });
// ---------------------------------

StrMap<Texture> cursor_textures;

Path paint_path = make_path("/Users/toby/Documents/GitHub/crust/paint");

void LoadCursorTextures() {
	cursor_textures = StrMapMaker<Texture>{}.make();
	let add = (char^ name):void -> {
		Image tmp = c:LoadImage((paint_path/t"cursors/{name}.png").str);
		c:ImageFlipVertical(^tmp);
		cursor_textures.put(name, c:LoadTextureFromImage(tmp));

		tmp.delete();
	};

	add("bucket"); add("crosshair"); add("eraser"); add("eyedropper"); add("pencil"); add("point"); add("resize_horiz"); add("resize_vert"); add("select_lasso"); add("select_rect");
}

char^ DetermineCursorAppearance() {
	if (click_started_on_ui || MouseOverUI()) { return "point"; }

	// if (brush#kind == ToolKind_BRUSH) { return "pencil"; }
	// if (brush#kind == ToolKind_CLIPPING_BRUSH) { return "pencil"; }
	// if (brush#kind == ToolKind_ERASER) { return "eraser"; }
	// if (brush#kind == ToolKind_FILL_BUCKET) { return "bucket"; }
	// if (brush#kind == ToolKind_EYE_DROPPER) { return "eyedropper"; }
	// if (brush#kind == ToolKind_SELECT_RECT) { return "select_rect"; }
	// if (brush#kind == ToolKind_SELECT_LASSO) { return "select_lasso"; }

	return tool#CursorAppearance();
}

void opts_setup(ProgramOpts opts) {
	char^ dimens_str = opts.getDashedWithAlias("dimensions", "d");
	export_on_exit_to = opts.getDashed("export-on-exit-to");
	export_movie_on_exit = opts.hasDashed("export-movie"); // TODO: path location to export to (in addition?)

	if (dimens_str != NULL) {
		if (str_contains(dimens_str, "x")) {
			Strings dimens = trim_split(dimens_str, "x");
			canvas_width = c:atoi(dimens.at(0));
			canvas_height = c:atoi(dimens.at(1));
		} else {
			int dimen_both = c:atoi(dimens_str);
			canvas_width = dimen_both;
			canvas_height = dimen_both;
		}
	}
}

Shader LoadShaderByName(char^ name) -> make_shader(paint_path/t"shaders/{name}.frag"); // TODO: make local to hard-coded / known path!

void AutosaveImg() {
	ExportCanvasToImage();
	img.ExportTo(global_meta_data.get_autosave_img_path().str);
}

int main(int argc, char^^ argv) {
	// opts
	opts_setup(make_opts(argc, argv));
	// ---

	// storage/meta/settings setup
	setup_global_paint_storage();
	global_meta_data.load();
	global_settings.load();

	global_meta_data.initial_update();

	defer global_meta_data.store();
	defer global_settings.store(); // TODO: maybe store these on-change? (in-case of panic/crash?)
	// ---

	if (export_movie_on_exit) { go(RecordScreen); }

	rl.SetTraceLogLevel(c:LOG_WARNING ~| c:LOG_ERROR);  // Log flags?
	rl.SetConfigFlags(c:FLAG_WINDOW_RESIZABLE); // c:FLAG_WINDOW_TRANSPARENT <-- cool
	// rl.SetConfigFlags(c:FLAG_WINDOW_RESIZABLE ~| c:FLAG_WINDOW_UNDECORATED); // c:FLAG_WINDOW_TRANSPARENT <-- cool

	window.Init(window_width, window_height, "tpp raylib window");
	defer window.Close();

	rl.SetWindowMinSize(100, 100);

	int m = rl.GetCurrentMonitor();
	int w = rl.GetMonitorWidth(m);
	int h = rl.GetMonitorHeight(m);

	window_width = w;
	window_height = h;

	// window.SetPosition(0, 0);
	// window.SetSize(window_width, window_height);

	// ---
	rl.HideCursor();
	LoadCursorTextures();
	// ---

	erase_shader = LoadShaderByName("erase_mask");
	defer erase_shader.delete();

	clip_shader = LoadShaderByName("clipping");
	defer clip_shader.delete();

	color_picker_block_shader = LoadShaderByName("color_picker");
	defer color_picker_block_shader.delete();

	color_picker_ring_shader = LoadShaderByName("hue_ring");
	defer color_picker_ring_shader.delete();

	layers = List<Layer>();
	defer {
		for (Layer& layer in layers) { layer.delete(); }
		layers.delete();
	}

	layers.add(make_layer(canvas_width, canvas_height));
	layers.add(make_layer(canvas_width, canvas_height));
	layers.add(make_layer(canvas_width, canvas_height)); // each is a frame-buffer

	SetLayer(0);

	canvas = make_render_texture(canvas_width, canvas_height);
	// rt uses current layer rt
	swap = make_render_texture(canvas_width, canvas_height);
	diff = make_render_texture(canvas_width, canvas_height);
	layer_temp = make_render_texture(canvas_width, canvas_height);
	pixel = make_render_texture(1, 1);

	last_mouse_pos = mouse.GetPos();
	ws_last_mouse_pos = to_worldspace(last_mouse_pos);

	// ---
	CenterCanvas();
	// ---

    c:SetTargetFPS(300);
	while (!window.ShouldClose()) {
		delta_time = c:GetFrameTime();

		mouse_pos = mouse.GetPos();
		ws_mouse_pos = to_worldspace(mouse_pos);
		d.Begin();
		GameTick();
		d.End();
		last_mouse_pos = mouse_pos;
		ws_last_mouse_pos = ws_mouse_pos;

		if (!img_ready) {
			ExportCanvasToImage();
			img_ready = true;
		}

		if (c:IsWindowResized()) {
			window_width  = c:GetScreenWidth();
			window_height = c:GetScreenHeight();
		}

		tfree(); // ------ END OF TEMP FRAME MARKER -------
    }

	if (export_movie_on_exit) {
		ExportVideo(30, "out/frames", "out/capture");
	}

	if (export_on_exit_to != NULL) {
		ExportCanvasToImage();
		img.ExportTo(export_on_exit_to);
	}

	AutosaveImg();

    return 0;
}

void DrawControls() {
	d.RectBetween(v2(20, 20), v2(window_width - 20, window_height - 20), c:GRAY);

	int font_size = 32;
	Color font_color = c:BLACK;

	int x = 30;
	int y = 30;
	int step = 40;

	d.Text("draw: S", x, y, font_size, font_color); y = y + step;
	d.Text("erase: D", x, y, font_size, font_color); y = y + step;
	d.Text("fill: F", x, y, font_size, font_color); y = y + step;
	d.Text("NUKE: X", x, y, font_size, font_color); y = y + step;

	y = y + step;
	d.Text("TOGGLE CONTROLS: SPACE", x, y, font_size, font_color); y = y + step;
}

bool look_at_controls = false;

// util
bool ClickedRect(Vec2 tl, Vec2 dimens) {
	Vec2 br = tl + dimens;

	return mouse.LeftClickPressed() && mouse_pos.Between(tl, br);
}

bool MouseOverUI() {
	return mouse_pos.InV(v2(0, 0), v2(left_panel_width, window_height));
}

void DrawLayerWidget(Layer layer, int layer_i, int x, int y){
	int width = 160 - 20;
	int height = 60;

	d.Rect(v2(x, y), v2(width, height), c:WHITE);
	d.TextureAtSize(layer.rt, x, y, width, height);
	// TODO: indicate selected

	if (ClickedRect(v2(x, y), v2(width, height))) {
		SetLayer(layer_i);
	}
}

struct ColorPicker {
	bool holding_ring;
	bool holding_block;
	float h; // 0-1 - TODO: should prob be 0-360
	float s; // 0-1
	float v; // 0-1

	Color color() -> c:ColorFromHSV(h * 360, s, v);

	void Draw(Vec2 tl, float diameter, float info_room) {
		float radius = diameter / 2;
		Vec2 center = tl + Vec2{ .x = radius, .y = radius };

		float thickness = 15; // TODO: adjust for best looks

		let PtAt = (Vec2 p):void -> {
			d.Circle(p, 4, c:WHITE);
			d.Circle(p, 3, c:BLACK);
		};

		float block_cross_length = diameter - (thickness * 2); // TODO: fix order of ops/type precedence -> 2*thickness = float :<
		float block_size = block_cross_length / (c:sqrtf(2.0));

		float block_start = (diameter - block_size) / 2;

		color_picker_ring_shader.SetFloat("size", diameter); // OPTIMIZE: inefficient!
		color_picker_ring_shader.SetFloat("ring_width", thickness);

		color_picker_block_shader.SetFloat("hue", h); // cyan

		color_picker_ring_shader.Begin();
			d.TextureAtSize(pixel, tl.x, tl.y, diameter, diameter);
		color_picker_ring_shader.End();

		color_picker_block_shader.Begin();
			Vec2 block_dimen = v2(block_size, block_size);
			Vec2 block_tl = tl + v2(block_start, block_start);
			d.TextureAtSizeV(pixel, block_tl, block_dimen);
		color_picker_block_shader.End();

		// Interaction ----------------------------
		bool mouse_in_block = mouse_pos.InV(block_tl, block_dimen);
		bool mouse_in_ring = mouse_pos.InCircle(center, radius) && !mouse_pos.InCircle(center, radius - thickness);

		if (mouse.LeftClickPressed()) {
			if (mouse_in_ring) { holding_ring = true; }
			else if (mouse_in_block) { holding_block = true; }
		}

		if (mouse.LeftClickReleased()) {
			holding_ring = false;
			holding_block = false;
		}

		if (holding_ring) {
			float angle = ((mouse_pos - center) * Vec2{ .x = 1, .y = -1 }).angle0();
			h = degrees(angle) / 360.0;
		}

		if (holding_block) {
			Vec2 uv = (mouse_pos - (tl + Vec2_one.scale(block_start))).divide(block_size).clamp(Vec2_zero, Vec2_one);

			s = uv.x;
			v = 1.0 - uv.y;
		}

		// interacted!
		if (holding_ring || holding_block) {
			brush_color = this.color();
		}
		// ----------------------------------------
		// selection points ---

		PtAt(tl + Vec2_one.scale(block_start) + Vec2{ .x = s, .y = 1.0 - v }.scale(block_size));
		PtAt(center + unit_vec(radians(h * 360.0)).scale(radius - thickness / 2));

		// color swatch(es) ---
		d.Rect(tl + Vec2_up.scale(diameter + 5), Vec2{ .x = diameter, .y = info_room - 5 }, this.color());
	}
}
ColorPicker color_picker = {
	.holding_block = false,
	.holding_ring = false,
	.h = 0,
	.s = 1,
	.v = 0,
};

int left_panel_width = 160;
void LeftPanelUI() {
	d.Rect(v2(0, 0), v2(left_panel_width, window_height), theme.panel);
	d.Rect(v2(left_panel_width, 0), v2(1, window_height), theme.panel_border);

	for (int i = 0; i != layers.size; i++;) {
		DrawLayerWidget(layers.get(i), i, 10, window_height - 10 - 60 - ((60 + 5) * i));
	}

	color_picker.Draw({ .x = 10, .y = 10 }, left_panel_width - 20, 20);
}

int selected_layer_i = 0;
Layer& selected_layer() -> layers.get(selected_layer_i);

void SetLayer(int i) {
	selected_layer_i = i;
	rt = selected_layer().rt;
}

void AddLayerContentUndo() {
	let& layer = selected_layer();
	undos.add(make_ContentUndo(layer.id, layer.rt.texture.Duplicate()));
}

void UseUndo() {
	if (undos.size == 0) { return; }
	undos.back()#Apply({ .layers = layers });
	undos.pop_back();
}

void IntoSwap() {
	swap.Begin();
		d.ClearBackground(transparent);
		d.Texture(rt, v2(0, 0));
	swap.End();

	rt.Begin();
		d.ClearBackground(transparent);
	rt.End();
}

bool click_started_on_ui = false;

void MouseScroll(float amount) {
	if (true) {
		MouseScrollZoom(amount);
	} else {
		// TODO:
		MouseScrollBrushSize(amount);
	}
}

void MouseScrollZoom(float scroll_amount) {
	float scale_factor = 0.025;
	float view_scale_min = 0.005;

	float scale_diff = scroll_amount * scale_factor;
	if (view_scale + scale_diff <= view_scale_min) { scale_diff = view_scale_min - view_scale; }

	float pre_scale = view_scale;
	Vec2 pre_diff = mouse_pos - view_translate; // / view_scale

	view_scale = view_scale + scale_diff;

	float ratio = view_scale / pre_scale;
	view_translate = mouse_pos.scale(1.0 - ratio) + view_translate.scale(ratio);

	// make pre_worldspace == post_worldspace, to center mouse at change!
}

void MouseScrollBrushSize(float scroll_amount) {
	// TODO: 
}

bool init = false;
void GameTick() {
	d.ClearBackground(theme.bg);

	if (key.IsPressed(KEY.SPACE)) {
		look_at_controls = !look_at_controls;
	}
	if (look_at_controls) {
		DrawControls();
		return;
	}

	// if (mouse.LeftClickDown()) {
	// 	Vec2 mouse_delta = rl.GetMouseDelta();
	// 	rl.GetWindowPosition();
	// 	Vec2 v = rl.GetWindowPosition() + mouse_delta;
	//
	// 	int x = c:float_to_int(v.x);
	// 	int y = c:float_to_int(v.y);
	//
	// 	rl.SetWindowPosition(x, y);
	// }

	//  trash hotkeys ==============
	if (key.IsPressed(KEY.O)) {
		if (rl.IsWindowState(c:FLAG_WINDOW_UNDECORATED)) {
			rl.ClearWindowState(c:FLAG_WINDOW_UNDECORATED); 
		} else {
			rl.SetWindowState(c:FLAG_WINDOW_UNDECORATED); 
		}
		println(t"{rl.GetScreenWidth()=} {rl.GetScreenHeight()=}");
	}
	if (key.IsPressed(KEY.I)) {
		rl.ToggleBorderlessWindowed(); 
		window_width = rl.GetScreenWidth();
		window_height = rl.GetScreenHeight();
		println(t"{rl.GetScreenWidth()=} {rl.GetScreenHeight()=}");
	}
	// /trash hotkeys ==============

	// export movie
	if (key.IsPressed(KEY.M)) { // NOTE: M for all keyboards
		img = c:LoadImageFromTexture(rt.texture);
	}

	// pen tool
	if (key.IsPressed(KEY.S)) { // NOTE: S is O for me
		tool = ^pen;
	}
	// eraser tool
	if (key.IsPressed(KEY.D)) { // NOTE: D is E for me
		tool = ^eraser;
	}
	// fill bucket tool
	if (key.IsPressed(KEY.F)) { // NOTE: F is U for me
		tool = ^bucket;
	}
	// eye dropper tool
	if (key.IsPressed(KEY.E)) { // NOTE: E is . for me
		tool = ^eye_dropper;
	}
	// // clipping pen tool
	// if (key.IsPressed(KEY.I)) { // NOTE: C for me
	// 	tool = ^clipping_pen;
	// }
	// nuke!
	if (key.IsPressed(KEY.B)) { // NOTE: X for me
		AddLayerContentUndo();
		rt.Begin();
			d.ClearBackground(transparent);
		rt.End();
	}
	// re-center canvas
	if (key.IsPressed(KEY.Y)) { // NOTE: F for me
		CenterCanvas();
	}
	// undo
	if (key.IsPressed(KEY.Z)) { // NOTE: ' for me
		UseUndo();
	}
	// add layer
	if (key.IsPressed(KEY.L)) { // NOTE: N for me
		layers.add(make_layer(canvas_width, canvas_height));
	}

	// if (key.IsPressed(KEY.UP)) {
	// 	SetLayer((selected_layer_i >= layers.size - 1) ? 0 | selected_layer_i + 1);
	// }
	//
	// if (key.IsPressed(KEY.DOWN)) {
	// 	SetLayer((selected_layer_i <= 0) ? layers.size - 1 | selected_layer_i - 1);
	// }

	if (key.IsDown(KEY.UP)) {
		view_scale = view_scale + delta_time * 1;
	}

	if (key.IsDown(KEY.DOWN)) {
		view_scale = view_scale - delta_time * 1;
	}

	if (key.IsDown(KEY.LEFT)) {
		view_translate.x = view_translate.x + delta_time * 300;
	}

	if (key.IsDown(KEY.RIGHT)) {
		view_translate.x = view_translate.x - delta_time * 300;
	}

	// changing layer
	if (key.IsPressed(KEY.NUM_1)) { SetLayer(0); }
	if (key.IsPressed(KEY.NUM_2)) { SetLayer(1); }
	if (key.IsPressed(KEY.NUM_3)) { SetLayer(2); }

	float mouse_scroll = c:GetMouseWheelMoveV().y;

	if (mouse_scroll != 0) {
		MouseScroll(mouse_scroll);
	}

	// mouse wheel
	if (tool#VisibleRad() < 0) {
		// no rad
	} else {
		// float new_rad = tool#VisibleRad() + c:GetMouseWheelMove() * 2;
		// if (new_rad <= 0) { new_rad = 1; }
		//
		// tool#SetRad(new_rad);
	}

	if (mouse.LeftClickPressed()) {
		click_started_on_ui = MouseOverUI();
	} else if (mouse.LeftClickReleased()) {
		click_started_on_ui = false;
	}

	if (mouse.LeftClickDown() && !click_started_on_ui) {
		// TODO: only do for tools that use this - should be part of Tool code imo
		if (tool#VisibleRad() >= 0) {
			float rad = tool#VisibleRad();
			diff.Begin();
				d.ClearBackground(transparent);

				d.Circle(ws_last_mouse_pos, rad, brush_color);
				d.Line(ws_last_mouse_pos, ws_mouse_pos, rad * 2, brush_color);
				d.Circle(ws_mouse_pos, rad, brush_color);
			diff.End();
		}
		// -----------

		int use_cond = tool#UseCond();
		switch (use_cond) {
		USE_COND_L_PRESS -> {
			// TODO: break -> exit from switch
			if (mouse.LeftClickPressed()) {
				if (tool#AddUndoOnStartUse()) { AddLayerContentUndo(); }
				
				tool#Use();
			}
		},
		USE_COND_L_DOWN -> {
			// TODO: abstract first-use cond?
			if (tool#AddUndoOnStartUse() && mouse.LeftClickPressed()) { AddLayerContentUndo(); }

			tool#Use();
		},
		else -> panic(t"unknown use_cond: {use_cond}")
		}
	}

	canvas.Begin();
	d.ClearBackground(theme.canvas_bg);
	for (let layer in layers) {
		d.Texture(layer.rt, Vec2_zero);
	}
	canvas.End();

	d.TextureAtRect(canvas, RectV(to_screenspace(v2(0, 0)), v2(canvas_width, canvas_height).scale(view_scale)));

	LeftPanelUI();

	if (tool#VisibleRad() >= 0) {
		float rad = tool#VisibleRad();
		d.Circle(mouse_pos, rad * view_scale, Color{ .r = 255, .g = 255, .b = 255, .a = 55 }); // TODO: show edge of circle!
	}

	d.TextureAtRect(cursor_textures.get(DetermineCursorAppearance()), RectCenter(mouse_pos, Vec2_one.scale(48)));
}

void ExportCanvasToImage() {
	img = c:LoadImageFromTexture(canvas.texture);
	c:ImageFlipVertical(^img);
}

void ExportVideo(int framerate, char^ folder_path, char^ output_file_name_no_path) {
	char^ video_name = f"{output_file_name_no_path}.mp4";

	system(f"ffmpeg -y -framerate {framerate} -pattern_type glob -i '{folder_path}/*.png' -c:v libx264 -pix_fmt yuv420p {video_name}");
}

void RecordScreen() {
	int frames = 0;

	system("mkdir out/frames");

	while (true) {
		// c:sleep(1);
		int ms = 500;
		c:usleep(ms * 1000);
		frames++;

		while (!img_ready) {}

		char^ name = t"out/frames/{frames%D05}.png";
		img.ExportTo(name);
		img.delete();
		img_ready = false;

		println("%s recorded", name);
	}
}
