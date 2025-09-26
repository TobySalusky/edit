import std;
import warn;
import tcc;

struct CustomFnID {
	int index;
}

struct CustomFnEntry {
	void^ fn;
	TCCState^ tcc;
	// TODO: type descriminator?
}

struct CustomFns {
	CustomFnEntry[] entries = {};

	void^ get_fn(CustomFnID id) {
		return (id.index >= 0 && id.index < entries.size) ? entries[id.index].fn | NULL;
	}

	void set(CustomFnID id, CustomFnEntry entry) {
		if (!(id.index >= 0 && id.index < entries.size)) { return warn(.MISC, "CustomFns.set() OOB"); }

		let old_tcc = entries[id.index].tcc;
		if (old_tcc) {
			old_tcc#delete();
		}

		entries[id.index] = entry;
	}

	CustomFnID register() {
		entries.zeroed_increase_size_to(entries.size + 1);
		return { .index = entries.size - 1 };
	}
}
