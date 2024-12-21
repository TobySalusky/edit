import pair;

// single slice ---
struct Slice<T> {
	int size;
	T^ data;

	// TODO: operator:[]
	T& get(int i) {
		if (0 > i || i >= size) {
			panic(t"index {i} OOB!");
		}
		return data[i];
	}

	bool is_empty() -> size == 0;

	T& back() {
		return this.get(size - 1);
	}

	// T pop_back() { // TODO: keep?
	// 	defer size--; // NOTE: slice becomes smaller...
	// 	return this.back();
	// }

	Slice_iter<T> iter() -> { .i = 0, .slice = ^this };
}

// TODO: add generics!
struct Slice_iter<T> {
	int i;
	Slice<T>^ slice;
	// T^ valid_for; // NOTE: no validity checking

	bool has_next() {
		return slice#size > i;
	}

	T& next() {
		return slice#get(i++);
	}
}

struct SliceMaker<T> {
	Slice<T> make(int size, T^ data) -> { :size, :data };
}

// index slice ---
struct IndexSlice<T> {
	int size;
	T^ data;

	// TODO: operator:[]
	KeyValuePair<int, T&> get(int i) {
		if (0 > i || i >= size) {
			panic(t"index {i} OOB!");
		}
		return { .key = i, .value = data[i] };
	}

	bool is_empty() -> size == 0;

	KeyValuePair<int, T&> back() {
		return this.get(size - 1);
	}

	// T pop_back() { // TODO: keep?
	// 	defer size--; // NOTE: IndexSlice becomes smaller...
	// 	return this.back();
	// }

	IndexSlice_iter<T> iter() -> { .i = 0, .slice = ^this };
}

// TODO: add generics!
struct IndexSlice_iter<T> {
	int i;
	IndexSlice<T>^ slice;
	// T^ valid_for; // NOTE: no validity checking

	bool has_next() {
		return slice#size > i;
	}

	KeyValuePair<int, T&> next() {
		return slice#get(i++);
	}
}

struct IndexSliceMaker<T> {
	IndexSlice<T> make(int size, T^ data) -> { :size, :data };
}

// zip slice ---
struct ZipSlice<T1, T2> {
	int size;
	T1^ data_1;
	T2^ data_2;

	// TODO: operator:[]
	KeyValuePair<T1&, T2&> get(int i) {
		if (0 > i || i >= size) {
			panic(t"index {i} OOB!");
		}
		return { .key = data_1[i], .value = data_2[i] };
	}

	bool is_empty() -> size == 0;

	KeyValuePair<T1&, T2&> back() {
		return this.get(size - 1);
	}

	// T& pop_back() { // TODO: keep?
	// 	defer size--; // NOTE: ZipSlice becomes smaller...
	// 	return this.back();
	// }

	ZipSlice_iter<T1, T2> iter() -> { .i = 0, .zip_slice = ^this };
}

// TODO: add generics!
struct ZipSlice_iter<T1, T2> {
	int i;
	ZipSlice<T1, T2>^ zip_slice;
	// T^ valid_for; // NOTE: no validity checking

	bool has_next() {
		return zip_slice#size > i;
	}

	KeyValuePair<T1&, T2&> next() {
		return zip_slice#get(i++);
	}
}

struct ZipSliceMaker<T1, T2> {
	ZipSlice<T1, T2> make(int size, T1^ data_1, T2^ data_2) -> { :size, :data_1, :data_2 };
	ZipSlice<T1, T2> make_slice(Slice<T1> slice_1, Slice<T2> slice_2) -> { .size = (slice_1.size > slice_2.size) ? slice_2.size | slice_1.size, .data_1 = slice_1.data, .data_2 = slice_2.data };
}
