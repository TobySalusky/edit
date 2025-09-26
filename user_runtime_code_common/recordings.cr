import std;
import list;

struct SampleRecording<T> {
	// 1; // TODO: should be syntax error, even when not instantiated!

	T[] data;
	float sample_time; // usually high; eg: 1/60 or 1/30
	// TODO: interpolate for wider sample_times?

	static Self Empty(float samples_per_sec = 60) -> {
		.data = {},
		.sample_time = 1.0 / samples_per_sec,
	};

	T operator:()(float t) { // hold first/last when OOB; return default value if empty
		if (data.is_empty()) {
			// TODO: #if T.is_default_constructable
			// return .0;
			return ---;
		}
		int i = (t <= 0) 
			? 0
			| std.mini((t / sample_time) as int, data.size - 1);

		return data[i];
	}
}

// [f, v, b, i, c, s]
// frec() : float
// v2rec() : vec2
// v3rec() : vec3
// brec() : bool
// irec() : int
// crec() : color
// srec() : string
// rec<T>() : T (custom)

// SampleRecording<Vec2> blah_TODO_DELETE;
