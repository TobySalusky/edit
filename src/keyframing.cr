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

		panic(t"UNKNOWN configuration for InterpolateModed: {from_out as int=} {to_in as int=}");
		return 0;
	}
}

struct KeyframeInterpolator<T> { }
struct KeyframeInterpolator=<bool> {
	static bool Interpolate(Keyframe<bool>& from, Keyframe<bool>& to, float t) {
		return from.value;
	}
	static bool DefaultValue() -> false;
	static void SerializeValue(Keyframe<bool>& keyframe, yaml_serializer& s) {
		s.bool_default(keyframe.value, "value", DefaultValue());
	}
	static void delete(Keyframe<bool>& keyframe) {}
}

struct KeyframeInterpolator=<char^> {
	static char^ Interpolate(Keyframe<char^>& from, Keyframe<char^>& to, float t) {
		return from.value;
	}
	static char^ DefaultValue() -> "";
	static void SerializeValue(Keyframe<char^>& keyframe, yaml_serializer& s) {
		s.str_default(keyframe.value, "value", DefaultValue());
	}
	static void delete(Keyframe<char^>& keyframe) {
		free(keyframe.value);
	}
}

struct KeyframeInterpolator=<float> {
	static float Interpolate(Keyframe<float>& from, Keyframe<float>& to, float t) {
		float pt = InterpolationFns.InterpolateModed(t, from.out_interpolation_mode, to.in_interpolation_mode);
		return from.value * (1.0 - pt) + to.value * pt;
	}
	static float DefaultValue() -> 0;
	static void SerializeValue(Keyframe<float>& keyframe, yaml_serializer& s) {
		s.float_default(keyframe.value, "value", DefaultValue());
	}
	static void delete(Keyframe<float>& keyframe) {}
}

struct KeyframeInterpolator=<Vec2> {
	static Vec2 Interpolate(Keyframe<Vec2>& from, Keyframe<Vec2>& to, float t) {
		float pt = InterpolationFns.InterpolateModed(t, from.out_interpolation_mode, to.in_interpolation_mode);
		return from.value.scale(1.0 - pt) + to.value.scale(pt);
	}
	static Vec2 DefaultValue() -> {};
	static void SerializeValue(Keyframe<Vec2>& keyframe, yaml_serializer& s) {
		s.Vec2_default(keyframe.value, "value", DefaultValue());
	}
	static void delete(Keyframe<Vec2>& keyframe) {}
}

struct KeyframeInterpolator=<int> {
	static int Interpolate(Keyframe<int>& from, Keyframe<int>& to, float t) {
		float pt = InterpolationFns.InterpolateModed(t, from.out_interpolation_mode, to.in_interpolation_mode);
		return from.value + (((to.value - from.value) as float) * pt) as int;
	}
	static int DefaultValue() -> 0;
	static void SerializeValue(Keyframe<int>& keyframe, yaml_serializer& s) {
		s.int_default(keyframe.value, "value", DefaultValue());
	}
	static void delete(Keyframe<int>& keyframe) {}
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
	static Color DefaultValue() -> { .r = 0, .g = 0, .b = 0, .a = 255 };
	static void SerializeValue(Keyframe<Color>& keyframe, yaml_serializer& s) {
		s.Color_default(keyframe.value, "value", DefaultValue());
	}
	static void delete(Keyframe<Color>& keyframe) {}
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

	void BiSerialize(yaml_serializer& s) {
		s.float_default(time, "time", 0);
		KeyframeInterpolator<T>.SerializeValue(this, s);

		if (s.is_load) {
			in_interpolation_mode = s.obj.get_int("in_interpolation_mode") as KeyframeInterpolationMode;
			out_interpolation_mode = s.obj.get_int("out_interpolation_mode") as KeyframeInterpolationMode;
		} else {
			s.obj.put_int("in_interpolation_mode", in_interpolation_mode as int);
			s.obj.put_int("out_interpolation_mode", out_interpolation_mode as int);
		}
	}

	yaml_object Serialize() {
		yaml_object obj = {};
		let s = yaml_serializer.Obj(obj, false);
		BiSerialize(s);
		return obj;
	}

	static Self Deserialize(yaml_serializer& s) {
		Self keyframe;
		keyframe.BiSerialize(s);
		return keyframe;
	}

	void delete() {
		KeyframeInterpolator<T>.delete(this);
	}

	KeyframeAssets& assets() -> match (in_interpolation_mode) {
		.Linear -> match (out_interpolation_mode) {
			.Linear -> KeyframeAssets.ll,
			.Ease -> KeyframeAssets.ls,
			else -> KeyframeAssets.ll
		},
		.Ease -> match (out_interpolation_mode) {
			.Linear -> KeyframeAssets.sl,
			.Ease -> KeyframeAssets.ss,
			else -> KeyframeAssets.ll
		},
		else -> KeyframeAssets.ll
	};
}

struct KeyframeAssets {
	Texture outline;
	Texture front;
	Texture highlight;

	construct(char^ path_til_index_and_png) -> {
		.outline = rl.LoadTexture(t"{path_til_index_and_png}{1}.png"),
		.front = rl.LoadTexture(t"{path_til_index_and_png}{2}.png"),
		.highlight = rl.LoadTexture(t"{path_til_index_and_png}{0}.png"),
	};

	static KeyframeAssets ll; // linear-linear
	static KeyframeAssets ss; // sine-sine
	static KeyframeAssets sl; // sine-linear
	static KeyframeAssets ls; // linear-sine

	static void LoadAssets() {
		ll = .("assets/keyframes/ll");
		ss = .("assets/keyframes/ss");
		sl = .("assets/keyframes/sl");
		ls = .("assets/keyframes/ls");
	}
}

struct KeyframeLayer<T> {
	List<Keyframe<T>> keyframes = {};
	// bool activated;

	construct() -> { .keyframes = List<Keyframe<T>>() };

	yaml_object Serialize() {
		yaml_object obj = {};
		obj.put_obj("keyframes", ListSerializer<Keyframe<T>>.Serialize(keyframes));
		return obj;
	}

	static Self Deserialize(yaml_serializer& s) {
		let keyframes_s = s.into_obj("keyframes");
		return {
			.keyframes = ListSerializer<Keyframe<T>>.Deserialize(keyframes_s)
		};
	}

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
				keyframes.get(i).delete();
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
		for (let& keyframe in keyframes) { keyframe.delete(); }
		keyframes.delete();
		keyframes = List<Keyframe<T>>();
	}

	void UI(Rectangle rect, float max_elem_time, float curr_local_time) {
		let dimens = rect.dimen();

		#clay({ // TODO: good lsp-support/checking in templates!
			.layout = {
				.sizing = Clay_Sizing.Grow()
			},
		}) {
			for (int i = 0; i != keyframes.size; i++;) {
				let& keyframe = keyframes.get(i);
				float t = keyframe.time / max_elem_time;

				Vec2 offset = v2(dimens.x * t, 0);

				let& assets = keyframe.assets();
				let sizing = Clay_Sizing(rem(1), rem(1));
				bool keyframe_hovered = false;
				#clay({
					.layout = {
						:sizing
					},
					.floating = {
						.attachTo = CLAY_ATTACH_TO_PARENT,
						:offset,
						.attachPoints = {
							.element = CLAY_ATTACH_POINT_CENTER_CENTER,
							.parent = CLAY_ATTACH_POINT_LEFT_CENTER,
						},
					},
					.backgroundColor = Colors.Black,
					.image = Clay_ImageElementConfig(assets.outline)
					// TODO: NOTE: in template .() does not work correctly
				}) {
					keyframe_hovered = Clay.Hovered();
					
					#clay({
						.layout = { .sizing = Clay_Sizing(0, 0) },
					}) {
						#clay({
							.layout = { :sizing },
							.backgroundColor = Colors.Gray,
							.image = Clay_ImageElementConfig(assets.front)
						}) {}
					}

					bool highlight = keyframe_hovered; // TODO: selection highlighting (diff colour, etc)
					if (highlight) {
						#clay({
							.layout = { :sizing },
							.floating = {
								.attachTo = CLAY_ATTACH_TO_PARENT,
								.offset = {},
								.pointerCaptureMode = CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH
							},
							.image = Clay_ImageElementConfig(assets.highlight),
							.backgroundColor = theme.keyframe_hover_highlight,
						}) {}
					}
				}
			}
		}
	}
}
