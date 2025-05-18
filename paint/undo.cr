import layer_list;
import std;
import theming;
import rl;

interface Undo {
	void Apply(UndoTarget info);
}

struct UndoTarget {
	List<Layer>& layers;
}

List<Undo^> make_undo_list() -> List<Undo^>();

struct MultiUndo : Undo {
	List<Undo^> undos;

	void Apply(UndoTarget info) {
		for (int i = 0; i != undos.size; i++;) {
			undos.get(i)#Apply(info);
		}
	}
}

MultiUndo^ make_MultiUndo() { 
	Box<MultiUndo> it;
	return it.make({
		.undos = make_undo_list()
	});
}

struct ContentUndo : Undo {
	int layer_id;
	Texture content;

	void Apply(UndoTarget info) {
		let rt = get_by_id(info.layers, layer_id).rt;
		rt.Begin();
		d.ClearBackground(transparent);
		d.Texture(content, Vec2_zero);
		rt.End();
	}
}

ContentUndo^ make_ContentUndo(int layer_id, Texture content) { 
	Box<ContentUndo> it;
	return it.make({
		:layer_id, :content
	});
}
