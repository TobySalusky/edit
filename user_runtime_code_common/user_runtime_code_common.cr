import recordings;
import std;

struct EditCustomFnParams {
	float lt;

	static SampleRecording<float> the_frec = &{
		SampleRecording<float> it = .Empty(20);
		for n in 0..100 {
			it.data.add(n % 10);
		}

		return it;
	};

	SampleRecording<float> frec(char^ name) {
		if (str_eq(name, "the_frec")) { return the_frec; }
		return .Empty();
	}
}
