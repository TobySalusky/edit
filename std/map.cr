import pair;

// NOTE: StrMap operations are currently O(n), it just provides the API of a dictionary/hashmap, but with a simple flat list-of-pairs implementation
struct StrMap<T> {
	int capacity = 0;
	int size = 0;

	char^^ keys = NULL;
	T^ values = NULL;

	construct() -> { .size = 0, .capacity = 0, .keys = NULL, .values = NULL };

	bool has(char^ key) {
		for (int i = 0; i != size; i++) {
			if (str_eq(key, keys[i])) {
				return true;
			}
		}
		return false;
	}

	// TODO: operator:[]
	T& get(char^ key) {
		for (int i = 0; i != size; i++) {
			if (str_eq(key, keys[i])) {
				return values[i];
			}
		}
		panic(t"key '{key}' not found in StrMap!");
		return values[0]; // never executed, we need @noreturn
	}

	int index_of(char^ key) {
		for (int i = 0; i != size; i++) {
			if (str_eq(key, keys[i])) {
				return i;
			}
		}
		return -1;
	}

	void put_unique(char^ key, T value) {
		if (this.has(key)) {
			panic(t"StrMap put_unique called with duplicate key: '{key}'");
		}
		this.put(key, value);
	}

	void put(char^ key, T value) {
		int index_of_key = this.index_of(key);
		if (index_of_key != -1) {
			values[index_of_key] = value;
			return;
		}

		if (size == capacity) {
			this.set_capacity((capacity == 0) ? 1 | capacity * 2);
		}
		
		keys[size] = strdup(key);
		values[size] = value;

		size++;
	}

	void set_capacity(int new_capacity) {
		char^^ old_keys = keys;
		T^ old_data = values;
		if (new_capacity != 0) {
			keys = malloc(sizeof<char^> * new_capacity);
			values = malloc(sizeof<T> * new_capacity);

			for (int i = 0; i != size; i++) {
				keys[i] = old_keys[i];
				values[i] = old_data[i];
			}
		}

		if (capacity != 0) {
			free(old_keys);
			free(old_data);
		}
		capacity = new_capacity;
	}

	void delete() {
		if (capacity > 0) {
			for (int i = 0; i != size; i++) {
				free(keys[i]); // keys are owned, so must be freed!
			}
			free(keys);
			free(values);
		}
	}

	bool is_empty() -> size == 0;

	StrMap_iter<T> iter() -> {
		.i = 0,
		.map = ^this
	};
}

struct StrMap_iter<T> {
	int i;
	StrMap<T>^ map;

	bool has_next() -> map#size > i;

	KeyValuePair<char^, T> next() {
		defer i++;
		return {
			.key = map#keys[i],
			.value = map#values[i]
		};
	}
}

// requires (K: Eq)
struct EqMap<K, V> {
	int capacity;
	int size;

	K^ keys;
	V^ values;

	construct() -> { .size = 0, .capacity = 0, .keys = NULL, .values = NULL };

	bool has(K key) {
		for (int i = 0; i != size; i++) {
			if ((key == keys[i])) {
				return true;
			}
		}
		return false;
	}

	// TODO: operator:[]
	V& get(K key) {
		for (int i = 0; i != size; i++) {
			if ((key == keys[i])) {
				return values[i];
			}
		}
		panic(t"key not found in EqMap!");
		// panic(t"key '{key}' not found in EqMap!");
		return values[0]; // never executed, we need @noreturn
	}

	int index_of(K key) {
		for (int i = 0; i != size; i++) {
			if ((key == keys[i])) {
				return i;
			}
		}
		return -1;
	}

	void put_unique(K key, V value) {
		if (this.has(key)) {
			panic(t"EqMap put_unique called with duplicate key: ");
			// panic(t"EqMap put_unique called with duplicate key: '{key}'");
		}
		this.put(key, value);
	}

	void put(K key, V value) {
		int index_of_key = this.index_of(key);
		if (index_of_key != -1) {
			values[index_of_key] = value;
			return;
		}

		if (size == capacity) {
			this.set_capacity((capacity == 0) ? 1 | capacity * 2);
		}
		
		keys[size] = key;
		values[size] = value;

		size++;
	}

	void set_capacity(int new_capacity) {
		K^ old_keys = keys;
		V^ old_data = values;
		if (new_capacity != 0) {
			keys = malloc(sizeof<K> * new_capacity);
			values = malloc(sizeof<V> * new_capacity);

			for (int i = 0; i != size; i++) {
				keys[i] = old_keys[i];
				values[i] = old_data[i];
			}
		}

		if (capacity != 0) {
			free(old_keys);
			free(old_data);
		}
		capacity = new_capacity;
	}

	void delete() {
		if (capacity > 0) {
			// TODO: delete children if needed?
			// for (int i = 0; i != size; i++) {
			// 	// free(keys[i]); // keys are owned, so must be freed!
			// }
			free(keys);
			free(values);
		}
	}

	bool is_empty() -> size == 0;

	EqMap_iter<K, V> iter() -> {
		.i = 0,
		.map = ^this
	};
}

struct EqMap_iter<K, V> {
	int i;
	EqMap<K, V>^ map;

	bool has_next() -> map#size > i;

	KeyValuePair<K, V> next() {
		defer i++;
		return {
			.key = map#keys[i],
			.value = map#values[i]
		};
	}
}
