import std;
import list;
import rl;

enum CursorType {
	Default, Pointer, Crosshair, ResizeVert, ResizeHoriz, ResizeDiagonalNWSE, ResizeDiagonalNESW, ResizeAll, IBeam;

	MouseCursor _to_raylib_cursor_type() -> match (this) {
		.Default -> MOUSE_CURSOR_DEFAULT,
		.Pointer -> MOUSE_CURSOR_POINTING_HAND,
		.Crosshair -> MOUSE_CURSOR_CROSSHAIR,
		.ResizeVert -> MOUSE_CURSOR_RESIZE_NS,
		.ResizeHoriz -> MOUSE_CURSOR_RESIZE_EW,
		.ResizeDiagonalNWSE -> MOUSE_CURSOR_RESIZE_NWSE,
		.ResizeDiagonalNESW -> MOUSE_CURSOR_RESIZE_NESW,
		.ResizeAll -> MOUSE_CURSOR_RESIZE_ALL,
		.IBeam -> MOUSE_CURSOR_IBEAM,
	};

	MouseCursor into() -> _to_raylib_cursor_type();

	// static List<Texture> cursor_textures = {};
	//
	// static void LoadAssets() {
	// 	cursor_textures.add(rl.LoadTexture("assets/cursors/default.png"));
	// 	cursor_textures.add(rl.LoadTexture("assets/cursors/pointer.png"));
	// 	cursor_textures.add(rl.LoadTexture("assets/cursors/crosshair.png"));
	// 	cursor_textures.add(rl.LoadTexture("assets/cursors/resize_vert.png"));
	// 	cursor_textures.add(rl.LoadTexture("assets/cursors/resize_horiz.png"));
	// 	cursor_textures.add(rl.LoadTexture("assets/cursors/slide_left_right.png"));
	// 	cursor_textures.add(rl.LoadTexture("assets/cursors/textbox.png"));
	// }
	//
	// Texture GetTexture() {
	// 	assert(this as int < cursor_textures.size, "cursor not loaded");
	// 	return cursor_textures.get(this as int);
	// }
}

CursorType cursor_type = .Default;
