import theming;
import rl;
import std;
import clay_lib;

struct InterpolationFns {
	// easing function
	static float Linear(float t) -> t;
	static float EaseInOutSine(float t) -> -(Math.cos(Math.PI * t) - 1) / 2;
	static float EaseInSine(float t) -> 1.0 - Math.cos((t * Math.PI) / 2);
	static float EaseOutSine(float t) -> Math.sin((t * Math.PI) / 2);

	static float InterpolateModed(float t, KeyframeInterpolationMode from_out, KeyframeInterpolationMode to_in) {
		// if (from_out is KeyframeInterpolationMode.Linear) { // TODO: crashes lsp
		if (from_out == .Linear && to_in == .Linear) { return Linear(t); }
		if (from_out == .Ease && to_in == .Ease) { return EaseInOutSine(t); }
		if (from_out == .Linear && to_in == .Ease) { return EaseInSine(t); }
		if (from_out == .Ease && to_in == .Linear) { return EaseOutSine(t); }

		panic(t"UNKNOWN configuariotn for InterpolateModed: {from_out as int=} {to_in as int=}");
		return 0;
	}
}

struct KeyframeInterpolator<T> { }
struct KeyframeInterpolator=<float> {
	static float Interpolate(Keyframe<float>& from, Keyframe<float>& to, float t) {
		float pt = InterpolationFns.InterpolateModed(t, from.out_interpolation_mode, to.in_interpolation_mode);
		return from.value * (1.0 - pt) + to.value * pt;
	}
}
struct KeyframeInterpolator=<Vec2> {
	static Vec2 Interpolate(Keyframe<Vec2>& from, Keyframe<Vec2>& to, float t) {
		float pt = InterpolationFns.InterpolateModed(t, from.out_interpolation_mode, to.in_interpolation_mode);
		return from.value.scale(1.0 - pt) + to.value.scale(pt);
	}
}

struct KeyframeInterpolator=<int> {
	static int Interpolate(Keyframe<int>& from, Keyframe<int>& to, float t) {
		float pt = InterpolationFns.InterpolateModed(t, from.out_interpolation_mode, to.in_interpolation_mode);
		return from.value + (((to.value - from.value) as float) * pt) as int;
	}
}

struct KeyframeInterpolator=<Color> {
	static Color Interpolate(Keyframe<Color>& from, Keyframe<Color>& to, float t) {
		float pt = InterpolationFns.InterpolateModed(t, from.out_interpolation_mode, to.in_interpolation_mode);
		return {
			.r = from.value.r + (((to.value.r - from.value.r) as float) * pt) as int,
			.g = from.value.g + (((to.value.g - from.value.g) as float) * pt) as int,
			.b = from.value.b + (((to.value.b - from.value.b) as float) * pt) as int,
			.a = from.value.a + (((to.value.a - from.value.a) as float) * pt) as int,
		};
	}
}

enum KeyframeInterpolationMode {
	Linear,
	Ease,
	;

	bool operator:==(Self other) -> this as int == other as int;
	bool operator:!=(Self other) -> this as int != other as int;
}

struct Keyframe<T> {
	T value;
	float time;
	KeyframeInterpolationMode in_interpolation_mode;
	KeyframeInterpolationMode out_interpolation_mode;
}

struct KeyframeLayer<T> {
	List<Keyframe<T>> keyframes;
	// bool activated;

	construct() -> { .keyframes = List<Keyframe<T>>() };

	bool HasValue() {
		return 
		// activated && 
		keyframes.size > 0;
	}

	Keyframe<T> BestFrom(float time) {
		Keyframe<T> best = keyframes.get(0);
		for (let keyframe in keyframes) {
			if (keyframe.time <= time) {
				best = keyframe;
			}
		}
		return best;
	}

	Keyframe<T> BestTo(float time) {
		for (let keyframe in keyframes) {
			if (keyframe.time > time) {
				return keyframe;
			}
		}
		return keyframes.get(keyframes.size - 1);
	}

	T GetValue(float time) {
		if (!this.HasValue()) { panic("No value! [GetValue]"); }

		Keyframe<T> from = this.BestFrom(time);
		Keyframe<T> to = this.BestTo(time);

		// TODO: skip interpolation when before/after first/last

		float t_range = to.time - from.time;
		if (t_range == 0) { t_range = 1; } // TODO: almost equal to zero?

		float t = (time - from.time) / t_range;
		float it = 1.0 - t;

		return KeyframeInterpolator<T>.Interpolate(from, to, t);
	}

	void Set(T^ setter, float time) {
		if (!this.HasValue()) { return; }

		*setter = this.GetValue(time);
	}

	void Insert(Keyframe<T> frame) {
		for (int i = 0; i != keyframes.size; i++;) {
			if (frame.time == keyframes.get(i).time) {
				keyframes.get(i) = frame;
				return;
			}
		}

		int best = keyframes.size;
		for (int i = 0; i != keyframes.size; i++;) {
			if (frame.time < keyframes.get(i).time) {
				best = i;
				break;
			}
		}
		keyframes.add_at(frame, best);
	}

	void InsertValue(float time, T value) {
		Insert({
			:value,
			:time,
			.in_interpolation_mode = .Linear,
			.out_interpolation_mode = .Linear,
		});
	}

	void Clear() {
		keyframes.delete();
		keyframes = List<Keyframe<T>>();
	}

	void UI(Rectangle rect, float max_elem_time, float curr_local_time) {
		let dimens = rect.dimen();

		#clay({
			.layout = {
				.sizing = Clay_Sizing.Grow()
			},
		}) {
			for (int i = 0; i != keyframes.size; i++;) {
				let keyframe = keyframes.get(i);
				float t = keyframe.time / max_elem_time;

				Vec2 offset = v2(dimens.x * t, 0);

				#clay({
					.layout = {
						.sizing = {
							.width = CLAY_SIZING_FIXED(5),
							.height = CLAY_SIZING_GROW(),
						}
					},
					.floating = {
						.attachTo = CLAY_ATTACH_TO_PARENT,
						:offset,
					},
					.backgroundColor = Colors.Red
				}) {
					// TODO: text (number)
					// d.TextTemp(t"{i}");
				}
			}
		}
	}
}
