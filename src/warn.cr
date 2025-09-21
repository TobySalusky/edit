import rl;
import std;
import clay_lib;
import ui_elements;
import theming;

enum ProgramWarningKind {
	__BEGIN_WARNINGS, // =================================================

	MISSING_PROJECT,
	MISSING_COMPOSITION,
	MISSING_LAYER_IN_COMPOSITION,
	EXTERNAL_HOT_RELOADING,
	MISC,
	LOADER_FAILURE,

	__BEGIN_TODOS, // =================================================

	TODO, // MISC
	TODO_BETTER_PROJECT_CLOSING,

	DEBUG, // =================================================
	;
}

struct ProgramWarning {
	ProgramWarningKind kind;
	char^ msg; // malloced! (strdup-ed)
	double time_issued;
	double last_time_issued; // sorted by this :)
	int num_repetitions; // 1 means this is the only one!

	construct(ProgramWarningKind kind, char^ msg) -> 
		with let time = rl.GetTime() in
	{
		:kind,
		:msg,
		.time_issued = time,
		.last_time_issued = time,
		.num_repetitions = 1,
	};
}

struct ProgramWarningLog {
	ProgramWarning[] shown_warnings = {};
	ProgramWarning[] ignored_warnings = {};

	static float max_warning_display_time = 2;
	static float animation_time = 0.2;

	void Update() {
		float width = 400;
		float padding = 20;

		float time = rl.GetTime();

		while (!shown_warnings.is_empty() && shown_warnings.front().last_time_issued < (time - max_warning_display_time)) {
			shown_warnings.pop_front();
		}

		float offset_y = 0;

		for (int i = shown_warnings.size - 1; i >= 0; i--) {
			let& warning = shown_warnings[i];
			float animation_slide_by = 0;
			if ((time - warning.time_issued) < animation_time) {
				float inverted_p = 1.0 - ((time - warning.time_issued) / animation_time);
				// animation_slide_by = (InterpolationFns.EaseInSine(inverted_p)) * (padding + width);
			} else if ((time - warning.last_time_issued) > (max_warning_display_time - animation_time)) {
				float p = ((time - warning.last_time_issued) - (max_warning_display_time - animation_time)) / animation_time;
				animation_slide_by = (InterpolationFns.EaseOutSine(p)) * (padding + width);
			}

			Clay_ElementId id = .(t"{^warning}");
			offset_y -= padding + Clay.GetBoundingBox(id).height;

			$clay({
				:id,
				.floating = {
					.attachTo = CLAY_ATTACH_TO_ROOT,
					.zIndex = 999,
					.attachPoints = {
						.element = CLAY_ATTACH_POINT_RIGHT_TOP,
						.parent = CLAY_ATTACH_POINT_RIGHT_BOTTOM,
					},
					.offset = { -padding + animation_slide_by, offset_y },
				},
				.layout = {
					.sizing = { .width = CLAY_SIZING_FIXED(width) }
				},
				.backgroundColor = theme.warning_bg,
				.border = .(1, Colors.White),
			}) {
				char^ prelude;
				if (warning.kind == .DEBUG) {
					prelude = "DEBUG";
				} else if ((warning.kind as c:int) > ProgramWarningKind.__BEGIN_TODOS) {
					prelude = t"TODO({warning.kind.name()})";
				} else {
					prelude = t"Warning({warning.kind.name()})";
				}
				clay_text(t"{prelude}{
						(warning.num_repetitions > 1)
							? ((warning.num_repetitions > 999)
								? " x999+"
								| t" x{warning.num_repetitions}")
							| ""
				}: {warning.msg}", {
					.fontSize = rem(1),
					.textColor = Colors.Yellow,
				});
			};
		}
	}
}
ProgramWarningLog warning_log = {};

void dbg(char^ msg) {
	warn(.DEBUG, msg);
}

void todo(char^ msg) {
	warn(.TODO, msg);
}

void warn(ProgramWarningKind kind, char^ msg = "") {
	println(t"[Program-Warning({kind.name()})]: {msg}");

	bool found = false;
	ProgramWarning warning;

	// if this exact warning is still being shown, just increment it's count and
	for (int i in 0..warning_log.shown_warnings.size) {
		let& w = warning_log.shown_warnings[i];
		if (kind == w.kind && str_eq(msg, w.msg)) {
			warning = warning_log.shown_warnings.remove_at(i);
			warning.num_repetitions++;
			warning.last_time_issued = rl.GetTime();
			found = true;
			break;
		}
	}
	
	if (!found) {
		warning = .(kind, strdup(msg));
	}

	warning_log.shown_warnings.add(warning);
}

