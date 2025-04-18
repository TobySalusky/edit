import std;
import rl;
c:import <"string.h">;

Color rgb(int r, int g, int b) -> {
	:r, :g, :b, .a = 255
};
Color rgba(int r, int g, int b, int a) -> {
	:r, :g, :b, :a
};

int hex_char(char c) {
	int res = c as..;
	if (res >= 48 && res <= 57) { // numbers 0-9
		res = res - 48;
	} else if (res >= 65 && res <= 70) { // characters A-F
		res = res - 65 + 10;
	} else if (res >= 97 && res <= 102) { // characters a-f
		res = res - 97 + 10;
	}
	return res;
}

// NOTE: hex_str should be WITHOUT leading #
Color hex(char^ hex_str) {
	int shift_index = (hex_str[0] == '#') ? 1 | 0;

	// if () { // TODO: error handle?
	// 	panic();
	// }

	int r = hex_char(hex_str[0 + shift_index]) * 16 + hex_char(hex_str[1 + shift_index]);
	int g = hex_char(hex_str[2 + shift_index]) * 16 + hex_char(hex_str[3 + shift_index]);
	int b = hex_char(hex_str[4 + shift_index]) * 16 + hex_char(hex_str[5 + shift_index]);
	int a = 255;
	if (strlen(hex_str) >= 8 + shift_index) {
		a = hex_char(hex_str[6 + shift_index]) * 16 + hex_char(hex_str[7 + shift_index]);
	}

	return rgba(r, g, b, a);
}

struct TimelineElementColorSet {
	Color bg;
	Color border;
	Color text;
}

struct NumberInputTheme {
	Color text;
	Color bg;
}

struct Theme {
	Color bg;
	Color canvas_bg;
	Color panel;
	Color panel_border;
	Color button; // TODO: button_hover
	Color button_hover; // TODO: button_hover
	Color button_err;
	Color active;

	NumberInputTheme number_input;

	TimelineElementColorSet elem_ui_pink; // normal
	TimelineElementColorSet elem_ui_yellow; // warning
	TimelineElementColorSet elem_ui_blue; // selected

	Color timeline_layer_info_gray;
	// Color elem_ui_yellow;

	Color keyframe_hover_highlight;
	Color modal_bg_darken;
	Color errmsg;

	Color progress_bar_bg;
	Color progress_bar_fg;
}

Theme MakeDarkTheme() -> {
	// TODO: hex"..."
	// .bg = hex("616161"),
	.bg = hex("222222"),
	.canvas_bg = hex("CCCCCC"),
	.panel = hex("4f4f4f"),
	.panel_border = hex("6b6b6b"),
	.button = hex("333333"),
	.button_hover = hex("222222"),
	.button_err = hex("765941"),
	.active = hex("FFAA00AA"),

	.number_input = {
		.text = hex("3bddff"),
		.bg = hex("3b3b3b"),
	},

	// .elem_ui_yellow = hex("CFAE55"),
	.elem_ui_pink = {
		.bg = hex("D6BCD6"),
		.border = hex("BFA6BF"),
		.text = hex("3D353D"),
	},
	.elem_ui_yellow = {
		.bg = hex("#eddd95"),
		.border = hex("#ccbe7e"),
		.text = hex("#302e21"),
	},
	.elem_ui_blue = {
		.bg = hex("#86a5d1"),
		.border = hex("#768fb3"),
		.text = hex("#20252b"),
	},
	.timeline_layer_info_gray = hex("AAAAAA"),
	.keyframe_hover_highlight = hex("0000FF99"),
	.modal_bg_darken = hex("00000033"),
	.errmsg = hex("FF4444"),

	.progress_bar_bg = hex("262626"), // gray
	.progress_bar_fg = hex("afc7af"), // green
};

Theme theme = MakeDarkTheme();
