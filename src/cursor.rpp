import std;
import list;
import rl;

enum CursorType {
	Default, Pointer, Crosshair, ResizeVert, ResizeHoriz;

	static List<Texture> cursor_textures = {};

	static void LoadAssets() {
		cursor_textures.add(rl.LoadTexture("assets/cursors/new/default.png"));
		cursor_textures.add(rl.LoadTexture("assets/cursors/new/pointer.png"));
		cursor_textures.add(rl.LoadTexture("assets/cursors/new/crosshair.png"));
		cursor_textures.add(rl.LoadTexture("assets/cursors/new/resize_vert.png"));
		cursor_textures.add(rl.LoadTexture("assets/cursors/new/resize_horiz.png"));
	}

	Texture GetTexture() {
		assert(this as int < cursor_textures.size, "cursor not loaded");
		return cursor_textures.get(this as int);
	}

	bool operator:==(Self other) -> this as int == other as int;
	bool operator:!=(Self other) -> this as int != other as int;
}

CursorType cursor_type = .Default;
