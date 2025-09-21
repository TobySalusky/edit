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

// default value is dark theme!
struct Theme {
	Color bg = hex("222222");
	Color canvas_bg = hex("CCCCCC");
	Color panel_highlight = hex("5f5f5f");
	Color panel = hex("4f4f4f");
	Color panel_disabled = hex("3f3f3f");
	Color panel_border = hex("6b6b6b");
	Color panel_border_highlight = hex("8a8a8a");
	Color button = hex("333333");
	Color button_hover = hex("222222");
	Color button_err = hex("765941");
	Color active = hex("FFAA00AA");
	Color timeline_current_caret = Colors.Orange;

	NumberInputTheme number_input = {
		.text = hex("3bddff"),
		.bg = hex("3b3b3b"),
	};

	TimelineElementColorSet elem_ui_pink = { // normal
		.bg = hex("D6BCD6"),
		.border = hex("BFA6BF"),
		.text = hex("3D353D"),
	};
	TimelineElementColorSet elem_ui_yellow = { // warning
		.bg = hex("#eddd95"),
		.border = hex("#ccbe7e"),
		.text = hex("#302e21"),
	};
	TimelineElementColorSet elem_ui_blue = { // selected
		.bg = hex("#86a5d1"),
		.border = hex("#768fb3"),
		.text = hex("#20252b"),
	};

	Color timeline_layer_info_gray = hex("AAAAAA");

	Color keyframe_hover_highlight = hex("0000FF99");
	Color modal_bg_darken = hex("00000033");
	Color errmsg = hex("FF4444");

	Color progress_bar_bg = hex("262626");
	Color progress_bar_fg = hex("afc7af");

	Color timeline_second_line = hex("6b6b6bDD");
	Color timeline_tenth_second_line = hex("6b6b6b55");

	Color warning_bg = hex("00000088");
}

@no_hr
Theme theme = {};
