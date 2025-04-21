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

	// TODO: operator:[]
	T& get(int i) {
		if (0 > i || i >= size) {
			panic(t"index {i} OOB!");
		}
		return data[i];
	}

	void add(T elem) {
		if (size == capacity) {
			this.set_capacity((capacity == 0) ? 1 | capacity * 2);
		}
		
		data[size] = elem;

		size++;
	}

	T remove_at(int at_index) {
		if (0 > at_index || at_index >= size) {
			panic(t"remove_at: index {at_index} OOB!");
		}
		T elem = data[at_index];

		for (int i = at_index; size > i; i++;) {
			data[i] = data[i + 1];
		}

		size--;

		return elem;
	}

	void add_at(T elem, int at_index) {
		if (size == capacity) {
			this.set_capacity((capacity == 0) ? 1 | capacity * 2);
		}

		for (int i = size; i > at_index; i--;) {
			data[i] = data[i - 1];
		}
		
		data[at_index] = elem;

		size++;
	}

	void set_capacity(int new_capacity) {
		T^ old_data = data;
		if (new_capacity != 0) {
			data = c:malloc(sizeof<T> * new_capacity);

			for (int i = 0; i != size; i++;) {
				data[i] = old_data[i];
			}
		}

		if (capacity != 0) {
			c:free(old_data);
		}
		capacity = new_capacity;
	}

	void reserve(int capacity) {
		if (capacity <= this.capacity) {
			return;
		}
		this.set_capacity(capacity);
	}

	void delete() {
		if (capacity > 0) {
			c:free(data);
		}
	}

	bool is_empty() -> size == 0;

	T& front() {
		return this.get(0);
	}

	T pop_front() {
		T res = this.get(0);
		remove_at(0);

		return res;
	}

	T& back() {
		return this.get(size - 1);
	}

	T pop_back() {
		defer size--;
		return this.back();
	}

	List_iter<T> iter() -> { .i = 0, .list = ^this, .valid_for = data };
}

// TODO: add generics!
struct List_iter<T> {
	int i;
	List<T>^ list;
	T^ valid_for;

	bool has_next() {
		this.check_valid();
		return list#size > i;
	}

	T& next() {
		this.check_valid();
		return list#get(i++);
	}

	void check_valid() {
		if (list#data != valid_for) {
			panic(t"List_iter invalidated during use, did you modify the referenced list?");
		}
	}
}
