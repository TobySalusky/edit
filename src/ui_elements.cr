import rl;
import theming;
import std;
import clay_lib;
import global_settings;
import cursor;
import hotkey;
import globals;
import textures;

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

bool ClayIconButton(Texture& texture, Clay_Sizing button_sizing = .(16, 16), Clay_Sizing? icon_sizing = none) {
	bool clicked = false;
	$clay({
		.layout = { .sizing = button_sizing },
	}) {
		bool hovered = Clay.Hovered();
		if (hovered) {
			cursor_type = .Pointer;
		}

		$clay({
			.layout = {
				.sizing = button_sizing,
				.childAlignment = Clay_ChildAlignment.Center(),
			},
			.backgroundColor = 
				(hovered) ? { .r = 255, .g = 255, .b = 255, .a = 122 } | Colors.Transparent
		}) {
			$clay({
				.layout = { .sizing = icon_sizing.! or button_sizing },
				.image = .(texture),
			}) {
				if (mouse.LeftClickPressed() && hovered) {
					clicked = true;
				}
			};
		};
			
	};
	return clicked;
}

bool ClayIconDisableButton(Texture& texture, bool disabled, float size = 16) {
	bool clicked = false;
	$clay({
		.layout = { .sizing = .(size, size) },
	}) {
		bool hovered = Clay.Hovered();
		bool show_hover = hovered && !disabled;
		if (show_hover) {
			cursor_type = .Pointer;
		}

		$clay({
			.layout = { .sizing = .(size, size) },
			.backgroundColor = 
				(show_hover) ? { .r = 255, .g = 255, .b = 255, .a = 122 } | Colors.Transparent
		}) {
			$clay({
				.layout = { .sizing = .(size, size) },
				.image = .(texture),
				.backgroundColor = disabled ? { .r = 122, .g = 122, .b = 122, .a = 122 } | Colors.White, // tint
			}) {
				if (!disabled && mouse.LeftClickPressed() && hovered) {
					clicked = true;
				}
			};
		};
			
	};
	return clicked;
}

bool ClayButton(char^ text, Clay_ElementId id, Clay_Sizing sizing, uint font_size = rem(1)) {
	bool hovered = Clay.PointerOver(id);
	if (hovered) {
		cursor_type = .Pointer;
	}

	$clay({
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
	};

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
		caret_pos = size; // put caret at end of text
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
			// TODO: diff cond based on OS? (CONTROL for windows)
			if (key.AltIsDown()) {
				// TODO: proper delete to last chunk!!
				// * delete any whitespace before cursor
				// * delete within character class of first char (alphanumeric+_ | otherwise [symbols and otherwise])

				memset(buffer, 0, mem_size);
				size = 0;
				changed = true;
			} else {
				// NOTE: single char backspace
				// TODO: * repeat-on-hold 
				if (size > 0) {
					buffer[--size] = '\0';
					changed = true;
				}
			}
		}

		// if (CLEAR_ME) {
		// 	c:memset(buffer, 0, mem_size);
		// 	size = 0;
		// 	changed = true;
		// }

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

	$clay({
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
		$clay({ .layout = { .sizing = .(4, 0) }}) {}; // horiz-padding

		char^ display_text = input.is_active() ? input.buffer | init_text;
		clay_text(display_text, {
			.fontSize = font_size,
			.textColor = Colors.White,
		});
	};


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

	$clay({
		:id,
		.backgroundColor = bg,
		.cornerRadius = .(4)
	}) {
		clay_text(talloc_sprintf("%d", ival), { // NOTE: 1 decimal place!
			.fontSize = config.font_size,
			.textColor = Colors.Blue,
		});
	};

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
		cursor_type = .Default;
	}

	$clay({
		:id,
		.backgroundColor = bg,
		.cornerRadius = .(4)
	}) {
		clay_text(talloc_sprintf("%.1f", *f), { // NOTE: 1 decimal place!
			.fontSize = config.font_size,
			.textColor = Colors.Blue,
		});
	};

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
	bool reverse = false; // gr gives Index-out-of-Range!!!
	bool vertical = false; // vertical means line is horizontal (maybe rename?)

	// internal
	bool dragging = false;
	float f_at_drag_start = 0;
	float axis_coord_at_drag_start = 0;

	float _GetAxisCoord() -> (vertical) ? mouse.GetPos().y | mouse.GetPos().x;

	Rectangle GetPanelBounds() -> Clay.GetBoundingBox(.(t"{save_config_name}-panel"));

	void Update() {
		assert(save_config_name != NULL, "save_config_name == NULL!!!");
		assert(f != NULL, "f == NULL!!!");

		bool hovered = false;

		Clay_ElementId id = .(t"{save_config_name}-expander");
		$clay({
			.layout = {
				.sizing = Clay_Sizing{
					.width = CLAY_SIZING_FIXED(1),
					.height = CLAY_SIZING_GROW(),
				}.FlipIf(vertical),
				.childAlignment = { CLAY_ALIGN_X_CENTER, CLAY_ALIGN_Y_CENTER },
			},
			.backgroundColor = Clay.VisuallyHovered(id) ? theme.panel_border_highlight | theme.panel_border
		}) {
			$clay({
				:id,
				.layout = {
					.sizing = Clay_Sizing{
						.width = CLAY_SIZING_FIXED(8),
						.height = CLAY_SIZING_GROW(),
					}.FlipIf(vertical),
				},
			}) {
				hovered = Clay.Hovered();
			};
		};

		if (dragging) {
			float diff = _GetAxisCoord() - axis_coord_at_drag_start;
			if (reverse) {
				diff *= -1;
			}
			*f = GlobalSettings.set_float(save_config_name, std.max(min, f_at_drag_start + diff));
		}

		if (dragging || hovered) {
			cursor_type = (vertical) ? .ResizeVert | .ResizeHoriz;
		}

		if (!mouse.LeftClickDown()) {
			dragging = false;
		}

		if (!dragging && mouse.LeftClickPressed() && hovered) {
			axis_coord_at_drag_start = _GetAxisCoord();
			f_at_drag_start = *f;
			dragging = true;
		}
	}
}

PanelExpander& Panel__begin(PanelExpander& panel_expander) {
	Clay__OpenConfiguredElement({
		.id = .(t"{panel_expander.save_config_name}-panel"),
		.layout = panel_expander.vertical ? {
			.sizing = { CLAY_SIZING_GROW(), CLAY_SIZING_FIXED(*panel_expander.f), },
			.layoutDirection = CLAY_TOP_TO_BOTTOM,
		} | {
			.sizing = { CLAY_SIZING_FIXED(*panel_expander.f), CLAY_SIZING_GROW(), },
			.layoutDirection = CLAY_LEFT_TO_RIGHT,
		},
		.backgroundColor = theme.panel,
	});
	{
		if (panel_expander.reverse) {
			panel_expander.Update();
		}

		Clay__OpenConfiguredElement({
			.id = .(t"{panel_expander.save_config_name}-panel-contents"),
			.layout = {
				.sizing = .Grow(),
				.layoutDirection = CLAY_TOP_TO_BOTTOM,
			}
		});
		{
			// user content goes here!
		}
	}
	return panel_expander;
}

void Panel__end(PanelExpander& panel_expander) {
	Clay__CloseElement(); // inner

	if (!panel_expander.reverse) {
		panel_expander.Update(); // (must be after use content)
	}
	Clay__CloseElement(); // outer
}

struct ModalState {
	bool just_opened = false;
	// void^ user_data = NULL;
	fn_ptr<void(ModalState&)> fn_ptr;
	fn_ptr<void(ModalState&)> on_close_fn_ptr;

	char^ errmsg = NULL;

	void set_errmsg(char^ malloced_errmsg) {
		if (errmsg != NULL) { free(errmsg); }
		errmsg = malloced_errmsg;
	}

	void close() {
		if (on_close_fn_ptr != NULL) {
			on_close_fn_ptr(this);
		}

		set_errmsg(NULL);
	}
}
List<ModalState> _open_modal_states_add_next_frame;
List<ModalState> open_modal_states;

void ModalUI(using ModalState& state) {
	// modal-bg-darkener
	$clay({
		.id = .(t"modal-wrapper-{^state}"),
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
		$clay({
			.backgroundColor = theme.panel,
			.border = .(1, theme.panel_border),
			.layout = { .sizing = { CLAY_SIZING_PERCENT(0.5), CLAY_SIZING_PERCENT(0.5) } },
		}) {
			// padding
			$clay({
				.layout = {
					.sizing = .Grow(),
					.padding = .(rem(2)),
					.layoutDirection = CLAY_TOP_TO_BOTTOM,
				},
			}) {
				fn_ptr(state);
			};

		};
	};

	if (HotKeys.ESCAPE.IsPressed()) {
		CloseModal();
		// TODO: think abt stacked modals (this broken omg)
	}
}
void OpenModal(ModalState state) {
	_open_modal_states_add_next_frame.add(state);
}
void OpenModalFn(fn_ptr<void(ModalState&)> fn_ptr, fn_ptr<void(ModalState&)> on_close_fn_ptr = NULL) {
	OpenModal({ :fn_ptr, :on_close_fn_ptr  });
}
void CloseModal() { // closes top (current-most) modal!
	if (!open_modal_states.is_empty()) {
		open_modal_states.back().close();
		open_modal_states.pop_back();
	} else {
		println("[WARNING]: CloseModal called while open_modal_states was empty");
	}

	UnFocusUIElements(); // TODO: do better?
}

bool IsModalOpen(fn_ptr<void(ModalState&)> fn_ptr) {
	for (int i = open_modal_states.size - 1; i >= 0; i--) {
		let& modal_state = open_modal_states.get(i);
		if (modal_state.fn_ptr == fn_ptr) {
			return true;
		}
	}
	return false;
}

void CloseModalByFn(fn_ptr<void(ModalState&)> fn_ptr) {
	for (int i = open_modal_states.size - 1; i >= 0; i--) {
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
		open_modal_states.add(_open_modal_states_add_next_frame.pop_front() with { .just_opened = true });
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
	$clay({
		.layout = { :sizing },
		.backgroundColor = bg,
		.border = .(1, border),
	}) {
		$clay({
			.backgroundColor = fg,
			// .floating = {
			// 	.attachTo = CLAY_ATTACH_TO_PARENT,
			// 	.offset = {0,0},
			// 	// .attachPoints = {
			// 	// 	.element = CLAY_ATTACH_POINT_LEFT_CENTER,
			// 	// 	.parent = CLAY_ATTACH_POINT_LEFT_CENTER,
			// 	// },
			// },
			.layout = {
				.sizing = {
					CLAY_SIZING_PERCENT(proportion),
					CLAY_SIZING_GROW()
				}
			}
		}) {};
	};
}

struct SyncedRenderTextures {
	RenderTexture temp;
	RenderTexture result;
	bool valid;

	construct() {
		RenderTexture temp;
		RenderTexture result;
		return { :temp, :result, .valid = false };
	}

	void Sync(Rectangle rect) {
		int rw = std.maxi(1, rect.width as int);
		int rh = std.maxi(1, rect.height as int);
		if (!valid) {
			temp = RenderTexture(rw, rh);
			result = RenderTexture(rw, rh);
		} else if (temp.width() != rw || temp.height() != rh) {
			temp.delete();
			result.delete();
			
			temp = RenderTexture(rw, rh);
			result = RenderTexture(rw, rh);
			// println(t"resizing SyncedRenderTextures to {rw} {rh}");
		}
		valid = true;
	}

	RenderTexture& GetTarget() {
		assert(valid, "SyncedRenderTextures not valid! - must call Sync before GetTarget");
		return temp;
	}

	Texture& GetResult() {
		assert(valid, "SyncedRenderTextures not valid! - must call Sync before GetResult");
		return result.texture;
	}

	void UpdateResult() {
		result.Begin();
			d.Texture(temp.into(), {0,0});
		result.End();
	}
}

struct ColorPicker {
	static Shader color_picker_block_shader;
	static Shader color_picker_ring_shader;

	static void LoadAssets() {
		color_picker_block_shader = rl.LoadShader(NULL, "assets/shaders/color_picker.frag");
		color_picker_ring_shader = rl.LoadShader(NULL, "assets/shaders/hue_ring.frag");
	}

	bool holding_ring = false;
	bool holding_block = false;
	float h = 0; // 0-1 - TODO: should prob be 0-360
	float s = 0; // 0-1
	float v = 0; // 0-1
	// TODO: when not changing, use entered_color to sync up!

	SyncedRenderTextures rts = .();

	Color color() -> Colors.hsv(h * 360, s, v);

	Color? Update(char^ id, float padding) {
		Rectangle rect = Clay.GetBoundingBox(.(id));
		rts.Sync(rect);

		Color? ret = none;

		rts.GetTarget().Begin();
		{
			d.ClearBackground(Colors.Transparent);
			float diameter = std.min(rect.width - padding * 2, rect.height - padding * 2);
			float radius = diameter / 2;

			Rectangle inner_rect = rect.Inset(padding).FitIntoSelfWithAspectRatio(1, 1);
			Vec2 tl = inner_rect.tl() - rect.tl();
			Vec2 center = inner_rect.center() - rect.tl();

			float thickness = 15; // TODO: adjust for best looks

			let PtAt = (Vec2 p, float rw) -> {
				p.y = rw - p.y;
				d.Circle(p, 4, Colors.White);
				d.Circle(p, 3, Colors.Black);
			};

			float block_cross_length = diameter - (thickness * 2); // TODO: fix order of ops/type precedence -> 2*thickness = float :<
			float block_size = block_cross_length / (c:sqrtf(2.0));

			float block_start = (diameter - block_size) / 2;

			color_picker_ring_shader.SetFloat("size", diameter); // OPTIMIZE: inefficient!
			color_picker_ring_shader.SetFloat("ring_width", thickness);

			color_picker_block_shader.SetFloat("hue", h); // cyan

			color_picker_ring_shader.Begin();
				d.TextureAtSize(Textures.pixel, tl.x, tl.y, diameter, diameter);
			color_picker_ring_shader.End();

			color_picker_block_shader.Begin();
				Vec2 block_dimen = v2(block_size, block_size);
				Vec2 block_tl = tl + v2(block_start, block_start);
				d.TextureAtSizeV(Textures.pixel, block_tl, block_dimen);
			color_picker_block_shader.End();

			// Interaction ----------------------------
			Vec2 local_mouse_pos = mouse_pos - rect.tl();

			bool mouse_in_block = local_mouse_pos.InV(block_tl, block_dimen);
			inner_rect.Contains(local_mouse_pos);
			bool mouse_in_ring = local_mouse_pos.InCircle(center, radius) && !local_mouse_pos.InCircle(center, radius - thickness);

			if (mouse_in_block || mouse_in_ring) {
				cursor_type = CursorType.Pointer;
			}

			if (mouse.LeftClickPressed()) {
				if (mouse_in_ring) { holding_ring = true; }
				else if (mouse_in_block) { holding_block = true; }
			}

			if (mouse.LeftClickReleased()) {
				holding_ring = false;
				holding_block = false;
			}

			if (holding_ring) {
				float angle = ((local_mouse_pos - center) * Vec2{ .x = 1, .y = -1 }).angle0();
				h = Math.degrees(angle) / 360.0;
			}

			if (holding_block) {
				Vec2 uv = (local_mouse_pos - (tl + Vec2_one.scale(block_start))).divide(block_size).clamp(Vec2_zero, Vec2_one);

				s = uv.x;
				v = 1.0 - uv.y;
			}

			// interacted!
			if (holding_ring || holding_block) {
				ret = this.color();
			}
			// ----------------------------------------
			// selection points ---

			PtAt(tl + Vec2_one.scale(block_start) + Vec2{ .x = s, .y = 1.0 - v }.scale(block_size), rect.height);
			PtAt(center + unit_vec(Math.radians(h * 360.0)).scale(radius - thickness / 2), rect.height);

			// color swatch(es) ---
			// d.Rect(tl + Vec2_up.scale(diameter + 5), Vec2{ .x = diameter, .y = info_room - 5 }, this.color());
		}
		rts.GetTarget().End();
		// rts.UpdateResult();

		$clay({
			.id = .(id),
			.layout = {
				.sizing = {
					CLAY_SIZING_PERCENT(1),
					CLAY_SIZING_PERCENT(1),
				}
			},
		}) {
			$clay({
				.image = .(rts.GetTarget().texture),
				.layout = { .sizing = .(rect.width, rect.height) },
				.floating = {
					.attachTo = CLAY_ATTACH_TO_PARENT,
					.offset = {0,0},
					// .attachPoints = {
					// 	.element = CLAY_ATTACH_POINT_LEFT_CENTER,
					// 	.parent = CLAY_ATTACH_POINT_LEFT_CENTER,
					// },
				},
			}) {};
		};

		return ret;
	}
}

struct ViewRange {
	float start;
	float end;

	float width() -> end - start;

	void debug_print(char^ msg) {
		println(t"{msg}: {start=} {end=}");
	}
}

struct ViewRangeSlider {
	ViewRange range;
	bool vertical = false;
	bool reverse = false;

	bool left_dragging = false;
	bool right_dragging = false;
	bool mid_dragging = false;
	float drag_mouse_axis_value_start = 0;
	float drag_value_start = 0;
	ViewRange drag_range_start = { .start = 0, .end = 0 };

	bool IsInteracting() -> left_dragging || right_dragging || mid_dragging;
	
	void Update(char^ id, float min, float max, float min_span) {
		float range_width = max - min;

		let primary_inner_padding = 4;
		let secondary_inner_padding = 4;

		Clay_ElementId left_grabber_part_id = .(t"{id}-left-grabber-part");
		bool left_grabber_part_hovered = Clay.GetBoundingBox(left_grabber_part_id).Contains(mouse_pos) && !(right_dragging || mid_dragging);
		Clay_ElementId right_grabber_part_id = .(t"{id}-right-grabber-part");
		bool right_grabber_part_hovered = Clay.GetBoundingBox(right_grabber_part_id).Contains(mouse_pos) && !(left_dragging || mid_dragging);
		Clay_ElementId mid_grabber_part_id = .(t"{id}-mid-grabber-part");
		bool mid_grabber_part_hovered = !(left_grabber_part_hovered || right_grabber_part_hovered) && Clay.GetBoundingBox(mid_grabber_part_id).Contains(mouse_pos) && !(left_dragging || right_dragging);

		Clay_ElementId container_id = .(t"{id}-slider-container");
		float usable_container_size = Clay.GetBoundingBox(container_id).AxisSize(vertical) - primary_inner_padding*2;
		$clay({
				.id = container_id,
				.backgroundColor = theme.button,
				.layout = {
					.sizing = Clay_Sizing{ .width = CLAY_SIZING_GROW() }.FlipIf(vertical),
					.layoutDirection = (vertical) ? CLAY_TOP_TO_BOTTOM | CLAY_LEFT_TO_RIGHT
				} 
		}) {
			$clay({ .layout = { .sizing = Clay_Sizing(primary_inner_padding , rem(1)).FlipIf(vertical) } }) {};
			$clay({
				.layout = {
					.sizing = Clay_Sizing{
						.width = CLAY_SIZING_GROW(),
						.height = CLAY_SIZING_FIXED(rem(1)),
					}.FlipIf(vertical),
					.padding = Clay_Padding{
						.top = secondary_inner_padding,
						.bottom = secondary_inner_padding,
					}.FlipIf(vertical),
					.layoutDirection = (vertical) ? CLAY_TOP_TO_BOTTOM | CLAY_LEFT_TO_RIGHT
				},
			}) {
				$clay({
					.layout = {
						.sizing = Clay_Sizing{
							.width = CLAY_SIZING_PERCENT((reverse) ? ((max - range.end) / range_width) | (range.start / range_width)),
							.height = CLAY_SIZING_GROW(),
						}.FlipIf(vertical)
					}
				}) {};

				float radius = (rem(1) - 8) / 2;
				float radius_outer_expand = 2;
				$clay({
					.layout = {
						.sizing = Clay_Sizing{
							.width = CLAY_SIZING_FIXED(radius),
							.height = CLAY_SIZING_GROW(),
						}.FlipIf(vertical),
						.layoutDirection = (vertical) ? CLAY_TOP_TO_BOTTOM | CLAY_LEFT_TO_RIGHT
					}
				}) {
					$clay({
						.id = left_grabber_part_id,
						.cornerRadius = .(radius+radius_outer_expand),
						.backgroundColor = theme.button,
						.layout = {
							.sizing = Clay_Sizing((radius + radius_outer_expand)*2+2, (radius + radius_outer_expand)*2).FlipIf(vertical),
						},
						.floating = {
							.attachTo = CLAY_ATTACH_TO_PARENT,
							.attachPoints = {
								.element = CLAY_ATTACH_POINT_CENTER_CENTER,
								.parent = (vertical) ? CLAY_ATTACH_POINT_CENTER_BOTTOM | CLAY_ATTACH_POINT_RIGHT_CENTER,
							}
						}
					}) {
						if (left_grabber_part_hovered && !Clay.Hovered()) { left_grabber_part_hovered = false; } // invalidate false hover
						if (left_grabber_part_hovered && mouse.LeftClickPressed()) {
							left_dragging = true;
							drag_mouse_axis_value_start = mouse_pos.AxisMag(vertical);
							drag_range_start = range;
						}
					};
					$clay({
						.cornerRadius = .(radius),
						.backgroundColor = (left_grabber_part_hovered || left_dragging) ? theme.panel_border | theme.panel,
						.layout = {
							.sizing = .(radius*2, radius*2),
						},
						.floating = {
							.attachTo = CLAY_ATTACH_TO_PARENT,
							.attachPoints = {
								.element = CLAY_ATTACH_POINT_CENTER_CENTER,
								.parent = (vertical) ? CLAY_ATTACH_POINT_CENTER_BOTTOM | CLAY_ATTACH_POINT_RIGHT_CENTER,
							},
							.pointerCaptureMode = CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH,
						}
					}) {};
				};

				// TODO: clay hovered by id!!!! i want, hoshii!!!
				$clay({
					.id = mid_grabber_part_id,
					.layout = {
						.sizing = .Grow()
					},
					.backgroundColor = (mid_grabber_part_hovered || mid_dragging) ? theme.panel_border | theme.panel,
				}) {
					if (mid_grabber_part_hovered && !Clay.Hovered()) { mid_grabber_part_hovered = false; } // invalidate false hover
						if (mid_grabber_part_hovered && mouse.LeftClickPressed()) {
							mid_dragging = true;
							drag_mouse_axis_value_start = mouse_pos.AxisMag(vertical);
							drag_range_start = range;
						}
				};
				$clay({
					.layout = {
						.sizing = Clay_Sizing{
							.width = CLAY_SIZING_FIXED(radius),
							.height = CLAY_SIZING_GROW(),
						}.FlipIf(vertical),
						.layoutDirection = (vertical) ? CLAY_TOP_TO_BOTTOM | CLAY_LEFT_TO_RIGHT
					}
				}) {
					$clay({
						.id = right_grabber_part_id,
						.cornerRadius = .(radius+radius_outer_expand),
						.backgroundColor = theme.button,
						.layout = {
							.sizing = Clay_Sizing((radius + radius_outer_expand)*2+2, (radius + radius_outer_expand)*2).FlipIf(vertical),
						},
						.floating = {
							.attachTo = CLAY_ATTACH_TO_PARENT,
							.attachPoints = {
								.element = CLAY_ATTACH_POINT_CENTER_CENTER,
								.parent = (vertical) ? CLAY_ATTACH_POINT_CENTER_TOP | CLAY_ATTACH_POINT_LEFT_CENTER,
							}
						}
					}) {
						if (right_grabber_part_hovered && !Clay.Hovered()) { right_grabber_part_hovered = false; } // invalidate false hover
						if (right_grabber_part_hovered && mouse.LeftClickPressed()) {
							right_dragging = true;
							drag_mouse_axis_value_start = mouse_pos.AxisMag(vertical);
							drag_range_start = range;
						}
					};
					$clay({
						.cornerRadius = .(radius),
						.backgroundColor = (right_grabber_part_hovered || right_dragging) ? theme.panel_border | theme.panel,
						.layout = {
							.sizing = .(radius*2, radius*2),
						},
						.floating = {
							.attachTo = CLAY_ATTACH_TO_PARENT,
							.attachPoints = {
								.element = CLAY_ATTACH_POINT_CENTER_CENTER,
								.parent = (vertical) ? CLAY_ATTACH_POINT_CENTER_TOP | CLAY_ATTACH_POINT_LEFT_CENTER,
							},
							.pointerCaptureMode = CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH,
						}
					}) {};
				};
				$clay({
					.layout = {
						.sizing = Clay_Sizing{
							.width = CLAY_SIZING_PERCENT((reverse) ? (range.start / range_width) | ((max - range.end) / range_width)),
							.height = CLAY_SIZING_GROW(),
						}.FlipIf(vertical)
					}
				});
			};
			$clay({ .layout = { .sizing = Clay_Sizing(primary_inner_padding, rem(1)).FlipIf(vertical) } }) {};
		};

		if (left_grabber_part_hovered || right_grabber_part_hovered || mid_grabber_part_hovered || left_dragging || right_dragging || mid_dragging) {
			cursor_type = .Pointer;
		}
		if (mouse.LeftClickReleased()) {
			left_dragging = false;
			mid_dragging = false;
			right_dragging = false;
		}

		float mouse_delta = mouse_pos.AxisMag(vertical) - drag_mouse_axis_value_start;
		float viewspace_delta = (mouse_delta / usable_container_size) * range_width;
		if (reverse) { viewspace_delta *= -1; }
		if (left_dragging) {
			if (reverse) {
				range.end = std.max(drag_range_start.end + viewspace_delta, range.start + min_span);
			} else {
				range.start = std.min(drag_range_start.start + viewspace_delta, range.end - min_span);
			}
		}
		if (right_dragging) {
			if (reverse) {
				range.start = std.min(drag_range_start.start + viewspace_delta, range.end - min_span);
			} else {
				range.end = std.max(drag_range_start.end + viewspace_delta, range.start + min_span);
			}
		}
		if (mid_dragging) {
			float allowable_viewspace_delta = std.clamp(
				viewspace_delta,
				min - drag_range_start.start,
				max - drag_range_start.end
			);
			range = {
				.start = drag_range_start.start + allowable_viewspace_delta,
				.end = drag_range_start.end + allowable_viewspace_delta,
			};
		}

		if (range.start < min) { range.start = min; }
		if (range.end > max) { range.end = max; }
	}
}
