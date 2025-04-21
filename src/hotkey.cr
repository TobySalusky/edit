import std;
import rl;

struct Env {
	static bool is_dvorak = c:getenv("SILLY_DVORAK_USER") != NULL;

	static void DebugPrint() {
		if (is_dvorak) { println("Setting keyboard to Dvorak (via env var)"); }
	}
}

c:`
// avoid cyclic import w/ ui_elements.cr
extern bool NoTextInputFocused(void);
`;

struct HotKey {
	int key_code;
	// TODO: modifiers

	bool IsPressed() -> (c:NoTextInputFocused() as bool) && key.IsPressed(key_code);

	static Self DvoKey(int keycode_qwerty, int keycode_dvorak) -> {
		.key_code = Env.is_dvorak ? keycode_dvorak | keycode_qwerty 
	};
	static Self Key(int keycode) -> Self.DvoKey(keycode, keycode);
}

struct HotKeys {
	// :hotkey

	static HotKey PlayPause = HotKey.Key(KEY.SPACE);

	static HotKey Mute = HotKey.Key(KEY.M);

	static HotKey ExportMovie = HotKey.DvoKey(KEY.E, KEY.D);
	static HotKey ImportMovie = HotKey.DvoKey(KEY.I, KEY.G);

	static HotKey ClayDebugToggle = HotKey.DvoKey(KEY.D, KEY.H);

	// key as in keyframe
	static HotKey KeyAtCurrentPosition  = HotKey.DvoKey(KEY.K, KEY.V);

	static HotKey QuickAdd = HotKey.DvoKey(KEY.A, KEY.A);

	static HotKey ToggleHideUIFullscreenPlayback  = HotKey.DvoKey(KEY.H, KEY.J);

	static HotKey QuickCut = HotKey.DvoKey(KEY.B, KEY.N); // contextual delete? like blender? // AT LEAST: remove Keys at current pos?

	static HotKey OpenProject = HotKey.DvoKey(KEY.O, KEY.S);
	static HotKey SaveProject = HotKey.DvoKey(KEY.S, KEY.SEMICOLON);

	static HotKey DeleteSelection = HotKey.Key(KEY.BACKSPACE);
	static HotKey ESCAPE = HotKey.Key(KEY.ESCAPE); // just to be able to re-bind escape as a user, basically

	// :hotkey:temp
	static HotKey Temp_AddFaceElem = HotKey.DvoKey(KEY.F, KEY.Y);

	static HotKey Temp_ClearTimeline = HotKey.DvoKey(KEY.C, KEY.I);
	static HotKey Temp_DeleteElement = HotKey.DvoKey(KEY.X, KEY.B);
	static HotKey Temp_ReloadCode = HotKey.DvoKey(KEY.R, KEY.O); // TODO: make this do something else -- since we reload?

	// static HotKey Temp_AddElementCircle = HotKey.DvoKey(KEY.O, KEY.S);

	static HotKey Temp_AddElementCool = HotKey.DvoKey(KEY.N, KEY.L);
}
