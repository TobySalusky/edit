import rl;
import theming;
import std;
import clay_lib;
import global_settings;
import cursor;
import hotkey;

uint root_font_size = GlobalSettings.get_int("root_font_size", 24);

uint rem(float root_elem_font_size_mult) -> (root_elem_font_size_mult * root_font_size) as ..; // TODO: autocompletions for inline -> method params

char^ LoadingDotDotDotStr() {
	float ps = rl.GetTime() - (rl.GetTime() as int);
	return t".{(ps > 0.33) ? "." | " "}{(ps > 0.66) ? "." | " "}";
}

struct UiElementID {
	void^ ptr;
	int i; // normally 0, unless ID_i

	bool operator:==(UiElementID other) -> ptr == other.ptr && i == other.i;
	
	// TODO: do defaults work for constructors?
	static UiElementID ID(void^ ptr, int i = 0) -> {
		:ptr,
		:i,
	};
}

UiElementID focused_ui_elem_id = UiElementID.ID(NULL);
bool ui_element_activated_this_frame = false;
bool NoTextInputFocused() {
	return focused_ui_elem_id == UiElementID.ID(NULL);
}

bool ClayButton(char^ text, Clay_ElementId id, Clay_Sizing sizing, uint font_size = rem(1)) {
	bool hovered = Clay.PointerOver(id);
	if (hovered) {
		cursor_type = .Pointer;
	}

	#clay({
		:id,
		.layout = {
			:sizing,
			.childAlignment = {
				.x = CLAY_ALIGN_X_CENTER,
				.y = CLAY_ALIGN_Y_CENTER,
			}
		},
		.backgroundColor = hovered ? theme.button_hover | theme.button,
	}) {
		clay_text(text, { .fontSize = font_size, .textColor = Colors.White });
	}

	return mouse.LeftClickPressed() && hovered;
}

bool Button(Vec2 tl, Vec2 dimens, char^ text) {
	Vec2 br = tl + dimens;

	d.RectBetween(tl, br, theme.button);
	bool hovered = mouse.GetPos().Between(tl, br);

	if (hovered) { // hover overlay-lighten
		cursor_type = .Pointer;
		d.RectBetween(tl, br, hex("FFFFFF11"));
	}

	int fontSize = 18;

	float text_width = c:MeasureText(text, fontSize);
	float center_x = tl.x + dimens.x / 2;
	int tx = (center_x - text_width / 2) as int;
	int ty = (tl.y + dimens.y / 2 - fontSize / 2) as int;
	d.Text(text, tx, ty, fontSize, c:WHITE);

	return mouse.LeftClickPressed() && hovered;
}

bool ButtonIcon(Vec2 tl, Vec2 dimens, Texture icon_texture) {
	Vec2 br = tl + dimens;

	// d.RectBetween(tl, br, theme.button);
	bool hovered = mouse.GetPos().Between(tl, br);

	// if (hovered) { // hover overlay-lighten
	// 	d.RectBetween(tl, br, hex("FFFFFF11"));
	// }

	// TODO: highlight w/ color on `hovered`
	d.TextureAtSizeV(icon_texture, tl, dimens);

	return mouse.LeftClickPressed() && hovered;
}

bool ButtonForceHover(Vec2 tl, Vec2 dimens, char^ text, bool force_hover, Color button_bg) {
	Vec2 br = tl + dimens;

	d.RectBetween(tl, br, button_bg);
	bool hovered = mouse.GetPos().Between(tl, br);

	if (hovered || force_hover) { // hover overlay-lighten
		d.RectBetween(tl, br, hex("FFFFFF11"));
	}

	int fontSize = 18;

	float text_width = c:MeasureText(text, fontSize);
	float center_x = tl.x + dimens.x / 2;
	int tx = (center_x - text_width / 2) as int;
	int ty = (tl.y + dimens.y / 2 - fontSize / 2) as int;
	d.Text(text, tx, ty, fontSize, Colors.White);

	return mouse.LeftClickPressed() && hovered;
}

// struct TextInput {
// 	List<char> char_list;
//
// 	int cursor_i;
// 	bool selected;
// 	bool hovered;
//
// 	Rectangle rect;
//
// 	Font font;
// 	int font_size;
// 	float padding;
//
// 	construct(char^ init_text, float padding, Font font, int font_size) {
// 		List<char> char_list = .();
// 		// List a = .(10, 20);
// 		for (int i in ..strlen(init_text)) {
// 			char_list.add(init_text[i]);
// 		}
//
// 		return {
// 			:char_list,
// 			.cursor_i = 0,
// 			.selected = false,
// 			.hovered = false,
// 			.rect = RectV(v2(0, 0), v2(0, 0)),
// 			:font,
// 			:font_size,
// 			:padding,
// 		};
// 	}
//
// 	static Self make(char^ init_text) -> .(init_text, 4, c:GetFontDefault(), 16);
//
// 	char^ ttext() {
// 		char^ text = talloc(char_list.size + 1);
// 		c:memcpy(text, char_list.data, char_list.size);
// 		text[char_list.size] = "\0"[0];
// 		return text;
// 	}
// 	char^ mtext() -> f"{this.ttext()}";
//
// 	// @discardable
// 	Vec2 Layout(Vec2 tl, float width) { // returns dimens
// 		// TODO: is "0" an ok string to measure?
// 		float height = c:MeasureTextEx(font, "0", font_size, 0).y + padding*2; // TODO: what is the right spacing num???
// 		rect = RectV(tl, v2(width, height));
// 		return rect.dimen();
// 	}
//
// 	// // @discardable
// 	// Vec2 Layout(Rectangle rect) { // returns dimens
// 	// 	return rect.dimen();
// 	// }
//
// 	void Interact() {
// 		selected = rect.Contains(mouse.GetPos());
// 	}
//
// 	Color bg() -> selected ? theme.active | theme.button;
//
// 	void Render() {
// 		d.Rect(rect.tl(), rect.dimen(), this.bg());
// 		let text_tl = rect.tl() + v2(padding, padding);
// 		d.TextV(this.ttext(), text_tl, font_size, Colors.White);
// 	}
//
// 	void Do() {
// 		this.Interact();
// 		this.Render();
// 	}
// }

void UnFocusUIElements() {
	focused_ui_elem_id = UiElementID.ID(NULL);
}

struct TextInputState {
	// NOTE: includes null-term
	static int mem_size = 256; // TODO: per-input size?

	// NOTE: includes null-term
	static int char_capacity = 255; // TODO: per-input size?

	char^ buffer;
	int caret_pos;
	int size;
	UiElementID id;

	bool is_active() -> id == focused_ui_elem_id;

	void Activate() {
		focused_ui_elem_id = id;
		ui_element_activated_this_frame = true;
	}

	void InitFrom(char^ str) {
		c:strncpy(buffer, str, char_capacity);
		size = strlen(str);
	}

	// NOTE: MUST BE ACTIVE
	// if unchanged: return NULL
	// if changed: return TextInputState-owned char^ (should be strdupped or temp outside use!)
	char^ DoActiveEffects() {
		bool changed = false;

		int key_pressed = c:GetCharPressed();
		while (key_pressed > 0) {
			if (char_capacity > size) {
				buffer[size++] = key_pressed as char;
			}
			key_pressed = c:GetCharPressed();

			changed = true;
		}

		if (key.IsPressed(KEY.BACKSPACE)) {
			c:memset(buffer, 0, mem_size);
			size = 0;

			changed = true;
		}

		return changed ? buffer | NULL;
	}
}

// TODO: styling/colour options

// NOTE: always returns ptr to buffer
TextInputState& TextBoxMaintained(UiElementID ui_id, Clay_ElementId clay_id, char^ init_text, Clay_Sizing sizing, int font_size) {
	TextInputState& input = GetTextInput(ui_id);
	
	TextBox(ui_id, clay_id, input.buffer, sizing, font_size);
	return input;
}

// NOTE: null returns when not changed
char^ TextBox(UiElementID ui_id, Clay_ElementId clay_id, char^ init_text, Clay_Sizing sizing, int font_size) {
	TextInputState& input = GetTextInput(ui_id);
	char^ res = NULL;

	if (init_text == NULL) { init_text = ""; }

	bool hovered = Clay.PointerOver(clay_id);

	if (hovered) {
		cursor_type = .IBeam;
	}

	if (mouse.LeftClickPressed() && hovered) {
		println("[DEBUG]: activating textbox!");
		if (!input.is_active() && init_text != input.buffer) {
			input.InitFrom(init_text);
		}
		input.Activate();
	}

	#clay({
		.id = clay_id,
		.layout = {
			:sizing,
			.childAlignment = {
				.y = CLAY_ALIGN_Y_CENTER
			},
		},
		.backgroundColor = theme.button,
		.border = .(1, input.is_active() ? theme.active | theme.panel_border),
	}) {
		if (input.is_active()) {
			res = input.DoActiveEffects();

			if (key.IsPressed(KEY.ESCAPE)) { // TODO: use hotkeys, but w/o non-input req!
				UnFocusUIElements();
			}
		}
		#clay({ .layout = { .sizing = .(4, 0) }}) {} // horiz-padding

		char^ display_text = input.is_active() ? input.buffer | init_text;
		clay_text(display_text, {
			.fontSize = font_size,
			.textColor = Colors.White,
		});
	}


	return res;
}

// key as UiElementID is kinda mid for multi-elem/layer setups :(
EqMap<UiElementID, TextInputState> text_inputs;
TextInputState& GetTextInput(UiElementID id) {
	if (!text_inputs.has(id)) {
		char^ buffer = c:calloc(1, 256);
		text_inputs.put_unique(id, {
			:buffer,
			.caret_pos = 0,
			.size = 0,
			:id
		});
	}
	return text_inputs.get(id);
}
TextInputState& GetTextInputNamed(char^ unique_name) -> GetTextInput(UiElementID.ID(unique_name));

// struct Flex {
// 	Clay_ElementDeclaration FloatEnd() -> {
// 		
// 	};
// }

struct SlidingFloatTextBoxConfig {
	float min = -c:FLT_MAX;
	float max = c:FLT_MAX;
	uint font_size = rem(1);
}

struct SlidingIntTextBoxConfig {
	int min = c:INT_MIN;
	int max = c:INT_MAX;
	uint font_size = rem(1);
}

struct GlobalSlidingFloatTextBoxState {
	static float^ fp_active;
	static float drag_x_start;
	static float drag_value_start;

	// static int DECIMAL_PLACES = 1; - currently 1, hardcoded!
	static float SLIDE_MULT = 1;
}

struct GlobalSlidingIntegralTextBoxState {
	static void^ ip_active;
	static float drag_x_start;
	static int drag_value_start;

	// static int DECIMAL_PLACES = 1; - currently 1, hardcoded!
	static float SLIDE_MULT = 1;
}

Opt<int> SlidingIntTextBox(Clay_ElementId id, int^ ip, SlidingIntTextBoxConfig config = {}) -> SlidingIntegralTextBox(id, *ip, ip, config);

Opt<uchar> SlidingUCharTextBox(Clay_ElementId id, uchar^ up, SlidingIntTextBoxConfig config = {}) ->
	match(SlidingIntegralTextBox(id, *up, up, config)) {
		int n -> n as uchar,
		None -> none
	};


Opt<int> SlidingIntegralTextBox(Clay_ElementId id, int ival, void^ ptr, SlidingIntTextBoxConfig config = {}) {
	if (ptr == NULL) {
		println("WARNING[SlidingIntegralTextBox]: ptr == NULL");
		return none;
	}

	Color bg = Colors.Transparent;

	bool hovered = Clay.PointerOver(id);

	if (hovered) {
		bg = theme.panel_border;
		cursor_type = .Pointer;
	}

	#clay({
		:id,
		.backgroundColor = bg,
		.cornerRadius = .(4)
	}) {
		clay_text(talloc_sprintf("%d", ival), { // NOTE: 1 decimal place!
			.fontSize = config.font_size,
			.textColor = Colors.Blue,
		});
	}

	// NOTE: (:danger): assumes never hovered on multiple of these!!!

	if (mouse.LeftClickReleased()) {
		GlobalSlidingIntegralTextBoxState.ip_active = NULL;
	}
	
	if (hovered && mouse.LeftClickPressed()) {
		GlobalSlidingIntegralTextBoxState.ip_active = ptr;
		GlobalSlidingIntegralTextBoxState.drag_x_start = mouse.GetPos().x;
		GlobalSlidingIntegralTextBoxState.drag_value_start = ival;
	}

	if (ptr == GlobalSlidingIntegralTextBoxState.ip_active) {
		float x_diff = mouse.GetPos().x - GlobalSlidingIntegralTextBoxState.drag_x_start;
		return std.clampi((GlobalSlidingIntegralTextBoxState.drag_value_start as float + x_diff * GlobalSlidingIntegralTextBoxState.SLIDE_MULT) as int, config.min, config.max);
	}
	return none;
}

Opt<float> SlidingFloatTextBox(Clay_ElementId id, float^ f, SlidingFloatTextBoxConfig config = {}) {
	if (f == NULL) {
		println("WARNING[SlidingFloatTextBox]: f == NULL");
		return none;
	}

	Color bg = Colors.Transparent;

	bool hovered = Clay.PointerOver(id);

	if (hovered) {
		bg = theme.panel_border;
		cursor_type = .Pointer;
	}

	#clay({
		:id,
		.backgroundColor = bg,
		.cornerRadius = .(4)
	}) {
		clay_text(talloc_sprintf("%.1f", *f), { // NOTE: 1 decimal place!
			.fontSize = config.font_size,
			.textColor = Colors.Blue,
		});
	}

	// NOTE: (:danger): assumes never hovered on multiple of these!!!

	if (mouse.LeftClickReleased()) {
		GlobalSlidingFloatTextBoxState.fp_active = NULL;
	}
	
	if (hovered && mouse.LeftClickPressed()) {
		GlobalSlidingFloatTextBoxState.fp_active = f;
		GlobalSlidingFloatTextBoxState.drag_x_start = mouse.GetPos().x;
		GlobalSlidingFloatTextBoxState.drag_value_start = *f;
	}

	if (f == GlobalSlidingFloatTextBoxState.fp_active) {
		float x_diff = mouse.GetPos().x - GlobalSlidingFloatTextBoxState.drag_x_start;
		return std.clamp(GlobalSlidingFloatTextBoxState.drag_value_start + x_diff * GlobalSlidingFloatTextBoxState.SLIDE_MULT, config.min, config.max);
	}
	return none;
}

struct PanelExpander {
	float^ f;
	char^ save_config_name; // @not-null
	float min;
	bool reverse = false;
	bool vertical = false; // vertical means line is horizontal (maybe rename?)

	// internal
	bool dragging = false;
	float f_at_drag_start = 0;
	float axis_coord_at_drag_start = 0;

	float _GetAxisCoord() -> vertical ? mouse.GetPos().y | mouse.GetPos().x;

	void Update() {
		assert(save_config_name != NULL, "save_config_name == NULL!!!");
		assert(f != NULL, "f == NULL!!!");

		bool moused_over = false;

		#clay({
			.layout = {
				.sizing = vertical ? {
					.width = CLAY_SIZING_GROW(),
					.height = CLAY_SIZING_FIXED(1),
				} | {
					.width = CLAY_SIZING_FIXED(1),
					.height = CLAY_SIZING_GROW(),
				},
				.childAlignment = { CLAY_ALIGN_X_CENTER, CLAY_ALIGN_Y_CENTER },
			},
			.backgroundColor = theme.panel_border
		}) {
			#clay({
				.layout = {
					.sizing = vertical ? {
						.width = CLAY_SIZING_GROW(),
						.height = CLAY_SIZING_FIXED(16),
					} | {
						.width = CLAY_SIZING_FIXED(16),
						.height = CLAY_SIZING_GROW(),
					},
				},
			}) {
				moused_over = Clay.Hovered();
			}
		}

		if (dragging) {
			float diff = _GetAxisCoord() - axis_coord_at_drag_start;
			if (reverse) {
				diff *= -1;
			}
			*f = GlobalSettings.set_float(save_config_name, std.max(min, f_at_drag_start + diff));
		}

		if (dragging || moused_over) {
			cursor_type = .ResizeHoriz;
		}

		if (!mouse.LeftClickDown()) {
			dragging = false;
		}

		if (!dragging && mouse.LeftClickPressed() && moused_over) {
			axis_coord_at_drag_start = _GetAxisCoord();
			f_at_drag_start = *f;
			dragging = true;
		}
	}
}

c:`typedef void(*void_takes_ModalState_ref_fn_ptr_t)(ModalState*);`;
struct ModalState {
	bool just_opened = false;
	// void^ user_data = NULL;
	c:void_takes_ModalState_ref_fn_ptr_t fn_ptr;
	c:void_takes_ModalState_ref_fn_ptr_t on_close_fn_ptr;

	char^ errmsg = NULL;

	void set_errmsg(char^ malloced_errmsg) {
		if (errmsg != NULL) { free(errmsg); }
		errmsg = malloced_errmsg;
	}

	void close() {
		if (on_close_fn_ptr != NULL) {
			on_close_fn_ptr(^this);
		}

		set_errmsg(NULL);
	}
}
List<ModalState> _open_modal_states_add_next_frame;
List<ModalState> open_modal_states;

void ModalUI(using ModalState& state) {
	// modal-bg-darkener
	#clay({
		.backgroundColor = theme.modal_bg_darken,
		// .id = .(t"{^state}"),
		.layout = {
			.sizing = .(rl.GetScreenWidth(), rl.GetScreenHeight()), // NOTE: TODO: real
			.childAlignment = { CLAY_ALIGN_X_CENTER, CLAY_ALIGN_Y_CENTER, }
		},
		.floating = {
			.attachTo = CLAY_ATTACH_TO_ROOT,
			.zIndex = 100, // TODO: standardize
			.attachPoints = {
				.element = CLAY_ATTACH_POINT_CENTER_CENTER,
				.parent = CLAY_ATTACH_POINT_CENTER_CENTER,
			}
		},
	}) {
		// modal
		#clay({
			.backgroundColor = theme.panel,
			.border = .(1, theme.panel_border),
			.layout = { .sizing = { CLAY_SIZING_PERCENT(0.5), CLAY_SIZING_PERCENT(0.5) } }
		}) {
			// padding
			#clay({
				.layout = {
					.sizing = Clay_Sizing.Grow(),
					.padding = .(rem(2)),
					.layoutDirection = CLAY_TOP_TO_BOTTOM,
				},
			}) {
				fn_ptr(^state);
			}

		}
	}

	if (HotKeys.ESCAPE.IsPressed()) {
		CloseModal();
		// TODO: think abt stacked modals (this broken omg)
	}
}
void OpenModal(ModalState state) {
	_open_modal_states_add_next_frame.add(state);
}
void OpenModalFn(c:void_takes_ModalState_ref_fn_ptr_t fn_ptr, c:void_takes_ModalState_ref_fn_ptr_t on_close_fn_ptr = NULL) {
	OpenModal({ :fn_ptr, :on_close_fn_ptr  });
}
void CloseModal() { // closes top (current-most) modal!
	if (!open_modal_states.is_empty()) {
		println("[WARNING]: CloseModal called while open_modal_states was empty");
		open_modal_states.back().close();
		open_modal_states.pop_back();
	}
	UnFocusUIElements(); // TODO: do better?
}

bool IsModalOpen(c:void_takes_ModalState_ref_fn_ptr_t fn_ptr) {
	for (int i = open_modal_states.size - 1; i >= 0; i--;) {
		let& modal_state = open_modal_states.get(i);
		if (modal_state.fn_ptr == fn_ptr) {
			return true;
		}
	}
	return false;
}

void CloseModalByFn(c:void_takes_ModalState_ref_fn_ptr_t fn_ptr) {
	for (int i = open_modal_states.size - 1; i >= 0; i--;) {
		let& modal_state = open_modal_states.get(i);
		if (modal_state.fn_ptr == fn_ptr) {
			modal_state.close();
			open_modal_states.remove_at(i);
		}
	}
	// this can close 0-inf # of the specified fn_ptr modal!
}
void DisplayModals() {
	for (let& modal_state in open_modal_states) {
		ModalUI(modal_state);
		modal_state.just_opened = false;
	}

	// add next frame so that inputs on the current frame won't be processed by auto-activated textboxes! (since this is common for modals)
	while (!_open_modal_states_add_next_frame.is_empty()) {
		open_modal_states.add(_open_modal_states_add_next_frame.pop_front() with { just_opened = true });
	}
}

void LoadingProgressBar(char^ label, float proportion) {
	// // Color color = ColorLerp(bg, fg, Sin01((rl.GetTime() - export_state.start_ffmpeg_time) * 5) * 0.7)
	// bool done_loading  = proportion >= 1;
	// Opt<char^> str = t"{label}{done_loading ? "" | LoadingDotDotDotStr()}: {proportion * 100.0 as int}";
	Opt<char^> str = label;
	ProgressBar(str, proportion, {
		.width = CLAY_SIZING_GROW(),
		.height = CLAY_SIZING_FIXED(rem(1.5)),
	});
}

void ProgressBar(Opt<char^> label, float proportion, Clay_Sizing sizing, Color bg = theme.progress_bar_bg, Color fg = theme.progress_bar_fg, Color border = theme.panel_border) {
	if (label is Some) {
		clay_text(label as Some, { .fontSize = rem(1), .textColor = Colors.White });
	}
	#clay({
		.layout = { :sizing },
		.backgroundColor = bg,
		.border = .(1, border),
	}) {
		#clay({
			.backgroundColor = fg,
			.layout = {
				.sizing = {
					CLAY_SIZING_PERCENT(proportion),
					CLAY_SIZING_GROW()
				}
			}
		}) {}
	}
}
