import std;
import rl;
import list;

c:c:`
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wincompatible-pointer-types-discards-qualifiers"
`;

struct Layer {
	RenderTexture rt;
	int id;

	int width;
	int height;

	void delete() {
		rt.delete();
	}
}

int next_layer_id = 0;
Layer make_layer(int width, int height) -> Layer{
	.id = next_layer_id++,
	.rt = make_render_texture(width, height),
	:width,
	:height,
};

Layer& get_by_id(List<Layer>& layer_list, int id) {
	for (int i = 0; i != layer_list.size; i++) {
		if (layer_list.data[i].id == id) {
			return layer_list.data[i];
		}
	}
	panic(t"get_by_id failed: id DNE");
	Layer fake;
	Layer^ fake_p = Box<Layer>{}.make(fake); return *fake_p; // unreachable
}

List<Layer> Make_List_Layer() {
	return {
		.capacity = 0,
		.size = 0,
		.data = c:NULL
	};
}

c:c:`
#pragma GCC diagnostic pop
`;
