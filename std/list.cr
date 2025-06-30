import slice;

struct List<T> {
	int capacity = 0;
	int size = 0;
	T^ data = NULL;

	construct() -> {
		.capacity = 0,
		.size = 0,
		.data = NULL
	};

	static Self Reserved(int n) {
		Self res = .(); // TODO(cr): TODO: why was i getting an error here?? (can i not use own constructor in static fn!!)
		res.reserve(n);
		return res;
	}

	Slice<T> to_slice() -> { :data, :size };

	IndexSlice<T> pairs() -> { :data, :size };

	T& operator:[](int i) {
		if (0 > i || i >= size) {
			panic(t"index {i} OOB!");
		}
		return data[i];
	}

	T& get(int i) -> this[i];

	void add(T elem) {
		if (size == capacity) {
			set_capacity((capacity == 0) ? 1 | capacity * 2);
		}
		
		data[size] = elem;

		size++;
	}

	T remove_at(int at_index) {
		if (0 > at_index || at_index >= size) {
			panic(t"remove_at: index {at_index} OOB!");
		}
		T elem = data[at_index];

		for (int i = at_index; size > i; i++) {
			data[i] = data[i + 1];
		}

		size--;

		return elem;
	}

	void add_at(T elem, int at_index) {
		if (size == capacity) {
			set_capacity((capacity == 0) ? 1 | capacity * 2);
		}

		for (int i = size; i > at_index; i--) {
			data[i] = data[i - 1];
		}
		
		data[at_index] = elem;

		size++;
	}

	Self copy() -> {
		:size,
		.capacity = size,
		.data = std.cloned_bytes(data, size * sizeof<T>),
	};

	void set_capacity(int new_capacity) {
		T^ old_data = data;
		if (new_capacity != 0) {
			data = malloc(sizeof<T> * new_capacity);

			for (int i = 0; i != size; i++) {
				data[i] = old_data[i];
			}
		}

		if (capacity != 0) {
			free(old_data);
		}
		capacity = new_capacity;
	}

	void reserve(int new_capacity) {
		if (new_capacity <= capacity) {
			return;
		}
		set_capacity(new_capacity);
	}

	void zeroed_increase_size_to(int new_size) {
		reserve(new_size);
		memset(^data[size] as void^, 0, (new_size - size) * sizeof<T>);
		size = new_size;
	}

	void delete() {
		if (capacity > 0) {
			free(data);
		}
	}

	void clear() {
		size = 0;
	}

	bool is_empty() -> size == 0;

	T& front() -> this[0];

	T pop_front() {
		T res = get(0);
		remove_at(0);

		return res;
	}

	T& back() -> this[size - 1];

	T pop_back() {
		defer size--;
		return back();
	}

	List_iter<T> iter() -> { .i = 0, .list = ^this, .valid_for = data };

	// sorts -------------------------

	// TODO: use binary search for insertion!
	void insert_ordered_by(T val, fn_ptr<int(T&, T&)> comparator) { // presumes list is sorted!
		int desired_i = 0;
		for (int i = 0; (i) < size; i++) {
			if (comparator(val, this[i]) < 0) { break; }
			desired_i++;
		}
		add_at(val, desired_i);
	}

	void insert_ordered_by_user_data(T val, fn_ptr<int(T&, T&, void^)> comparator, void^ user_data) { // presumes list is sorted!
		int desired_i = 0;
		for (int i = 0; (i) < size; i++) {
			if (comparator(val, this[i], user_data) < 0) { break; }
			desired_i++;
		}
		add_at(val, desired_i);
	}
	// void insertion_sort_by(fn_ptr<int(T&, T&)> comparator) {
	// 	
	// }
}

// TODO: add generics!
struct List_iter<T> {
	int i;
	List<T>^ list;
	T^ valid_for;

	bool has_next() {
		check_valid();
		return list#size > i;
	}

	T& next() {
		check_valid();
		return list#get(i++);
	}

	void check_valid() {
		if (list#data != valid_for) {
			panic(t"List_iter invalidated during use, did you modify the referenced list?");
		}
	}
}
