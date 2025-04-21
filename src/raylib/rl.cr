import std;

c:import "raylib.h";
c:import "raymath.h";

c:c:`
#pragma GCC diagnostic push
#ifdef _WIN32
	#pragma GCC diagnostic ignored "-Wdiscarded-qualifiers" // issue w/ do_file_tree_dir_visit
#else
	#pragma GCC diagnostic ignored "-Wincompatible-pointer-types-discards-qualifiers" // issue w/ do_file_tree_dir_visit
#endif
#pragma GCC diagnostic ignored "-Wpointer-sign" // TODO: <--- should really fix this
`;

import list;

c:`
typedef Vector2 Vec2;
typedef Vector3 Vec3;
typedef Vector4 Vec4;
`;

@extern struct Camera2D {}
@extern struct VrStereoConfig {}
@extern struct VrDeviceInfo {}
@extern struct TraceLogCallback {}
@extern struct LoadFileDataCallback {}
@extern struct SaveFileDataCallback {}
@extern struct LoadFileTextCallback {}
@extern struct SaveFileTextCallback {}
@extern struct FilePathList {
	uint capacity;
	uint count;
	char^^ paths;

	static Self Load() -> c:LoadDroppedFiles();
	void Unload() -> c:UnloadDroppedFiles(this);
}
@extern struct AutomationEvent {}
@extern struct AutomationEventList{}
@extern struct Ray{}
@extern struct Matrix{}

struct Raylib {
	// =================================
	// Window-related functions
    void InitWindow(int width, int height, char^ title) -> c:InitWindow(width, height, title);  // Initialize window and OpenGL context
    void CloseWindow() -> c:CloseWindow();                                     // Close window and unload OpenGL context
    bool WindowShouldClose() -> c:WindowShouldClose();                               // Check if application should close (KEY_ESCAPE pressed or windows close icon clicked)
    bool IsWindowReady() -> c:IsWindowReady();                                   // Check if window has been initialized successfully
    bool IsWindowFullscreen() -> c:IsWindowFullscreen();                              // Check if window is currently fullscreen
    bool IsWindowHidden() -> c:IsWindowHidden();                                  // Check if window is currently hidden (only PLATFORM_DESKTOP)
    bool IsWindowMinimized() -> c:IsWindowMinimized();                               // Check if window is currently minimized (only PLATFORM_DESKTOP)
    bool IsWindowMaximized() -> c:IsWindowMaximized();                               // Check if window is currently maximized (only PLATFORM_DESKTOP)
    bool IsWindowFocused() -> c:IsWindowFocused();                                 // Check if window is currently focused (only PLATFORM_DESKTOP)
    bool IsWindowResized() -> c:IsWindowResized();                                 // Check if window has been resized last frame
    bool IsWindowState(int flag) -> c:IsWindowState(flag);                      // Check if one specific window flag is enabled
    void SetWindowState(int flags) -> c:SetWindowState(flags);                    // Set window configuration state using flags (only PLATFORM_DESKTOP)
    void ClearWindowState(int flags) -> c:ClearWindowState(flags);                  // Clear window configuration state flags
    void ToggleFullscreen() -> c:ToggleFullscreen();                                // Toggle window state: fullscreen/windowed (only PLATFORM_DESKTOP)
    void ToggleBorderlessWindowed() -> c:ToggleBorderlessWindowed();                        // Toggle window state: borderless windowed (only PLATFORM_DESKTOP)
    void MaximizeWindow() -> c:MaximizeWindow();                                  // Set window state: maximized, if resizable (only PLATFORM_DESKTOP)
    void MinimizeWindow() -> c:MinimizeWindow();                                  // Set window state: minimized, if resizable (only PLATFORM_DESKTOP)
    void RestoreWindow() -> c:RestoreWindow();                                   // Set window state: not minimized/maximized (only PLATFORM_DESKTOP)
    void SetWindowIcon(Image image) -> c:SetWindowIcon(image);                            // Set icon for window (single image, RGBA 32bit, only PLATFORM_DESKTOP)
    void SetWindowIcons(Image^ images, int count) -> c:SetWindowIcons(images, count);              // Set icon for window (multiple images, RGBA 32bit, only PLATFORM_DESKTOP)
    void SetWindowTitle(char^ title) -> c:SetWindowTitle(title);                     // Set title for window (only PLATFORM_DESKTOP and PLATFORM_WEB)
    void SetWindowPosition(int x, int y) -> c:SetWindowPosition(x, y);                       // Set window position on screen (only PLATFORM_DESKTOP)
    void SetWindowMonitor(int monitor) -> c:SetWindowMonitor(monitor);                         // Set monitor for the current window
    void SetWindowMinSize(int width, int height) -> c:SetWindowMinSize(width, height);               // Set window minimum dimensions (for FLAG_WINDOW_RESIZABLE)
    void SetWindowMaxSize(int width, int height) -> c:SetWindowMaxSize(width, height);               // Set window maximum dimensions (for FLAG_WINDOW_RESIZABLE)
    void SetWindowSize(int width, int height) -> c:SetWindowSize(width, height);                  // Set window dimensions
    void SetWindowOpacity(float opacity) -> c:SetWindowOpacity(opacity);                       // Set window opacity [0.0f..1.0f] (only PLATFORM_DESKTOP)
    void SetWindowFocused() -> c:SetWindowFocused();                                // Set window focused (only PLATFORM_DESKTOP)
    void^ GetWindowHandle() -> c:GetWindowHandle();                                // Get native window handle
    int GetScreenWidth() -> c:GetScreenWidth();                                   // Get current screen width
    int GetScreenHeight() -> c:GetScreenHeight();                                  // Get current screen height
    int GetRenderWidth() -> c:GetRenderWidth();                                   // Get current render width (it considers HiDPI)
    int GetRenderHeight() -> c:GetRenderHeight();                                  // Get current render height (it considers HiDPI)
    int GetMonitorCount() -> c:GetMonitorCount();                                  // Get number of connected monitors
    int GetCurrentMonitor() -> c:GetCurrentMonitor();                                // Get current connected monitor
    Vec2 GetMonitorPosition(int monitor) -> c:GetMonitorPosition(monitor);                    // Get specified monitor position
    int GetMonitorWidth(int monitor) -> c:GetMonitorWidth(monitor);                           // Get specified monitor width (current video mode used by monitor)
    int GetMonitorHeight(int monitor) -> c:GetMonitorHeight(monitor);                          // Get specified monitor height (current video mode used by monitor)
    int GetMonitorPhysicalWidth(int monitor) -> c:GetMonitorPhysicalWidth(monitor);                   // Get specified monitor physical width in millimetres
    int GetMonitorPhysicalHeight(int monitor) -> c:GetMonitorPhysicalHeight(monitor);                  // Get specified monitor physical height in millimetres
    int GetMonitorRefreshRate(int monitor) -> c:GetMonitorRefreshRate(monitor);                     // Get specified monitor refresh rate
    Vec2 GetWindowPosition() -> c:GetWindowPosition();                            // Get window position XY on monitor
    Vec2 GetWindowScaleDPI() -> c:GetWindowScaleDPI();                            // Get window scale DPI factor
    char^ GetMonitorName(int monitor) -> c:GetMonitorName(monitor);                    // Get the human-readable, UTF-8 encoded name of the specified monitor
    void SetClipboardText(char^ text) -> c:SetClipboardText(text);                    // Set clipboard text content
    char^ GetClipboardText() -> c:GetClipboardText();                         // Get clipboard text content
    void EnableEventWaiting() -> c:EnableEventWaiting();                              // Enable waiting for events on EndDrawing(), no automatic event polling
    void DisableEventWaiting() -> c:DisableEventWaiting();                             // Disable waiting for events on EndDrawing(), automatic events polling


    // Cursor-related functions
    void ShowCursor() -> c:ShowCursor();                                      // Shows cursor
    void HideCursor() -> c:HideCursor();                                      // Hides cursor
    bool IsCursorHidden() -> c:IsCursorHidden();                                  // Check if cursor is not visible
    void EnableCursor() -> c:EnableCursor();                                    // Enables cursor (unlock cursor)
    void DisableCursor() -> c:DisableCursor();                                   // Disables cursor (lock cursor)
    bool IsCursorOnScreen() -> c:IsCursorOnScreen();                                // Check if cursor is on the screen

    // Drawing-related functions
    void ClearBackground(Color color) -> c:ClearBackground(color);                          // Set background color (framebuffer clear color)
    void BeginDrawing() -> c:BeginDrawing();                                    // Setup canvas (framebuffer) to start drawing
    void EndDrawing() -> c:EndDrawing();                                      // End canvas drawing and swap buffers (float buffering)
    void BeginMode2D(Camera2D camera) -> c:BeginMode2D(camera);                          // Begin 2D mode with custom camera (2D)
    void EndMode2D() -> c:EndMode2D();                                       // Ends 2D mode with custom camera
    void BeginMode3D(Camera camera) -> c:BeginMode3D(camera);                          // Begin 3D mode with custom camera (3D)
    void EndMode3D() -> c:EndMode3D();                                       // Ends 3D mode and returns to default 2D orthographic mode
    void BeginTextureMode(RenderTexture target) -> c:BeginTextureMode(target);              // Begin drawing to render texture
    void EndTextureMode() -> c:EndTextureMode();                                  // Ends drawing to render texture
    void BeginShaderMode(Shader shader) -> c:BeginShaderMode(shader);                        // Begin custom shader drawing
    void EndShaderMode() -> c:EndShaderMode();                                   // End custom shader drawing (use default shader)
    void BeginBlendMode(int mode) -> c:BeginBlendMode(mode);                              // Begin blending mode (alpha, additive, multiplied, subtract, custom)
    void EndBlendMode() -> c:EndBlendMode();                                    // End blending mode (reset to default: alpha blending)
    void BeginScissorMode(int x, int y, int width, int height) -> c:BeginScissorMode(x, y, width, height); // Begin scissor mode (define screen area for following drawing)
    void EndScissorMode() -> c:EndScissorMode();                                  // End scissor mode
    void BeginVrStereoMode(VrStereoConfig config) -> c:BeginVrStereoMode(config);              // Begin stereo rendering (requires VR simulator)
    void EndVrStereoMode() -> c:EndVrStereoMode();                                 // End stereo rendering (requires VR simulator)

    // VR stereo config functions for VR simulator
    VrStereoConfig LoadVrStereoConfig(VrDeviceInfo device) -> c:LoadVrStereoConfig(device);     // Load VR stereo config for VR simulator device parameters
    void UnloadVrStereoConfig(VrStereoConfig config) -> c:UnloadVrStereoConfig(config);           // Unload VR stereo config

    // Shader management functions
    // NOTE: Shader functionality is not available on OpenGL 1.1
    Shader LoadShader(char^ vsFileName, char^ fsFileName) -> c:LoadShader(vsFileName, fsFileName);   // Load shader from files and bind default locations
    Shader LoadShaderFromMemory(char^ vsCode, char^ fsCode) -> c:LoadShaderFromMemory(vsCode, fsCode); // Load shader from code strings and bind default locations
    bool IsShaderValid(Shader shader) -> c:IsShaderValid(shader);                                   // Check if a shader is ready
    int GetShaderLocation(Shader shader, char^ uniformName) -> c:GetShaderLocation(shader, uniformName);       // Get shader uniform location
    int GetShaderLocationAttrib(Shader shader, char^ attribName) -> c:GetShaderLocationAttrib(shader, attribName);  // Get shader attribute location
    void SetShaderValue(Shader shader, int locIndex, void^ value, int uniformType) -> c:SetShaderValue(shader, locIndex, value, uniformType);               // Set shader uniform value
    void SetShaderValueV(Shader shader, int locIndex, void^ value, int uniformType, int count) -> c:SetShaderValueV(shader, locIndex, value, uniformType, count);   // Set shader uniform value Vec
    void SetShaderValueMatrix(Shader shader, int locIndex, Matrix mat) -> c:SetShaderValueMatrix(shader, locIndex, mat);         // Set shader uniform value (matrix 4x4)
    void SetShaderValueTexture(Shader shader, int locIndex, Texture texture) -> c:SetShaderValueTexture(shader, locIndex, texture); // Set shader uniform value for texture (sampler2d)
    void UnloadShader(Shader shader) -> c:UnloadShader(shader);                                    // Unload shader from GPU memory (VRAM)

    // Screen-space-related functions
    Ray GetMouseRay(Vec2 mousePosition, Camera camera) -> c:GetMouseRay(mousePosition, camera);      // Get a ray trace from mouse position
    Matrix GetCameraMatrix(Camera camera) -> c:GetCameraMatrix(camera);                      // Get camera transform matrix (view matrix)
    Matrix GetCameraMatrix2D(Camera2D camera) -> c:GetCameraMatrix2D(camera);                  // Get camera 2d transform matrix
    Vec2 GetWorldToScreen(Vec3 position, Camera camera) -> c:GetWorldToScreen(position, camera);  // Get the screen space position for a 3d world space position
    Vec2 GetScreenToWorld2D(Vec2 position, Camera2D camera) -> c:GetScreenToWorld2D(position, camera); // Get the world space position for a 2d camera screen space position
    Vec2 GetWorldToScreenEx(Vec3 position, Camera camera, int width, int height) -> c:GetWorldToScreenEx(position, camera, width, height); // Get size position for a 3d world space position
    Vec2 GetWorldToScreen2D(Vec2 position, Camera2D camera) -> c:GetWorldToScreen2D(position, camera); // Get the screen space position for a 2d camera world space position

    // Timing-related functions
    void SetTargetFPS(int fps) -> c:SetTargetFPS(fps);                                 // Set target FPS (maximum)
    float GetFrameTime() -> c:GetFrameTime();                                   // Get time in seconds for last frame drawn (delta time)
    float GetTime() -> c:GetTime();                                       // Get elapsed time in seconds since InitWindow() // TODO: should be float
    int GetFPS() -> c:GetFPS();                                           // Get current FPS

    // Custom frame control functions
    // NOTE: Those functions are intended for advance users that want full control over the frame processing
    // By default EndDrawing() does this job: draws everything + SwapScreenBuffer() + manage frame timing + PollInputEvents()
    // To avoid that behaviour and control frame processes manually, enable in config.h: SUPPORT_CUSTOM_FRAME_CONTROL
    void SwapScreenBuffer() -> c:SwapScreenBuffer();                                // Swap back buffer with front buffer (screen drawing)
    void PollInputEvents() -> c:PollInputEvents();                                 // Register all input events
    void WaitTime(float seconds) -> c:WaitTime(seconds);                              // Wait for some time (halt program execution)

    // Random values generation functions
    void SetRandomSeed(int seed) -> c:SetRandomSeed(seed);                      // Set the seed for the random number generator
    int GetRandomValue(int min, int max) -> c:GetRandomValue(min, max);                       // Get a random value between min and max (both included)
    int^ LoadRandomSequence(int count, int min, int max) -> c:LoadRandomSequence(count, min, max); // Load random values sequence, no values repeated
    void UnloadRandomSequence(int^ sequence) -> c:UnloadRandomSequence(sequence);                   // Unload random values sequence

    // Misc. functions
    void TakeScreenshot(char^ fileName) -> c:TakeScreenshot(fileName);                  // Takes a screenshot of current screen (filename extension defines format)
    void SetConfigFlags(int flags) -> c:SetConfigFlags(flags);                    // Setup init configuration flags (view FLAGS)
    void OpenURL(char^ url) -> c:OpenURL(url);                              // Open URL with default system browser (if available)

    // NOTE: Following functions implemented in module [utils]
    //------------------------------------------------------------------
    void TraceLog(int logLevel, char^ text) -> c:TraceLog(logLevel, text);         // Show trace log messages (LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERROR...)
    void SetTraceLogLevel(int logLevel) -> c:SetTraceLogLevel(logLevel);                        // Set the current threshold (minimum) log level
    void^ MemAlloc(int size) -> c:MemAlloc(size);                          // Internal memory allocator
    void^ MemRealloc(void^ ptr, int size) -> c:MemRealloc(ptr, size);             // Internal memory reallocator
    void MemFree(void^ ptr) -> c:MemFree(ptr);                                    // Internal memory free

    // Set custom callbacks
    // WARNING: Callbacks setup is intended for advance users
    void SetTraceLogCallback(TraceLogCallback callback) -> c:SetTraceLogCallback(callback);         // Set custom trace log
    void SetLoadFileDataCallback(LoadFileDataCallback callback) -> c:SetLoadFileDataCallback(callback); // Set custom file binary data loader
    void SetSaveFileDataCallback(SaveFileDataCallback callback) -> c:SetSaveFileDataCallback(callback); // Set custom file binary data saver
    void SetLoadFileTextCallback(LoadFileTextCallback callback) -> c:SetLoadFileTextCallback(callback); // Set custom file text data loader
    void SetSaveFileTextCallback(SaveFileTextCallback callback) -> c:SetSaveFileTextCallback(callback); // Set custom file text data saver

    // Files management functions
    char^ LoadFileData(char^ fileName, int^ dataSize) -> c:LoadFileData(fileName, dataSize); // Load file data as byte array (read)
    void UnloadFileData(char^ data) -> c:UnloadFileData(data);                   // Unload file data allocated by LoadFileData()
    bool SaveFileData(char^ fileName, void^ data, int dataSize) -> c:SaveFileData(fileName, data, dataSize); // Save data to file from byte array (write), returns true on success
    bool ExportDataAsCode(char^ data, int dataSize, char^ fileName) -> c:ExportDataAsCode(data, dataSize, fileName); // Export data to code (.h), returns true on success
    char^ LoadFileText(char^ fileName) -> c:LoadFileText(fileName);                   // Load text data from file (read), returns a '\0' terminated string
    void UnloadFileText(char^ text) -> c:UnloadFileText(text);                            // Unload file text data allocated by LoadFileText()
    bool SaveFileText(char^ fileName, char^ text) -> c:SaveFileText(fileName, text);        // Save text data to file (write), string must be '\0' terminated, returns true on success
    //------------------------------------------------------------------

    // File system functions
    bool FileExists(char^ fileName) -> c:FileExists(fileName);                      // Check if file exists
    bool DirectoryExists(char^ dirPath) -> c:DirectoryExists(dirPath);                  // Check if a directory path exists
    bool IsFileExtension(char^ fileName, char^ ext) -> c:IsFileExtension(fileName, ext); // Check file extension (including point: .png, .wav)
    int GetFileLength(char^ fileName) -> c:GetFileLength(fileName);                    // Get file length in bytes (NOTE: GetFileSize() conflicts with windows.h)
    char^ GetFileExtension(char^ fileName) -> c:GetFileExtension(fileName);         // Get pointer to extension for a filename string (includes dot: '.png')
    char^ GetFileName(char^ filePath) -> c:GetFileName(filePath);              // Get pointer to filename for a path string
    char^ GetFileNameWithoutExt(char^ filePath) -> c:GetFileNameWithoutExt(filePath);    // Get filename string without extension (uses static string)
    char^ GetDirectoryPath(char^ filePath) -> c:GetDirectoryPath(filePath);         // Get full path for a given fileName with path (uses static string)
    char^ GetPrevDirectoryPath(char^ dirPath) -> c:GetPrevDirectoryPath(dirPath);      // Get previous directory path for a given path (uses static string)
    char^ GetWorkingDirectory() -> c:GetWorkingDirectory();                      // Get current working directory (uses static string)
    char^ GetApplicationDirectory() -> c:GetApplicationDirectory();                  // Get the directory of the running application (uses static string)
    bool ChangeDirectory(char^ dir) -> c:ChangeDirectory(dir);                      // Change working directory, return true on success
    bool IsPathFile(char^ path) -> c:IsPathFile(path);                          // Check if a given path is a file or a directory
    FilePathList LoadDirectoryFiles(char^ dirPath) -> c:LoadDirectoryFiles(dirPath);       // Load directory filepaths
    FilePathList LoadDirectoryFilesEx(char^ basePath, char^ filter, bool scanSubdirs) -> c:LoadDirectoryFilesEx(basePath, filter, scanSubdirs); // Load directory filepaths with extension filtering and recursive directory scan
    void UnloadDirectoryFiles(FilePathList files) -> c:UnloadDirectoryFiles(files);              // Unload filepaths
    bool IsFileDropped() -> c:IsFileDropped();                                   // Check if a file has been dropped into window
    FilePathList LoadDroppedFiles() -> c:LoadDroppedFiles();                        // Load dropped filepaths
    void UnloadDroppedFiles(FilePathList files) -> c:UnloadDroppedFiles(files);                // Unload dropped filepaths
    long GetFileModTime(char^ fileName) -> c:GetFileModTime(fileName);                  // Get file modification time (last write time)

    // Compression/Encoding functionality // TODO: use unsigned char^
    // char^ CompressData(char^ data, int dataSize, int^ compDataSize) -> c:CompressData(data, dataSize, compDataSize);        // Compress data (DEFLATE algorithm), memory must be MemFree()
    // char^ DecompressData(char^ compData, int compDataSize, int^ dataSize) -> c:DecompressData(compData, compDataSize, dataSize);  // Decompress data (DEFLATE algorithm), memory must be MemFree()
    // char^ EncodeDataBase64(char^ data, int dataSize, int^ outputSize) -> c:EncodeDataBase64(data, dataSize, outputSize);               // Encode data to Base64 string, memory must be MemFree()
    // char^ DecodeDataBase64(char^ data, int^ outputSize) -> c:DecodeDataBase64(data, outputSize);                    // Decode Base64 string data, memory must be MemFree()

    // Automation events functionality
    AutomationEventList LoadAutomationEventList(char^ fileName) -> c:LoadAutomationEventList(fileName);                // Load automation events list from file, NULL for empty list, capacity = MAX_AUTOMATION_EVENTS
    void UnloadAutomationEventList(AutomationEventList list) -> c:UnloadAutomationEventList(list);                        // Unload automation events list from file
    bool ExportAutomationEventList(AutomationEventList list, char^ fileName) -> c:ExportAutomationEventList(list, fileName);   // Export automation events list as text file
    void SetAutomationEventList(AutomationEventList^ list) -> c:SetAutomationEventList(list);                           // Set automation event list to record to
    void SetAutomationEventBaseFrame(int frame) -> c:SetAutomationEventBaseFrame(frame);                                      // Set automation event internal base frame to start recording
    void StartAutomationEventRecording() -> c:StartAutomationEventRecording();                                         // Start recording automation events (AutomationEventList must be set)
    void StopAutomationEventRecording() -> c:StopAutomationEventRecording();                                          // Stop recording automation events
    void PlayAutomationEvent(AutomationEvent event) -> c:PlayAutomationEvent(event);                                  // Play a recorded automation event

    //------------------------------------------------------------------------------------
    // Input Handling Functions (Module: core)
    //------------------------------------------------------------------------------------

    // Input-related functions: keyboard
    bool IsKeyPressed(int key) -> c:IsKeyPressed(key);                             // Check if a key has been pressed once
    bool IsKeyPressedRepeat(int key) -> c:IsKeyPressedRepeat(key);                       // Check if a key has been pressed again (Only PLATFORM_DESKTOP)
    bool IsKeyDown(int key) -> c:IsKeyDown(key);                                // Check if a key is being pressed
    bool IsKeyReleased(int key) -> c:IsKeyReleased(key);                            // Check if a key has been released once
    bool IsKeyUp(int key) -> c:IsKeyUp(key);                                  // Check if a key is NOT being pressed
    int GetKeyPressed() -> c:GetKeyPressed();                                // Get key pressed (keycode), call it multiple times for keys queued, returns 0 when the queue is empty
    int GetCharPressed() -> c:GetCharPressed();                               // Get char pressed (unicode), call it multiple times for chars queued, returns 0 when the queue is empty
    void SetExitKey(int key) -> c:SetExitKey(key);                               // Set a custom key to exit program (default is ESC)

    // Input-related functions: gamepads
    bool IsGamepadAvailable(int gamepad) -> c:IsGamepadAvailable(gamepad);                   // Check if a gamepad is available
    char^ GetGamepadName(int gamepad) -> c:GetGamepadName(gamepad);                // Get gamepad internal name id
    bool IsGamepadButtonPressed(int gamepad, int button) -> c:IsGamepadButtonPressed(gamepad, button);   // Check if a gamepad button has been pressed once
    bool IsGamepadButtonDown(int gamepad, int button) -> c:IsGamepadButtonDown(gamepad, button);      // Check if a gamepad button is being pressed
    bool IsGamepadButtonReleased(int gamepad, int button) -> c:IsGamepadButtonReleased(gamepad, button);  // Check if a gamepad button has been released once
    bool IsGamepadButtonUp(int gamepad, int button) -> c:IsGamepadButtonUp(gamepad, button);        // Check if a gamepad button is NOT being pressed
    int GetGamepadButtonPressed() -> c:GetGamepadButtonPressed();                      // Get the last gamepad button pressed
    int GetGamepadAxisCount(int gamepad) -> c:GetGamepadAxisCount(gamepad);                   // Get gamepad axis count for a gamepad
    float GetGamepadAxisMovement(int gamepad, int axis) -> c:GetGamepadAxisMovement(gamepad, axis);    // Get axis movement value for a gamepad axis
    int SetGamepadMappings(char^ mappings) -> c:SetGamepadMappings(mappings);           // Set internal gamepad mappings (SDL_GameControllerDB)

    // Input-related functions: mouse
    bool IsMouseButtonPressed(int button) -> c:IsMouseButtonPressed(button);                  // Check if a mouse button has been pressed once
    bool IsMouseButtonDown(int button) -> c:IsMouseButtonDown(button);                     // Check if a mouse button is being pressed
    bool IsMouseButtonReleased(int button) -> c:IsMouseButtonReleased(button);                 // Check if a mouse button has been released once
    bool IsMouseButtonUp(int button) -> c:IsMouseButtonUp(button);                       // Check if a mouse button is NOT being pressed
    int GetMouseX() -> c:GetMouseX();                                    // Get mouse position X
    int GetMouseY() -> c:GetMouseY();                                    // Get mouse position Y
    Vec2 GetMousePosition() -> c:GetMousePosition();                         // Get mouse position XY
    Vec2 GetMouseDelta() -> c:GetMouseDelta();                            // Get mouse delta between frames
    void SetMousePosition(int x, int y) -> c:SetMousePosition(x, y);                    // Set mouse position XY
    void SetMouseOffset(int offsetX, int offsetY) -> c:SetMouseOffset(offsetX, offsetY);          // Set mouse offset
    void SetMouseScale(float scaleX, float scaleY) -> c:SetMouseScale(scaleX, scaleY);         // Set mouse scaling
    float GetMouseWheelMove() -> c:GetMouseWheelMove();                          // Get mouse wheel movement for X or Y, whichever is larger
    Vec2 GetMouseWheelMoveV() -> c:GetMouseWheelMoveV();                       // Get mouse wheel movement for both X and Y
    void SetMouseCursor(int cursor) -> c:SetMouseCursor(cursor);                        // Set mouse cursor

    // Input-related functions: touch
    int GetTouchX() -> c:GetTouchX();                                    // Get touch position X for touch point 0 (relative to screen size)
    int GetTouchY() -> c:GetTouchY();                                    // Get touch position Y for touch point 0 (relative to screen size)
    Vec2 GetTouchPosition(int index) -> c:GetTouchPosition(index);                    // Get touch position XY for a touch point index (relative to screen size)
    int GetTouchPointId(int index) -> c:GetTouchPointId(index);                         // Get touch point identifier for given index
    int GetTouchPointCount() -> c:GetTouchPointCount();                           // Get number of touch points

    //------------------------------------------------------------------------------------
    // Gestures and Touch Handling Functions (Module: rgestures) // TODO: gestures
    //------------------------------------------------------------------------------------
    void SetGesturesEnabled(int flags) -> c:SetGesturesEnabled(flags);      // Enable a set of gestures using flags
    bool IsGestureDetected(int gesture) -> c:IsGestureDetected(gesture);     // Check if a gesture have been detected
    // int GetGestureDetected() -> c:GetGestureDetected();                     // Get latest detected gesture
    // float GetGestureHoldDuration() -> c:GetGestureHoldDuration();               // Get gesture hold time in milliseconds
    // Vec2 GetGestureDragVec() -> c:GetGestureDragVec();               // Get gesture drag Vec
    // float GetGestureDragAngle() -> c:GetGestureDragAngle();                  // Get gesture drag angle
    // Vec2 GetGesturePinchVec() -> c:GetGesturePinchVec();              // Get gesture pinch delta
    // float GetGesturePinchAngle() -> c:GetGesturePinchAngle();                 // Get gesture pinch angle

    //------------------------------------------------------------------------------------
    // Camera System Functions (Module: rcamera)
    //------------------------------------------------------------------------------------
    void UpdateCamera(Camera^ camera, int mode) -> c:UpdateCamera(camera, mode);      // Update camera position for selected mode
    void UpdateCameraPro(Camera^ camera, Vec3 movement, Vec3 rotation, float zoom) -> c:UpdateCameraPro(camera, movement, rotation, zoom); // Update camera movement/rotation
	// =================================



	// TODO: stuff
    Texture LoadTexture(char^ file_path) -> c:LoadTexture(file_path);                                                       // Load texture from file into GPU memory (VRAM)
    Texture LoadTextureFromImage(Image img) -> c:LoadTextureFromImage(img);                                                       // Load texture from file into GPU memory (VRAM)
    Texture LoadTextureFromImageDestructively(Image img_to_unload) {
		defer img_to_unload.Unload();
		return LoadTextureFromImage(img_to_unload);
	}
	Image LoadImageFromTexture(Texture texture) -> c:LoadImageFromTexture(texture);

	Image GenImageColor(int width, int height, Color color) -> c:GenImageColor(width, height, color);                                           // Generate image: plain color
}

Raylib rl;

Vec2 Vec2_one = v2(1, 1);
Vec2 Vec2_zero = v2(0, 0);
Vec2 Vec2_up = v2(0, 1);
Vec2 Vec2_right = v2(1, 0);

@extern struct Vec2 {
	float x = 0;
	float y = 0;

	construct(float x, float y) -> { :x, :y };

	// TODO: static
	// Vector2 Vector2Zero(void);
	// Vector2 Vector2One(void);
	// TODO: right/left, up/down too

	// Vector2 Vector2Lerp(Vector2 v1, Vector2 v2, float amount); -- also instance?

	bool Between(Vec2 tl, Vec2 br) -> (x >= tl.x && x <= br.x) && (y >= tl.y && y <= br.y);
	bool InV(Vec2 tl, Vec2 dimens) -> this.Between(tl, tl + dimens);
	bool InCircle(Vec2 center, float radius) -> (center - this).mag() <= radius; // <=

	c:Vector2 v() -> c:Vector2{ .x = this.x, .y = this.y };
	
	Vec2 operator:+(Vec2 other) -> c:Vector2Add(v(), other.v());
	// Vector2 Vector2AddValue(Vector2 v, float add);
	Vec2 operator:-(Vec2 other) -> c:Vector2Subtract(v(), other.v());
	// Vector2 Vector2SubtractValue(Vector2 v, float sub);
	float length() -> c:Vector2Length(v());
	float length_sqr() -> c:Vector2LengthSqr(v());

	float dot_product(Vec2 other) -> c:Vector2DotProduct(v(), other.v());

	float mag() -> this.distance(Vec2{ .x = 0, .y = 0 }); // TODO: mag_squared!!
	float distance(Vec2 other) -> c:Vector2Distance(v(), other.v());
	float distance_sqr(Vec2 other) -> c:Vector2DistanceSqr(v(), other.v());

	float angle0() -> this.angle(Vec2{ .x = 1, .y = 0 });
	float angle(Vec2 other) -> c:Vector2Angle(v(), other.v());

	Vec2 operator:*(Vec2 other) -> c:Vector2Multiply(v(), other.v());
	// TODO: make this also operator (need overloads)
	Vec2 scale(float scale) -> c:Vector2Scale(v(), scale);

	// TODO: operator:- (uop support!)
	Vec2 negate() -> c:Vector2Negate(v());

	Vec2 operator:/(Vec2 other) -> c:Vector2Divide(v(), other.v());
	Vec2 divide(float divisor) -> v2(this.x / divisor, this.y / divisor);
	// TODO: operator:/(float xxx)

	Vec2 normalize() -> c:Vector2Normalize(v());

	// NOTE: uses rough equality... do we want that?
	bool operator:==(Vec2 other) -> c:Vector2Equals(v(), other.v());
	// TODO: forgot to impl op:!=
	bool operator:!=(Vec2 other) -> !(this == other);

	Vec2 lerp(Vec2 other, float amount) -> c:Vector2Lerp(v(), other.v(), amount);

	// NOTE: what does this even do?
	Vec2 move_towards(Vec2 other, float maxDistance) -> c:Vector2MoveTowards(v(), other.v(), maxDistance);

	Vec2 reflect(Vec2 normal) -> c:Vector2Reflect(v(), normal.v());
	Vec2 rotate(float angle) -> c:Vector2Rotate(v(), angle);
	// NOTE: what? is this (1/x, 1/y)?
	Vec2 invert() -> c:Vector2Invert(v());
	Vec2 clamp(Vec2 min, Vec2 max) -> c:Vector2Clamp(v(), min.v(), max.v());
	Vec2 clamp_value(float min, float max) -> c:Vector2ClampValue(v(), min, max);

	// TODO: other
	// Vector2 Vector2Transform(Vector2 v, Matrix mat);
}
Vec2 unit_vec(float radians) -> {
	.x = c:cos(radians),
	.y = c:sin(radians)
};

@extern struct Vec3 {
	float x;
	float y;
	float z;

	construct(float x, float y, float z) -> { :x, :y, :z };

	// TODO: static
	// Vector3 Vector3Zero(void);
	// Vector3 Vector3One(void);
	// TODO: right/left, up/down too

	// Vector3 Vector3Lerp(Vector3 v1, Vector3 v2, float amount); -- also instance?

	bool Between(Vec3 tl, Vec3 br) -> (x >= tl.x && x <= br.x) && (y >= tl.y && y <= br.y) && (z >= tl.z && z <= br.z);
	bool InV(Vec3 tl, Vec3 dimens) -> this.Between(tl, tl + dimens);
	bool InCircle(Vec3 center, float radius) -> (center - this).mag() <= radius; // <=
	
	Vec3 operator:+(Vec3 other) -> c:Vector3Add(this, other);
	// Vector3 Vector3AddValue(Vector3 v, float add);
	Vec3 operator:-(Vec3 other) -> c:Vector3Subtract(this, other);
	// Vector3 Vector3SubtractValue(Vector3 v, float sub);
	float length() -> c:Vector3Length(this);
	float length_sqr() -> c:Vector3LengthSqr(this);

	float dot_product(Vec3 other) -> c:Vector3DotProduct(this, other);

	float mag() -> this.distance(v3(0, 0, 0)); // TODO: mag_squared!!
	float distance(Vec3 other) -> c:Vector3Distance(this, other);
	float distance_sqr(Vec3 other) -> c:Vector3DistanceSqr(this, other);

	float angle0() -> this.angle(v3(1, 0, 0)); // NOTE: sus for 3D...
	float angle(Vec3 other) -> c:Vector3Angle(this, other);

	Vec3 operator:*(Vec3 other) -> c:Vector3Multiply(this, other);
	// TODO: make this also operator (need overloads)
	Vec3 scale(float scale) -> c:Vector3Scale(this, scale);

	// TODO: operator:- (uop support!)
	Vec3 negate() -> c:Vector3Negate(this);

	Vec3 operator:/(Vec3 other) -> c:Vector3Divide(this, other);
	Vec3 divide(float divisor) -> v3(this.x / divisor, this.y / divisor, this.z / divisor);
	// TODO: operator:/(float xxx)

	Vec3 normalize() -> c:Vector3Normalize(this);

	// NOTE: uses rough equality... do we want that?
	bool operator:==(Vec3 other) -> c:Vector3Equals(this, other);
	// TODO: forgot to impl op:!=
	bool operator:!=(Vec3 other) -> !(this == other);

	Vec3 lerp(Vec3 other, float amount) -> c:Vector3Lerp(this, other, amount);

	// NOTE: what does this even do?
	// Vec3 move_towards(Vec3 other, float maxDistance) -> c:Vector3MoveTowards(this, other, maxDistance);

	Vec3 reflect(Vec3 normal) -> c:Vector3Reflect(this, normal);
	// Vec3 rotate(float angle) -> c:Vector3Rotate(this, angle);
	// NOTE: what? is this (1/x, 1/y)?
	Vec3 invert() -> c:Vector3Invert(this);
	Vec3 clamp(Vec3 min, Vec3 max) -> c:Vector3Clamp(this, min, max);
	Vec3 clamp_value(float min, float max) -> c:Vector3ClampValue(this, min, max);

	// TODO: other
	// Vector2 Vector2Transform(Vector2 v, Matrix mat);
}

@extern struct Vec4 {
	float x; float y; float z; float w;

	// TODO: ...
}

Vec2 v2(float x, float y) -> { :x, :y };
Vec3 v3(float x, float y, float z) -> { :x, :y, :z };

void pv(Vec2 v) {
	printf("(%f, %f)\n", v.x, v.y);
}

struct Cursor {
	static void Show() -> c:ShowCursor();
	static void Hide() -> c:HideCursor();
	static bool IsHidden() -> c:IsCursorHidden();
	static void Lock() -> c:EnableCursor();
	static void Unlock() -> c:DisableCursor();
	static bool IsOnScreen() -> c:IsCursorOnScreen();
}

struct Window {
	void Init(int width, int height, char^ title)
		-> c:InitWindow(width, height, title);

	void Close() -> c:CloseWindow();

	bool ShouldClose() -> c:WindowShouldClose();

	void SetSize(int width, int height) -> c:SetWindowSize(width, height);
	void SetPosition(int x, int y) -> c:SetWindowPosition(x, y);
}

enum TextPinKind {
	TopLeft, TopMiddle, TopRight, MiddleLeft, Middle, MiddleRight, BottomLeft, BottomMiddle, BottomRight,
}

// GlyphInfo, font characters glyphs info
@extern struct GlyphInfo {
    int value;              // Character value (Unicode)
    int offsetX;            // Character offset X when drawing
    int offsetY;            // Character offset Y when drawing
    int advanceX;           // Character advance position X
    Image image;            // Character image data
}

@extern struct Font {
	int baseSize;           // Base size (default chars height)
    int glyphCount;         // Number of glyph characters
    int glyphPadding;       // Padding around the glyph characters
    Texture texture;      // Texture atlas containing the glyphs
    Rectangle^ recs;        // Rectangles in texture for the glyphs
    GlyphInfo^ glyphs;      // Glyphs info data
}

struct Drawer {
	void Begin() -> c:BeginDrawing();
	void End() -> c:EndDrawing();
	void ClearBackground(Color color) -> c:ClearBackground(color);
	void Text(char^ text, int x, int y, int font_size, Color color)
		-> c:DrawText(text, x, y, font_size, color);

	void TextPro(Font font, char^ text, Vec2 position, Vec2 origin, float rotation, float fontSize, float spacing, Color tint) -> c:DrawTextPro(font, text, position, origin, rotation, fontSize, spacing, tint);

	void TextAngle(char^ text, Vec2 pin_pos, TextPinKind pin_location_kind, float rotation, float font_size, Color tint) -> this.TextAngleFont(c:GetFontDefault(), text, pin_pos, pin_location_kind, rotation, font_size, tint);

	void TextAngleFont(Font font, char^ text, Vec2 pin_pos, TextPinKind pin_location_kind, float rotation, float font_size, Color tint) {
		float spacing = 2;
		Vec2 pos = pin_pos;

		Vec2 text_dimens = c:MeasureTextEx(font, text, font_size, spacing);

		Vec2 origin = match (pin_location_kind) {
			.TopLeft      -> text_dimens * v2(0.0, 0.0),
			.TopMiddle    -> text_dimens * v2(0.5, 0.0),
			.TopRight     -> text_dimens * v2(1.0, 0.0),
			.MiddleLeft   -> text_dimens * v2(0.0, 0.5),
			.Middle       -> text_dimens * v2(0.5, 0.5),
			.MiddleRight  -> text_dimens * v2(1.0, 0.5),
			.BottomLeft   -> text_dimens * v2(0.0, 1.0),
			.BottomMiddle -> text_dimens * v2(0.5, 1.0),
			.BottomRight  -> text_dimens * v2(1.0, 1.0),
		};

		this.TextPro(font, text, pos, origin, rotation, font_size, spacing, tint);
	}

	// NOTE: more
	void Circle(Vec2 pos, float rad, Color color) -> c:DrawCircleV(pos.v(), rad, color);
	void Triangle(Vec2 p1, Vec2 p2, Vec2 p3, Color color) -> c:DrawTriangle(p1.v(), p2.v(), p3.v(), color);

	void Line(Vec2 p1, Vec2 p2, float thickness, Color color) -> c:DrawLineEx(p1.v(), p2.v(), thickness, color);

	void RectBetween(Vec2 tl, Vec2 br, Color color) -> c:DrawRectangleV(tl.v(), (br - tl).v(), color);
	void RectOutlineBetween(Vec2 tl, Vec2 br, Color color) -> this.RectOutline(tl, br - tl, color);
	void RectOutlineR(Rectangle rect, Color color) -> this.RectOutline(rect.tl(), rect.dimen(), color);
	void Rect(Vec2 tl, Vec2 dimens, Color color) -> c:DrawRectangleV(tl.v(), dimens.v(), color);
	void RectR(Rectangle rect, Color color) -> c:DrawRectangleV(rect.tl(), rect.dimen(), color);

	// draws outline ON border, not around size (pad rect by one for exterior!)
	void RectOutline(Vec2 tl, Vec2 dimens, Color color) {
		this.Rect(tl, v2(1, dimens.y), color);
		this.Rect(tl, v2(dimens.x, 1), color);
		this.Rect(tl + v2(0, dimens.y - 1), v2(dimens.x, 1), color);
		this.Rect(tl + v2(dimens.x - 1, 0), v2(1, dimens.y), color);
	}
	void RectRot(Vec2 tl, Vec2 dimens, float rot, Color color) {
		Rectangle rect = {
			.x = (tl.x + dimens.x / 2) as int, // adding half here to make up for origin offsetting
			.y = (tl.y + dimens.y / 2) as int,
			.width = (dimens.x) as int,
			.height = (dimens.y) as int,
		};
		Vec2 origin = dimens * v2(0.5, 0.5); // by default, center!
		return c:DrawRectanglePro(rect, origin.v(), rot, color);
	}

	void TextV(char^ text, Vec2 pos, int font_size, Color color) {
		this.Text(text, (pos.x) as int, (pos.y) as int, font_size, color);
	}
	void TextTemp(char^ text, Vec2 pos) {
		this.TextV(text, pos, 16, c:BLACK);
	}

	// TODO: width/height
	void Texture(Texture texture, Vec2 pos, Color color = Colors.White) {
		c:DrawTextureRec(texture, texture.SourceRect(), pos.v(), color);
	}
	
	void FlippedTexture(Texture texture, Vec2 pos, Color color = Colors.White) {
		Rectangle source_rect = texture.SourceRect();
		source_rect.height *= -1;
		c:DrawTextureRec(texture, source_rect, pos.v(), color);
	}

	void TextureAtSize(Texture texture, float x, float y, float width, float height, Color color = Colors.White) {
		Rectangle dest = {
			:x, :y, :width, :height
		};

		c:DrawTexturePro(texture, texture.SourceRect(), dest, v2(0, 0).v(), 0, color);
	}

	void TextureAtSizeV(Texture texture, Vec2 pos, Vec2 dimen, Color color = Colors.White) {
		Rectangle dest = RectV(pos, dimen);

		c:DrawTexturePro(texture, texture.SourceRect(), dest, v2(0, 0).v(), 0, color);
	}

	void TextureAtRect(Texture texture, Rectangle dest, Color color = Colors.White) {
		c:DrawTexturePro(texture, texture.SourceRect(), dest, v2(0, 0).v(), 0, color);
	}

	void TextureAtSizeVColor(Texture texture, Vec2 pos, Vec2 dimen, Color color = Colors.White) {
		Rectangle dest = RectV(pos, dimen);

		c:DrawTexturePro(texture, texture.SourceRect(), dest, v2(0, 0).v(), 0, color);
	}

	void TextureAtRectColor(Texture texture, Rectangle dest, Color color) {
		c:DrawTexturePro(texture, texture.SourceRect(), dest, v2(0, 0).v(), 0, color);
	}

	// void Texture(RenderTexture rt) {
	// 	this.TextureAt(rt, v2(0, 0));
	// }
}

struct ColorUtil {
    Color Lightgray; Color Gray; Color DarkGray; Color Yellow; Color Gold; Color Orange; Color Pink; Color Red; Color Maroon; Color Green; Color Lime; Color DarkGreen; Color SkyBlue; Color Blue; Color DarkBlue; Color Purple; Color Violet; Color DarkPurple; Color Beige; Color Brown; Color DarkBrown; Color White; Color Black; Color Blank; Color Magenta; Color RayWhite;
	Color Transparent;

	int hex_char(char c) {
		c:int res = c;
		if (res >= 48 && res <= 57) { // numbers 0-9
			res = res - 48;
		} else if (res >= 65 && res <= 70) { // characters A-F
			res = res - 65 + 10;
		} else if (res >= 97 && res <= 102) { // characters a-f
			res = res - 97 + 10;
		}
		return res;
	}

	// NOTE: hex_str should be WITHOUT leading #
	Color hex(char^ hex_str) {
		int r = this.hex_char(hex_str[0]) * 16 + this.hex_char(hex_str[1]);
		int g = this.hex_char(hex_str[2]) * 16 + this.hex_char(hex_str[3]);
		int b = this.hex_char(hex_str[4]) * 16 + this.hex_char(hex_str[5]);
		int a = 255;
		if (c:strlen(hex_str) >= 8) {
			a = this.hex_char(hex_str[6]) * 16 + this.hex_char(hex_str[7]);
		}

		return this.rgba(r, g, b, a);
	}

	Color rgb_f(float r, float g, float b) -> {
		.r = (255.0 * r) as int,
		.g = (255.0 * b) as int,
		.b = (255.0 * b) as int,
		.a = 255,
	};

	Color rgba_f(float r, float g, float b, float a) -> {
		.r = (255.0 * r) as int,
		.g = (255.0 * b) as int,
		.b = (255.0 * b) as int,
		.a = (255.0 * a) as int,
	};

	Color rgb(int r, int g, int b) -> {
		:r, :g, :b, .a = 255
	};
	Color rgba(int r, int g, int b, int a) -> {
		:r, :g, :b, :a
	};

	// hue in [0..360]
	// saturation/value in [0..1]
	Color hsv(float hue, float saturation, float value) -> c:ColorFromHSV(hue, saturation, value);
}

ColorUtil Colors = {
    .Lightgray = c:LIGHTGRAY,
    .Gray = c:GRAY,
    .DarkGray = c:DARKGRAY,
    .Yellow = c:YELLOW,
    .Gold = c:GOLD,
    .Orange = c:ORANGE,
    .Pink = c:PINK,
    .Red = c:RED,
    .Maroon = c:MAROON,
    .Green = c:GREEN,
    .Lime = c:LIME,
    .DarkGreen = c:DARKGREEN,
    .SkyBlue = c:SKYBLUE,
    .Blue = c:BLUE,
    .DarkBlue = c:DARKBLUE,
    .Purple = c:PURPLE,
    .Violet = c:VIOLET,
    .DarkPurple = c:DARKPURPLE,
    .Beige = c:BEIGE,
    .Brown = c:BROWN,
    .DarkBrown = c:DARKBROWN,
    .White = c:WHITE,
    .Black = c:BLACK,
    .Blank = c:BLANK,
    .Magenta = c:MAGENTA,
    .RayWhite = c:RAYWHITE,
	.Transparent = Color{ .r = 0, .g = 0, .b = 0, .a = 0 }
};

Rectangle RectV(Vec2 tl, Vec2 dimen) -> {
	.x = tl.x, .y = tl.y,
	.width = dimen.x, .height = dimen.y
};

Rectangle RectCenter(Vec2 pos, Vec2 dimen) -> {
	.x = pos.x - dimen.x / 2, .y = pos.y - dimen.y / 2,
	.width = dimen.x, .height = dimen.y
};

@extern struct Color {
	uchar r; // should be unsigned char
	uchar g;
	uchar b;
	uchar a;

	bool VisualEquals(Color other) {
		if (a == 0 && other.a == 0) { return true; }
		return r == other.r && g == other.g && b == other.b && a == other.a;
	}
}

@extern struct Rectangle {
	float x;
	float y;
	float width;
	float height;

	construct(float x, float y, float width, float height) -> {
		:x, :y, :width, :height
	};

	static Rectangle FromV(Vec2 tl, Vec2 dims) {
		return {
			.x = tl.x,
			.y = tl.y,
			.width = dims.x,
			.height = dims.y,
		};
	}

	static Rectangle Centered(Vec2 center, Vec2 dims) -> FromV(center - dims.divide(2), dims);

	Vec2 tl() -> { :x, :y };
	Vec2 tr() -> { .x = x + width, :y };
	Vec2 bl() -> { :x, .y = y + height };
	Vec2 br() -> { .x = x + width, .y = y + height };
	Vec2 dimen() -> { .x = width, .y = height };
	Vec2 center() -> this.tl() + this.dimen().divide(2);
	float b() -> y + height; // bottom
	float r() -> x + width; // right

	Rectangle operator:+(Vec2 translate) -> {
		.x = x + translate.x,
		.y = y + translate.y,
		:width,
		:height
	};

	Rectangle operator:*(Vec2 scale) -> { // NOTE: pos (x, y) does not change
		:x,
		:y,
		.width = width * scale.x,
		.height = height * scale.y
	};

	Rectangle Inset(float amount) -> {
		.x = x + amount,
		.y = y + amount,
		.width = width - amount*2,
		.height = height - amount*2,
	};

	Rectangle Pad(float amount) -> {
		.x = x - amount,
		.y = y - amount,
		.width = width + amount*2,
		.height = height + amount*2,
	};

	// 16:9 (x_component = 16, y_component = 9)
	Rectangle FitIntoSelfWithAspectRatio(float x_component, float y_component) {
		float ratio = std.min(width / x_component, height / y_component);
		return Centered(center(), v2(x_component, y_component).scale(ratio));
	}

	bool Contains(Vec2 v) -> v.Between(this.tl(), this.br()); 

	char^ to_tstring() -> t"Rect({x=}, {y=}, {width=}, {height=})";
	char^ to_string() -> f"Rect({x=}, {y=}, {width=}, {height=})";
}

struct Point { // not a real raylib type, but is convenient
	int x; int y;

	char^ to_tstring() -> t"({x}, {y})";
	char^ to_string() -> f"({x}, {y})";

	Point operator:+(Point other) -> { .x = x + other.x, .y = y + other.y };
}

@extern struct Image {
	void^ data;
	int width;
	int height;
	int mipmaps; // 1 by default
	int format; // data format (PixelFormat type)

	Color get(Point p) -> this.getXY(p.x, p.y); // TODO: bound check w/ panic?
	Color getXY(int x, int y) -> c:GetImageColor(this, x, y);

	void set(Point p, Color color) -> this.setXY(p.x, p.y, color);
	void setXY(int x, int y, Color color) -> c:ImageDrawPixel(^this, x, y, color);

	void ExportTo(char^ file_path) -> c:ExportImage(this, file_path);

	void Unload() -> c:UnloadImage(this);

	static Self Load(char^ file_path) -> c:LoadImage(file_path);
}

@extern struct Texture {
	int width;
	int height;

	Rectangle SourceRect() -> {
		.x = 0, .y = 0, :width, :height // NOTE: negative height! - corrects for flipped storage!
	};

	// WARNING: !!!
	Texture Duplicate() {
		Image img = c:LoadImageFromTexture(this);
		Texture res = c:LoadTextureFromImage(img);
		c:UnloadImage(img);

		return res;
	}

	void delete() -> c:UnloadTexture(this);
}

// c:RenderTexture2D.texture -> c:Texture2D
@extern struct RenderTexture {
	construct (int width, int height) -> c:LoadRenderTexture(width, height);
	Texture texture;

	Texture into() -> texture;

	int width() -> texture.width;
	int height() -> texture.height;

	void Begin() -> c:BeginTextureMode(this);
	void End() -> c:EndTextureMode();

	void Clear() {
		this.Begin();
		d.ClearBackground(Color{ .r=0,.g=0,.b=0,.a=0});
		this.End();
	}

	void ClearBackground(Color color) {
		this.Begin();
		d.ClearBackground(color);
		this.End();
	}

	void delete() -> c:UnloadRenderTexture(this); // NOTE: don't call texture.delete(), I assume???
}

struct Mouse {
	Vec2 GetPos() -> c:GetMousePosition(); // TODO: bad

	bool LeftClickPressed() -> c:IsMouseButtonPressed(c:MOUSE_BUTTON_LEFT);
	bool LeftClickReleased() -> c:IsMouseButtonReleased(c:MOUSE_BUTTON_LEFT);
	bool LeftClickDown() -> c:IsMouseButtonDown(c:MOUSE_BUTTON_LEFT);
}

struct Keys {
	int A; int B; int C; int D; int E; int F; int G; int H; int I; int J; int K; int L; int M; int N; int O; int P; int Q; int R; int S; int T; int U; int V; int W; int X; int Y; int Z;
	int NUM_0; int NUM_1; int NUM_2; int NUM_3; int NUM_4; int NUM_5; int NUM_6; int NUM_7; int NUM_8; int NUM_9;
	int UP; int DOWN; int LEFT; int RIGHT;
	int SPACE;
	int TAB;
	int ENTER;
	int ESCAPE;
	int BACKSPACE;
	int SEMICOLON;
	// TODO: other special keys - see: https://github.com/raysan5/raylib/blob/master/src/raylib.h
}
Keys make_keys() -> {
	.A = c:KEY_A, .B = c:KEY_B, .C = c:KEY_C, .D = c:KEY_D, .E = c:KEY_E, .F = c:KEY_F, .G = c:KEY_G, .H = c:KEY_H, .I = c:KEY_I, .J = c:KEY_J, .K = c:KEY_K, .L = c:KEY_L, .M = c:KEY_M, .N = c:KEY_N, .O = c:KEY_O, .P = c:KEY_P, .Q = c:KEY_Q, .R = c:KEY_R, .S = c:KEY_S, .T = c:KEY_T, .U = c:KEY_U, .V = c:KEY_V, .W = c:KEY_W, .X = c:KEY_X, .Y = c:KEY_Y, .Z = c:KEY_Z,
	.NUM_0 = c:KEY_ZERO, .NUM_1 = c:KEY_ONE, .NUM_2 = c:KEY_TWO, .NUM_3 = c:KEY_THREE, .NUM_4 = c:KEY_FOUR, .NUM_5 = c:KEY_FIVE, .NUM_6 = c:KEY_SIX, .NUM_7 = c:KEY_SEVEN, .NUM_8 = c:KEY_EIGHT, .NUM_9 = c:KEY_NINE,
	.UP = c:KEY_UP, .DOWN = c:KEY_DOWN, .LEFT = c:KEY_LEFT, .RIGHT = c:KEY_RIGHT,
	.SPACE = c:KEY_SPACE,
	.TAB = c:KEY_TAB,
	.ENTER = c:KEY_ENTER,
	.ESCAPE = c:KEY_ESCAPE,
	.BACKSPACE = c:KEY_BACKSPACE,
	.SEMICOLON = c:KEY_SEMICOLON,
};

struct Keyboard {
	bool IsPressed(int keycode) -> c:IsKeyPressed(keycode);
	bool IsReleased(int keycode) -> c:IsKeyReleased(keycode);
	bool IsDown(int keycode) -> c:IsKeyDown(keycode);
	bool IsUp(int keycode) -> !c:IsKeyDown(keycode);
}

@extern
Color ColorLerp(Color from, Color to, float t);

// shaders ---
@extern struct Shader {
	void Begin() -> c:BeginShaderMode(this);
	void End() -> c:EndShaderMode();

	bool IsValid() -> c:IsShaderValid(this); // idk what this actually does lol - checks if valid I think?? - TODO: investigate & name better

	int GetShaderLoc(char^ uniform_name) -> c:GetShaderLocation(this, uniform_name);

	ShaderLocationHandle GetShaderLocHandle(char^ uniform_name) -> {
		.shader = this,
		.loc = this.GetShaderLoc(uniform_name)
	};

	void delete() -> c:UnloadShader(this);

	void SetInt(char^ uniform_name, int value) -> this.GetShaderLocHandle(uniform_name).SetInt(value);
	void SetFloat(char^ uniform_name, float value) -> this.GetShaderLocHandle(uniform_name).SetFloat(value);
	void SetVec2(char^ uniform_name, Vec2 value) -> this.GetShaderLocHandle(uniform_name).SetVec2(value);
	void SetVec3(char^ uniform_name, Vec3 value) -> this.GetShaderLocHandle(uniform_name).SetVec3(value);
	void SetVec4(char^ uniform_name, Vec4 value) -> this.GetShaderLocHandle(uniform_name).SetVec4(value);
	void SetTexture(char^ uniform_name, Texture value) -> this.GetShaderLocHandle(uniform_name).SetTexture(value);
	void SetRenderTexture(char^ uniform_name, RenderTexture value) -> this.GetShaderLocHandle(uniform_name).SetRenderTexture(value);
}

struct ShaderLocationHandle { // stack/mem Shader must stay valid!
	Shader shader;
	int loc;

	void SetInt(int value) -> c:SetShaderValue(shader, loc, ^value, c:SHADER_UNIFORM_INT);
	void SetFloat(float value) -> c:SetShaderValue(shader, loc, ^value, c:SHADER_UNIFORM_FLOAT);
	void SetVec2(Vec2 value) -> c:SetShaderValue(shader, loc, ^value, c:SHADER_UNIFORM_VEC2);
	void SetVec3(Vec3 value) -> c:SetShaderValue(shader, loc, ^value, c:SHADER_UNIFORM_VEC3);
	void SetVec4(Vec4 value) -> c:SetShaderValue(shader, loc, ^value, c:SHADER_UNIFORM_VEC4);
	void SetTexture(Texture value) -> c:SetShaderValueTexture(shader, loc, value);
	void SetRenderTexture(RenderTexture value) -> c:SetShaderValueTexture(shader, loc, value.texture);
}

Shader make_shader(char^ fragFileName) -> c:LoadShader(0, fragFileName);

//  3D ---------------------------------
@extern struct Camera {
    Vec3 position;       // Camera position
    Vec3 target;         // Camera target it looks-at
    Vec3 up;             // Camera up vector (rotation over its axis)
    float fovy;             // Camera field-of-view aperture in Y (degrees) in perspective, used as near plane width in orthographic
    int projection;         // Camera projection: CAMERA_PERSPECTIVE or CAMERA_ORTHOGRAPHIC
}

@extern struct Mesh {
	    int vertexCount;        // Number of vertices stored in arrays
    int triangleCount;      // Number of triangles stored (indexed or not)

    // Vertex attributes data
    float ^vertices;        // Vertex position (XYZ - 3 components per vertex) (shader-location = 0)
    float ^texcoords;       // Vertex texture coordinates (UV - 2 components per vertex) (shader-location = 1)
    float ^texcoords2;      // Vertex texture second coordinates (UV - 2 components per vertex) (shader-location = 5)
    float ^normals;         // Vertex normals (XYZ - 3 components per vertex) (shader-location = 2)
    float ^tangents;        // Vertex tangents (XYZW - 4 components per vertex) (shader-location = 4)
    // unsigned char ^colors;      // Vertex colors (RGBA - 4 components per vertex) (shader-location = 3)
    char ^colors;      // Vertex colors (RGBA - 4 components per vertex) (shader-location = 3)
    // unsigned short ^indices;    // Vertex indices (in case vertex data comes indexed)
    // TODO: short ^indices;    // Vertex indices (in case vertex data comes indexed)

    // Animation vertex data
    float ^animVertices;    // Animated vertex positions (after bones transformations)
    float ^animNormals;     // Animated normals (after bones transformations)
    // unsigned char ^boneIds; // Vertex bone ids, max 255 bone ids, up to 4 bones influence by vertex (skinning) (shader-location = 6)
    char ^boneIds; // Vertex bone ids, max 255 bone ids, up to 4 bones influence by vertex (skinning) (shader-location = 6)
    float ^boneWeights;     // Vertex bone weight, up to 4 bones influence by vertex (skinning) (shader-location = 7)
    // Matrix TODO: ^boneMatrices;   // Bones animated transformation matrices
    int boneCount;          // Number of bones

    // OpenGL identifiers
    // unsigned int vaoId;     // OpenGL Vertex Array Object id
    int ^vboId;    // OpenGL Vertex Buffer Objects id (default vertex data)
}
// /3D ---------------------------------

// globals ---
Drawer d;
Window window;
Mouse mouse;
Keyboard key;
Keys KEY = make_keys();

c:c:`
#pragma GCC diagnostic pop
`;


// PROGRAM GLOBALS (CONVENIENT, WELL-INCLUDED LOCATION...) ------------------
// these are not raylib things, they are for edit!!!!! but because of non-cyclic file includes, it's easiest to put here!
// NOTE: these should not remain in rl.cr for external use!!!
Vec2 mp_world_space; // mouse-pos-world-space
