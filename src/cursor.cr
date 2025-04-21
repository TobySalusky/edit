import std;
import list;
import rl;

enum CursorType {
	Default, Pointer, Crosshair, ResizeVert, ResizeHoriz, SlideLeftRight, Textbox;

	static List<Texture> cursor_textures = {};

	static void LoadAssets() {
		cursor_textures.add(rl.LoadTexture("assets/cursors/default.png"));
		cursor_textures.add(rl.LoadTexture("assets/cursors/pointer.png"));
		cursor_textures.add(rl.LoadTexture("assets/cursors/crosshair.png"));
		cursor_textures.add(rl.LoadTexture("assets/cursors/resize_vert.png"));
		cursor_textures.add(rl.LoadTexture("assets/cursors/resize_horiz.png"));
		cursor_textures.add(rl.LoadTexture("assets/cursors/slide_left_right.png"));
		cursor_textures.add(rl.LoadTexture("assets/cursors/textbox.png"));
	}

	Texture GetTexture() {
		assert(this as int < cursor_textures.size, "cursor not loaded");
		return cursor_textures.get(this as int);
	}

	bool operator:==(Self other) -> this as int == other as int;
	bool operator:!=(Self other) -> this as int != other as int;
}

CursorType cursor_type = .Default;
