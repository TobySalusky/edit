import std;

struct Hasher<T> {
	ulong hash(T& val) -> val.hash();
	bool eq(T& val, T& other) -> val == other;
}

struct Hasher=<char> { ulong hash(char& val) -> val as..; bool eq(char& val, char& other) -> val == other; }
struct Hasher=<short> { ulong hash(short& val) -> val as..; bool eq(short& val, short& other) -> val == other; }
struct Hasher=<int> { ulong hash(int& val) -> val as..; bool eq(int& val, int& other) -> val == other; }
struct Hasher=<long> { ulong hash(long& val) -> val as..; bool eq(long& val, long& other) -> val == other; }
struct Hasher=<uchar> { ulong hash(uchar& val) -> val as..; bool eq(uchar& val, uchar& other) -> val == other; }
struct Hasher=<ushort> { ulong hash(ushort& val) -> val as..; bool eq(ushort& val, ushort& other) -> val == other; }
struct Hasher=<uint> { ulong hash(uint& val) -> val as..; bool eq(uint& val, uint& other) -> val == other; }
struct Hasher=<ulong> { ulong hash(ulong& val) -> val as..; bool eq(ulong& val, ulong& other) -> val == other; }

struct Hasher=<char^> {
	ulong hash(char^& val) { // djb2 string hash algorithm!
		char^ str = val;

        ulong hash_val = 5381;
        while (true) {
			char c = *str;
			if (c == '\0') { break; }
            hash_val = ((hash_val << 5) + hash_val) + c; // hash_val * 33 + c

			str++;
        }
        return hash_val;
	}

	bool eq(char^& val, char^& other) -> str_eq(val, other);
}

struct HashMapEntry<K, V> {
	K key;
	V value;
	bool is_occupied = false;
	bool is_deleted = false;
}

struct HashMap<K, V> {
	construct(int capacity = 8) {
		HashMapEntry<K, V>[] table = .();
		table.zeroed_increase_size_to(capacity);

		return {
			:capacity,
			.size = 0,
			:table,
			.hasher = {}
		};
	}

	HashMapIterator<K, V> iter() -> {
		.i = 0,
		.hash_map = ^this,
	};

	// NOTE: does copy... should it? const& in future......?
	// V& operator:[](K key) -> a;

	Hasher<K> hasher;
	HashMapEntry<K, V>[] table;
    int capacity;
    int size;

	void delete() {
		table.delete();
	}

    void resize() {
        int new_capacity = std.maxi(1, capacity * 2);
        HashMapEntry<K, V>[] new_table = {};
		new_table.zeroed_increase_size_to(new_capacity);
        for (let& entry in table) {
            if (entry.is_occupied && !entry.is_deleted) {
                int idx = hasher.hash(entry.key) % new_capacity; // TODO: ?
                while (new_table[idx].is_occupied) {
                    idx = (idx + 1) % new_capacity;
                }
                new_table[idx] = entry;
            }
        }
		table.delete();
        table = new_table;
        capacity = new_capacity;
    }

    void insert(K key, V value) {
        if (size >= capacity / 2) {
            resize();
        }
        int idx = hasher.hash(key) % capacity;
        while (table[idx].is_occupied && !table[idx].is_deleted && table[idx].key != key) {
            idx = (idx + 1) % capacity;
        }
        if (!table[idx].is_occupied || table[idx].is_deleted) {
            table[idx].key = key;
            table[idx].value = value;
            table[idx].is_occupied = true;
            table[idx].is_deleted = false;
            ++size;
        } else {
            table[idx].value = value;
        }
    }

    bool has(K key) -> get_ptr(key) != NULL;

    V& get(K key) {
        int idx = hasher.hash(key) % capacity;
        while (table[idx].is_occupied) {
            if (!table[idx].is_deleted && hasher.eq(table[idx].key, key)) {
                return table[idx].value;
            }
            idx = (idx + 1) % capacity;
        }
		panic("HashMap.get() failed to find key!");
		V a;
        V& awkward = a;
		return awkward;
    }

    V&? get_opt_ref(K key) {
        let ptr = get_ptr(key);
		if (ptr == NULL) { return none; }
		V& ref = *ptr;
		return ref;
    }

    V? get_opt(K key) {
        let ptr = get_ptr(key);
		if (ptr == NULL) { return none; }
		return *ptr;
    }

    V^ get_ptr(K key) {
        int idx = hasher.hash(key) % capacity;
        while (table[idx].is_occupied) {
            if (!table[idx].is_deleted && hasher.eq(table[idx].key, key)) {
                return ^table[idx].value;
            }
            idx = (idx + 1) % capacity;
        }
		return NULL;
    }

    void remove(K key) {
        int idx = hasher.hash(key) % capacity;
        while (table[idx].is_occupied) {
            if (!table[idx].is_deleted && hasher.eq(table[idx].key, key)) {
                table[idx].is_deleted = true;
                size--;
                return;
            }
            idx = (idx + 1) % capacity;
        }
    }
}

struct HashMapIterator<K, V> {
	int i;
	HashMap<K, V>^ hash_map;

	bool has_next() {
		for (; (i) < hash_map#table.size; i++) {
			if (hash_map#table[i].is_occupied && !hash_map#table[i].is_deleted) { return true; }
		}
		return false;
	}

	HashMapEntryRef<K, V> next() {
		defer i++;

		return {
			.value = hash_map#table[i].value,
			.key = hash_map#table[i].key,
		};
	}
}

struct HashMapEntryRef<K, V> {
	K& key;
	V& value;
}


// struct HashSet<T> {
// 	HashSet<KeyValuePair<K, V>> impl;
// }
