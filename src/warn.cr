import rl;
import std;
import clay_lib;
import ui_elements;
import theming;

enum ProgramWarningKind {
	MISSING_PROJECT,
	MISSING_COMPOSITION,
	;
}

struct ProgramWarning {
	ProgramWarningKind kind;
	char^ msg; // malloced! (strdup-ed)
	double time_issued;

	construct(ProgramWarningKind kind, char^ msg) -> {
		:kind,
		:msg,
		.time_issued = rl.GetTime(),
	};
}

struct ProgramWarningLog {
	ProgramWarning[] shown_warnings = {};
	ProgramWarning[] ignored_warnings = {};


	static float max_warning_display_time = 2;
	static float animation_time = 0.2;

	void Update() {
		float width = 300;
		float height = 50;
		float padding = 20;

		float time = rl.GetTime();

		int n = 0;
		for (int i = shown_warnings.size - 1; i >= 0; i--) {
			let& warning = shown_warnings[i];
			if (warning.time_issued < (time - max_warning_display_time )) { break; }

			float animation_slide_by = 0;
			if ((time - warning.time_issued) < animation_time) {
				float inverted_p = 1.0 - ((time - warning.time_issued) / animation_time);
				animation_slide_by = (InterpolationFns.EaseInSine(inverted_p)) * (padding + width);
			} else if ((time - warning.time_issued) > (max_warning_display_time - animation_time)) {
				float p = ((time - warning.time_issued) - (max_warning_display_time - animation_time)) / animation_time;
				animation_slide_by = (InterpolationFns.EaseOutSine(p)) * (padding + width);
			}

			$clay({
				.floating = {
					.attachTo = CLAY_ATTACH_TO_ROOT,
					.zIndex = 999,
					.attachPoints = {
						.element = CLAY_ATTACH_POINT_RIGHT_BOTTOM,
						.parent = CLAY_ATTACH_POINT_RIGHT_BOTTOM,
					},
					.offset = { -padding + animation_slide_by, -(padding + (padding + height) * n) },
				},
				.layout = {
					.(width, height)
				},
				.backgroundColor = theme.warning_bg,
				.border = .(1, Colors.White),
			}) {
				clay_text(t"Warning({warning.kind as int}): {warning.msg}", {
					.fontSize = rem(1),
					.textColor = Colors.Yellow,
				});
			};
			n++;
		}
	}
}
ProgramWarningLog warning_log = {};

void warn(ProgramWarningKind kind, char^ msg) {
	ProgramWarning warning = .(kind, strdup(msg));

	println(t"[Program-Warning]: {msg}");
	warning_log.shown_warnings.add(warning);
}

