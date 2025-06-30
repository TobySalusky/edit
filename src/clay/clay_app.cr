// main loop -- using clay!
import std;
import rl;
import hotkey;

import clay_lib;

import global_settings;

bool debugEnabled = false;
bool reinitializeClay = false;

struct ScrollbarData
{
    Vec2 clickOrigin = {}; // TODO: re-work
    Vec2 positionOrigin = {};
    bool mouseDown = false;
}

@no_hr
ScrollbarData scrollbarData = {};

void HandleClayErrors(Clay_ErrorData errorData) {
    println(t"{errorData.errorText.chars}");
    if (errorData.errorType == CLAY_ERROR_TYPE_ELEMENTS_CAPACITY_EXCEEDED) {
        reinitializeClay = true;
        Clay.SetMaxElementCount(Clay.GetMaxElementCount() * 2);
    } else if (errorData.errorType == CLAY_ERROR_TYPE_TEXT_MEASUREMENT_CAPACITY_EXCEEDED) {
        reinitializeClay = true;
        Clay.SetMaxMeasureTextCacheWordCount(Clay.GetMaxMeasureTextCacheWordCount() * 2);
    } else if (errorData.errorType == CLAY_ERROR_TYPE_INTERNAL_ERROR) {
		println("[CLAY INTERNAL ERROR]: ...crashing on purpose to debug with GDB!");
		char^ v_ptr = NULL;
		*v_ptr = 'a';
	} else {
		panic(t"HandleClayErrors - unhandled case! {errorData.errorType as c:int as int}");
	}
}

c:`typedef void (*EditClayAppMainLoopUpdateFn)(void);`;

struct EditClayApp {
	static ulong totalMemorySize;
	static Clay_Arena clayMemory;
	static Clay_ErrorHandler error_handler;
	static List<Font> fonts = .();

	static void Init(int window_width, int window_height, char^ name) {
		totalMemorySize = Clay.MinMemorySize();
		clayMemory = Clay.CreateArenaWithCapacityAndMemory(totalMemorySize);
		error_handler = { HandleClayErrors, NULL };

		// TODO: logging config by flag?
		// rl.SetTraceLogLevel(c:LOG_WARNING ~| c:LOG_ERROR);  // Log flags? -- comment out to see if I/O or shader stuff is working!
		// NOTE: removed - c:FLAG_WINDOW_HIGHDPI  (believe it was causing windows issues)
		Clay.Raylib_Initialize(window_width, window_height, name, c:FLAG_VSYNC_HINT ~| c:FLAG_WINDOW_RESIZABLE ~| c:FLAG_MSAA_4X_HINT);
		Clay.Initialize(clayMemory, Clay_Dimensions{ rl.GetScreenWidth() as float, rl.GetScreenHeight() as float }, error_handler);

		// fonst.get(FONT_ID_BODY_24)
		fonts.add(c:LoadFontEx("assets/fonts/Roboto-Regular.ttf", 48, NULL, 0));
		c:SetTextureFilter(fonts.get(0).texture, c:TEXTURE_FILTER_BILINEAR);
		// fonst.get(FONT_ID_BODY_16)
		fonts.add(c:LoadFontEx("assets/fonts/Roboto-Regular.ttf", 32, NULL, 0));
		c:SetTextureFilter(fonts.get(1).texture, c:TEXTURE_FILTER_BILINEAR);
		void^^ user_ptr_arr = malloc(sizeof<void^> * 2);
		int^ font_count_ptr = malloc(sizeof<int^>);
		*font_count_ptr = fonts.size;

		user_ptr_arr[0] = fonts.data;
		user_ptr_arr[1] = font_count_ptr;
		Clay.SetMeasureTextFunction(c:Raylib_MeasureText, user_ptr_arr);
	}

	static void Deinit() {
		Clay.Raylib_Close();
	}

	static void MainLoop(c:EditClayAppMainLoopUpdateFn update_fn, c:EditClayAppMainLoopUpdateFn render_after_fn) {
		// Main game loop
		rl.SetTargetFPS(60);
		bool raylib_close_on_esc = GlobalSettings.get_bool("raylib_close_on_esc", false); // loaded from GlobalSettings
		if (!raylib_close_on_esc) {
			rl.SetExitKey(c:KEY_NULL);
		}

		while (!rl.WindowShouldClose())    // Detect window close button or ESC key
		{
			if (reinitializeClay) {
				Clay.SetMaxElementCount(8192); // TODO: UM WHAT?
				totalMemorySize = Clay.MinMemorySize();
				clayMemory = Clay.CreateArenaWithCapacityAndMemory(totalMemorySize);
				Clay.Initialize(clayMemory, Clay_Dimensions { rl.GetScreenWidth() as float, rl.GetScreenHeight() as float }, Clay_ErrorHandler{ HandleClayErrors, NULL });
				reinitializeClay = false;
			}
			_UpdateDrawFrame(update_fn, render_after_fn);
		}
	}

	static void _UpdateDrawFrame(c:EditClayAppMainLoopUpdateFn update_fn, c:EditClayAppMainLoopUpdateFn render_after_fn) {
		Vec2 mouseWheelDelta = c:GetMouseWheelMoveV();
		float mouseWheelX = mouseWheelDelta.x;
		float mouseWheelY = mouseWheelDelta.y;

		if (HotKeys.ClayDebugToggle.IsPressed()) {
			debugEnabled = !debugEnabled;
			Clay.SetDebugModeEnabled(debugEnabled);
		}
		//----------------------------------------------------------------------------------
		// Handle scroll containers
		Vec2 mousePosition = rl.GetMousePosition();
		Clay.SetPointerState(mousePosition, rl.IsMouseButtonDown(0) && !scrollbarData.mouseDown);
		Clay.SetLayoutDimensions(Clay_Dimensions{ rl.GetScreenWidth() as float, rl.GetScreenHeight() as float });
		if (!rl.IsMouseButtonDown(0)) {
			scrollbarData.mouseDown = false;
		}

		if (rl.IsMouseButtonDown(0) && !scrollbarData.mouseDown && Clay.PointerOver(Clay__HashString(CLAY_STRING("ScrollBar"), 0, 0))) {
			Clay_ScrollContainerData scrollContainerData = Clay.GetScrollContainerData(Clay__HashString(CLAY_STRING("MainContent"), 0, 0));
			scrollbarData.clickOrigin = mousePosition;
			scrollbarData.positionOrigin = *scrollContainerData.scrollPosition;
			scrollbarData.mouseDown = true;
		} else if (scrollbarData.mouseDown) {
			Clay_ScrollContainerData scrollContainerData = Clay.GetScrollContainerData(Clay__HashString(CLAY_STRING("MainContent"), 0, 0));
			if (scrollContainerData.contentDimensions.height > 0) {
				Vec2 ratio = {
					scrollContainerData.contentDimensions.width / scrollContainerData.scrollContainerDimensions.width,
					scrollContainerData.contentDimensions.height / scrollContainerData.scrollContainerDimensions.height,
				};
				if (scrollContainerData.config.vertical) {
					scrollContainerData.scrollPosition#y = scrollbarData.positionOrigin.y + (scrollbarData.clickOrigin.y - mousePosition.y) * ratio.y;
				}
				if (scrollContainerData.config.horizontal) {
					scrollContainerData.scrollPosition#x = scrollbarData.positionOrigin.x + (scrollbarData.clickOrigin.x - mousePosition.x) * ratio.x;
				}
			}
		}

		Clay.UpdateScrollContainers(true, Vec2{mouseWheelX, mouseWheelY}, rl.GetFrameTime());
		// Generate the auto layout for rendering
		double currentTime = rl.GetTime();

		Clay.BeginLayout();
		update_fn();
		Clay_RenderCommandArray renderCommands = Clay.EndLayout();
		// printf("layout time: %f microseconds\n", (rl.GetTime() - currentTime) * 1000 * 1000);
		// RENDERING ---------------------------------
		currentTime = rl.GetTime();
		rl.BeginDrawing();
		// rl.ClearBackground(Colors.Purple);
		rl.ClearBackground(Colors.Black);
		Clay.Raylib_Render(renderCommands, fonts.data);

		render_after_fn();

		rl.EndDrawing();
		// printf("render time: %f ms\n", (rl.GetTime() - currentTime) * 1000);

		//----------------------------------------------------------------------------------

		tfree(); // release temp memory -- per frame barier! ---------------------
	}
}
