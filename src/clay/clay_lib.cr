include path("../../raylib");

import std;
import rl;

c:import <"float.h">;
c:import "clay.h";

c:`
extern void Clay_Raylib_Initialize(int width, int height, const char *title, unsigned int flags);
extern void Clay_Raylib_Close();
extern Clay_Dimensions Raylib_MeasureText(Clay_StringSlice text, Clay_TextElementConfig *config, void *userData);
extern void Clay_Raylib_Render(Clay_RenderCommandArray renderCommands, Font* fonts);
`;

c:c:`
#define CLAY_IMPLEMENTATION
#include "clay.h" // clay implementation, should be in ONE C FILE ONLY
// #include "clay_renderer_raylib.c" // clay renderer implementation, should be in ONE C FILE ONLY
`;

@extern struct Clay_Context {
	// TODO: ...
}

@extern struct Clay_ErrorType {
	bool operator:==(Clay_ErrorType other) -> other as c:int == this as c:int;
} // enum
// A text measurement function wasn't provided using Clay_SetMeasureTextFunction(), or the provided function was null.
@extern Clay_ErrorType CLAY_ERROR_TYPE_TEXT_MEASUREMENT_FUNCTION_NOT_PROVIDED;
// Clay attempted to allocate its internal data structures but ran out of space.
// The arena passed to Clay_Initialize was created with a capacity smaller than that required by Clay_MinMemorySize().
@extern Clay_ErrorType CLAY_ERROR_TYPE_ARENA_CAPACITY_EXCEEDED;
// Clay ran out of capacity in its internal array for storing elements. This limit can be increased with Clay_SetMaxElementCount().
@extern Clay_ErrorType CLAY_ERROR_TYPE_ELEMENTS_CAPACITY_EXCEEDED;
// Clay ran out of capacity in its internal array for storing elements. This limit can be increased with Clay_SetMaxMeasureTextCacheWordCount().
@extern Clay_ErrorType CLAY_ERROR_TYPE_TEXT_MEASUREMENT_CAPACITY_EXCEEDED;
// Two elements were declared with exactly the same ID within one layout.
@extern Clay_ErrorType CLAY_ERROR_TYPE_DUPLICATE_ID;
// A floating element was declared using CLAY_ATTACH_TO_ELEMENT_ID and either an invalid .parentId was provided or no element with the provided .parentId was found.
@extern Clay_ErrorType CLAY_ERROR_TYPE_FLOATING_CONTAINER_PARENT_NOT_FOUND;
// An element was declared that using CLAY_SIZING_PERCENT but the percentage value was over 1. Percentage values are expected to be in the 0-1 range.
@extern Clay_ErrorType CLAY_ERROR_TYPE_PERCENTAGE_OVER_1;
// Clay encountered an internal error. It would be wonderful if you could report this so we can fix it!
@extern Clay_ErrorType CLAY_ERROR_TYPE_INTERNAL_ERROR;

// Data to identify the error that clay has encountered.
@extern struct Clay_ErrorData {
    // Represents the type of error clay encountered while computing layout.
    // CLAY_ERROR_TYPE_TEXT_MEASUREMENT_FUNCTION_NOT_PROVIDED - A text measurement function wasn't provided using Clay_SetMeasureTextFunction(), or the provided function was null.
    // CLAY_ERROR_TYPE_ARENA_CAPACITY_EXCEEDED - Clay attempted to allocate its internal data structures but ran out of space. The arena passed to Clay_Initialize was created with a capacity smaller than that required by Clay_MinMemorySize().
    // CLAY_ERROR_TYPE_ELEMENTS_CAPACITY_EXCEEDED - Clay ran out of capacity in its internal array for storing elements. This limit can be increased with Clay_SetMaxElementCount().
    // CLAY_ERROR_TYPE_TEXT_MEASUREMENT_CAPACITY_EXCEEDED - Clay ran out of capacity in its internal array for storing elements. This limit can be increased with Clay_SetMaxMeasureTextCacheWordCount().
    // CLAY_ERROR_TYPE_DUPLICATE_ID - Two elements were declared with exactly the same ID within one layout.
    // CLAY_ERROR_TYPE_FLOATING_CONTAINER_PARENT_NOT_FOUND - A floating element was declared using CLAY_ATTACH_TO_ELEMENT_ID and either an invalid .parentId was provided or no element with the provided .parentId was found.
    // CLAY_ERROR_TYPE_PERCENTAGE_OVER_1 - An element was declared that using CLAY_SIZING_PERCENT but the percentage value was over 1. Percentage values are expected to be in the 0-1 range.
    // CLAY_ERROR_TYPE_INTERNAL_ERROR - Clay encountered an internal error. It would be wonderful if you could report this so we can fix it!
    Clay_ErrorType errorType;
    // A string containing human-readable error text that explains the error in more detail.
    Clay_String errorText;
    // A transparent pointer passed through from when the error handler was first provided.
    void^ userData;
}

// Note: Clay_String is not guaranteed to be null terminated. It may be if created from a literal C string,
// but it is also used to represent slices.
@extern struct Clay_String {
    // Set this boolean to true if the char* data underlying this string will live for the entire lifetime of the program.
    // This will automatically be set for strings created with CLAY_STRING, as the macro requires a string literal.
    bool isStaticallyAllocated = false;
    int length = 0;
    // The underlying character memory. Note: this will not be copied and will not extend the lifetime of the underlying memory.
    char^ chars = NULL;

	construct(char^ str_that_we_trust_will_live_the_frame) -> {
		.length = strlen(str_that_we_trust_will_live_the_frame),
		.chars = str_that_we_trust_will_live_the_frame,
	};
}

// Clay_StringSlice is used to represent non owning string slices, and includes
// a baseChars field which points to the string this slice is derived from.
@extern struct Clay_StringSlice {
    int length = 0;
    char^ chars = NULL;
    char^ baseChars = NULL; // The source string / char* that this slice was derived from
}


// Primarily created via the CLAY_ID(), CLAY_IDI(), CLAY_ID_LOCAL() and CLAY_IDI_LOCAL() macros.
// Represents a hashed string ID used for identifying and finding specific clay UI elements, required
// by functions such as Clay_PointerOver() and Clay_GetElementData().
@extern struct Clay_ElementId {
	uint id = 0; // The resulting hash generated from the other fields.
    uint offset = 0; // A numerical offset applied after computing the hash from stringId.
    uint baseId = 0; // A base hash value to start from, for example the parent element ID is used when calculating CLAY_ID_LOCAL().
    Clay_String stringId = {}; // The string id to hash.
	construct(char^ str_that_will_live_to_next_frame, uint offset = 0) { // TODO: does that mean into next frame, or till?
		return Clay__HashString(.(str_that_will_live_to_next_frame), offset, 0);
	}
}

@extern struct Clay__SizingType {} // extern enum?
@extern struct Clay_SizingAxis {
	static Self fixed(float size) -> CLAY_SIZING_FIXED(size);
	static Self fit(float min, float max = c:FLT_MAX) -> CLAY_SIZING_FIT(min, max);
	static Self grow(float min = 0, float max = c:FLT_MAX) -> CLAY_SIZING_GROW(min, max);
	static Self portion(float portion_01) -> CLAY_SIZING_PERCENT(portion_01);
	static Self Zero = .portion(0);
// union {
//        Clay_SizingMinMax minMax; // Controls the minimum and maximum size in pixels that this element is allowed to grow or shrink to, overriding sizing types such as FIT or GROW.
//        float percent; // Expects 0-1 range. Clamps the axis size to a percent of the parent container's axis size minus padding and child gaps.
//    } size;

	// c:whatever_the_unions_type_wants_to_be_called size; // .mixMax or .percent !
	// Clay__SizingType type; // Controls how the element takes up space inside its parent container.
	// TODO: ^
}
@extern struct Clay_Sizing {
	Clay_SizingAxis width = {}; // Controls the width sizing of the element, along the x axis.
	Clay_SizingAxis height = {};  // Controls the height sizing of the element, along the y axis.
	construct(float fixed_width, float fixed_height) -> {
		.width = CLAY_SIZING_FIXED(fixed_width),
		.height = CLAY_SIZING_FIXED(fixed_height),
	};

	static Self Grow() -> {
		.width = CLAY_SIZING_GROW(),
		.height = CLAY_SIZING_GROW(),
	};

	static Self Zero = {
		.width = .portion(0),
		.height = .portion(0),
	};

	Self FlipIf(bool cond) -> (cond) ? { .width = height, .height = width } | this;
}
@extern struct Clay_Padding {
    ushort left = 0; // uint16_t's
    ushort right = 0;
    ushort top = 0;
    ushort bottom = 0;

	construct (ushort padding_all_sides) -> {
		padding_all_sides, padding_all_sides, padding_all_sides, padding_all_sides
	};

	static Self XY(ushort horiz, ushort vert) -> {
		horiz, horiz, vert, vert
	};

	Self FlipIf(bool cond) -> (cond)
		? { .left = top, .right = bottom, .top = left, .bottom = right}
		| this;
}

@extern struct Clay_LayoutAlignmentX { }
@extern struct Clay_LayoutAlignmentY { }

// (Default) Aligns child elements to the left hand side of this element, offset by padding.width.left
@extern Clay_LayoutAlignmentX CLAY_ALIGN_X_LEFT;
// Aligns child elements to the right hand side of this element, offset by padding.width.right
@extern Clay_LayoutAlignmentX CLAY_ALIGN_X_RIGHT;
// Aligns child elements horizontally to the center of this element
@extern Clay_LayoutAlignmentX CLAY_ALIGN_X_CENTER;

// (Default) Aligns child elements to the top of this element, offset by padding.width.top
@extern Clay_LayoutAlignmentY CLAY_ALIGN_Y_TOP;
// Aligns child elements to the bottom of this element, offset by padding.width.bottom
@extern Clay_LayoutAlignmentY CLAY_ALIGN_Y_BOTTOM;
// Aligns child elements vertically to the center of this element
@extern Clay_LayoutAlignmentY CLAY_ALIGN_Y_CENTER;

@extern struct Clay_ChildAlignment {
	Clay_LayoutAlignmentX x = CLAY_ALIGN_X_LEFT; // Controls alignment of children along the x axis.
    Clay_LayoutAlignmentY y = CLAY_ALIGN_Y_TOP; // Controls alignment of children along the y axis.

	static Self Center() -> { .x = CLAY_ALIGN_X_CENTER, .y = CLAY_ALIGN_Y_CENTER };
	static Self CenterX() -> { .x = CLAY_ALIGN_X_CENTER };
	static Self CenterY() -> { .y = CLAY_ALIGN_Y_CENTER };
}

@extern struct Clay_LayoutDirection {
	Self FlipIf(bool cond) -> (cond)
		? (
			(this == CLAY_LEFT_TO_RIGHT)
			? CLAY_TOP_TO_BOTTOM
			| CLAY_LEFT_TO_RIGHT
		)
		| this;

	bool operator:==(Self other) -> this as c:int == other as c:int;
	bool operator:!=(Self other) -> this as c:int != other as c:int;
}
// (Default) Lays out child elements from left to right with increasing x.
@extern Clay_LayoutDirection CLAY_LEFT_TO_RIGHT;
// Lays out child elements from top to bottom with increasing y.
@extern Clay_LayoutDirection CLAY_TOP_TO_BOTTOM;

@extern struct Clay_LayoutConfig {
		// NOTE: for real 0-sizing use .portion, instead of .fixed (since .fixed(0) is the zero value, which defaults to growing to fit children)
    Clay_Sizing sizing = {}; // Controls the sizing of this element inside it's parent container, including FIT, GROW, PERCENT and FIXED sizing.
    Clay_Padding padding = {}; // Controls "padding" in pixels, which is a gap between the bounding box of this element and where its children will be placed.

    ushort childGap = 0; // Controls the gap in pixels between child elements along the layout axis (horizontal gap for LEFT_TO_RIGHT, vertical gap for TOP_TO_BOTTOM). NOTE: was uint16_t

    Clay_ChildAlignment childAlignment = {}; // Controls how child elements are aligned on each axis.
    Clay_LayoutDirection layoutDirection = CLAY_LEFT_TO_RIGHT; // Controls the direction in which child elements will be automatically laid out.
}
@extern struct Clay_CornerRadius {
    float topLeft;
    float topRight;
    float bottomLeft;
    float bottomRight;

	construct (float radius) -> {
		radius, radius, radius, radius
	};
}

@extern struct Clay_ImageElementConfig {
    void^ imageData = NULL; // A transparent pointer used to pass image data through to the renderer.

	construct(Texture& texture_that_must_stay_alive_for_frame) -> {
		.imageData = ^texture_that_must_stay_alive_for_frame,
	};
}

@extern struct Clay_FloatingAttachPointType { } // enum
@extern Clay_FloatingAttachPointType CLAY_ATTACH_POINT_LEFT_TOP;
@extern Clay_FloatingAttachPointType CLAY_ATTACH_POINT_LEFT_CENTER;
@extern Clay_FloatingAttachPointType CLAY_ATTACH_POINT_LEFT_BOTTOM;
@extern Clay_FloatingAttachPointType CLAY_ATTACH_POINT_CENTER_TOP;
@extern Clay_FloatingAttachPointType CLAY_ATTACH_POINT_CENTER_CENTER;
@extern Clay_FloatingAttachPointType CLAY_ATTACH_POINT_CENTER_BOTTOM;
@extern Clay_FloatingAttachPointType CLAY_ATTACH_POINT_RIGHT_TOP;
@extern Clay_FloatingAttachPointType CLAY_ATTACH_POINT_RIGHT_CENTER;
@extern Clay_FloatingAttachPointType CLAY_ATTACH_POINT_RIGHT_BOTTOM;

@extern struct Clay_FloatingAttachPoints {
    Clay_FloatingAttachPointType element = CLAY_ATTACH_POINT_LEFT_TOP; // Controls the origin point on a floating element that attaches to its parent.
    Clay_FloatingAttachPointType parent = CLAY_ATTACH_POINT_LEFT_TOP; // Controls the origin point on the parent element that the floating element attaches to.
}

@extern struct Clay_PointerCaptureMode {} // enum
@extern Clay_PointerCaptureMode CLAY_POINTER_CAPTURE_MODE_CAPTURE;
@extern Clay_PointerCaptureMode CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH;

@extern struct Clay_FloatingAttachToElement {} // enum
// (default) Disables floating for this element.
@extern Clay_FloatingAttachToElement CLAY_ATTACH_TO_NONE;
// Attaches this floating element to its parent, positioned based on the .attachPoints and .offset fields.
@extern Clay_FloatingAttachToElement CLAY_ATTACH_TO_PARENT;
// Attaches this floating element to an element with a specific ID, specified with the .parentId field. positioned based on the .attachPoints and .offset fields.
@extern Clay_FloatingAttachToElement CLAY_ATTACH_TO_ELEMENT_WITH_ID;
// Attaches this floating element to the root of the layout, which combined with the .offset field provides functionality similar to "absolute positioning".
@extern Clay_FloatingAttachToElement CLAY_ATTACH_TO_ROOT;


@extern struct Clay_FloatingElementConfig {
	// Offsets this floating element by the provided x,y coordinates from its attachPoints.
    Vec2 offset = {};
    // Expands the boundaries of the outer floating element without affecting its children.
    Clay_Dimensions expand = {};
    // When used in conjunction with .attachTo = CLAY_ATTACH_TO_ELEMENT_WITH_ID, attaches this floating element to the element in the hierarchy with the provided ID.
    // Hint: attach the ID to the other element with .id = CLAY_ID("yourId"), and specify the id the same way, with .parentId = CLAY_ID("yourId").id
    uint parentId = 0;
    // Controls the z index of this floating element and all its children. Floating elements are sorted in ascending z order before output.
    // zIndex is also passed to the renderer for all elements contained within this floating element.
    ushort zIndex = 0;
    // Controls how mouse pointer events like hover and click are captured or passed through to elements underneath / behind a floating element.
    // Enum is of the form CLAY_ATTACH_POINT_foo_bar. See Clay_FloatingAttachPoints for more details.
    // Note: see <img src="https://github.com/user-attachments/assets/b8c6dfaa-c1b1-41a4-be55-013473e4a6ce />
    // and <img src="https://github.com/user-attachments/assets/ebe75e0d-1904-46b0-982d-418f929d1516 /> for a visual explanation.
    Clay_FloatingAttachPoints attachPoints = {};
    // Controls how mouse pointer events like hover and click are captured or passed through to elements underneath a floating element.
    // CLAY_POINTER_CAPTURE_MODE_CAPTURE (default) - "Capture" the pointer event and don't allow events like hover and click to pass through to elements underneath.
    // CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH - Transparently pass through pointer events like hover and click to elements underneath the floating element.
    Clay_PointerCaptureMode pointerCaptureMode = CLAY_POINTER_CAPTURE_MODE_CAPTURE;
    // Controls which element a floating element is "attached" to (i.e. relative offset from).
    // CLAY_ATTACH_TO_NONE (default) - Disables floating for this element.
    // CLAY_ATTACH_TO_PARENT - Attaches this floating element to its parent, positioned based on the .attachPoints and .offset fields.
    // CLAY_ATTACH_TO_ELEMENT_WITH_ID - Attaches this floating element to an element with a specific ID, specified with the .parentId field. positioned based on the .attachPoints and .offset fields.
    // CLAY_ATTACH_TO_ROOT - Attaches this floating element to the root of the layout, which combined with the .offset field provides functionality similar to "absolute positioning".
    Clay_FloatingAttachToElement attachTo = CLAY_ATTACH_TO_NONE;
}
@extern struct Clay_CustomElementConfig {
    // A transparent pointer through which you can pass custom data to the renderer.
    // Generates CUSTOM render commands.
    void^ customData;
}
@extern struct Clay_ClipElementConfig {
    bool horizontal = false; // Clip overflowing elements on the X axis and allow scrolling left and right.
    bool vertical = false; // Clip overflowing elements on the YU axis and allow scrolling up and down.
    Vec2 childOffset = {}; // Offsets the x,y positions of all child elements. Used primarily for scrolling containers.
}

@extern struct Clay_TextElementConfigWrapMode {} // enum...
// (default) breaks on whitespace characters.
@extern Clay_TextElementConfigWrapMode CLAY_TEXT_WRAP_WORDS;
// Don't break on space characters, only on newlines.
@extern Clay_TextElementConfigWrapMode CLAY_TEXT_WRAP_NEWLINES;
// Disable text wrapping entirely.
@extern Clay_TextElementConfigWrapMode CLAY_TEXT_WRAP_NONE;

@extern struct Clay_TextAlignment {} // enum
// (default) Horizontally aligns wrapped lines of text to the left hand side of their bounding box.
@extern Clay_TextAlignment CLAY_TEXT_ALIGN_LEFT;
// Horizontally aligns wrapped lines of text to the center of their bounding box.
@extern Clay_TextAlignment CLAY_TEXT_ALIGN_CENTER;
// Horizontally aligns wrapped lines of text to the right hand side of their bounding box.
@extern Clay_TextAlignment CLAY_TEXT_ALIGN_RIGHT;

@extern struct Clay_TextElementConfig {
	// A pointer that will be transparently passed through to the resulting render command.
    void^ userData = NULL;
    // The RGBA color of the font to render, conventionally specified as 0-255.
    Color textColor = Colors.Black;
    // An integer transparently passed to Clay_MeasureText to identify the font to use.
    // The debug view will pass fontId = 0 for its internal text.
    ushort fontId = 0;
    // Controls the size of the font. Handled by the function provided to Clay_MeasureText.
    ushort fontSize = 16; // TODO: diff default?
    // Controls extra horizontal spacing between characters. Handled by the function provided to Clay_MeasureText.
    ushort letterSpacing = 0;
    // Controls additional vertical space between wrapped lines of text.
    ushort lineHeight = 0;
    // Controls how text "wraps", that is how it is broken into multiple lines when there is insufficient horizontal space.
    // CLAY_TEXT_WRAP_WORDS (default) breaks on whitespace characters.
    // CLAY_TEXT_WRAP_NEWLINES doesn't break on space characters, only on newlines.
    // CLAY_TEXT_WRAP_NONE disables wrapping entirely.
    Clay_TextElementConfigWrapMode wrapMode = CLAY_TEXT_WRAP_WORDS;
    // Controls how wrapped lines of text are horizontally aligned within the outer text bounding box.
    // CLAY_TEXT_ALIGN_LEFT (default) - Horizontally aligns wrapped lines of text to the left hand side of their bounding box.
    // CLAY_TEXT_ALIGN_CENTER - Horizontally aligns wrapped lines of text to the center of their bounding box.
    // CLAY_TEXT_ALIGN_RIGHT - Horizontally aligns wrapped lines of text to the right hand side of their bounding box.
    Clay_TextAlignment textAlignment = CLAY_TEXT_ALIGN_LEFT;
}

@extern struct Clay_BorderWidth {
	ushort left = 0; // uint_16's
    ushort right = 0;
    ushort top = 0;
    ushort bottom = 0;
    // Creates borders between each child element, depending on the .layoutDirection.
    // e.g. for LEFT_TO_RIGHT, borders will be vertical lines, and for TOP_TO_BOTTOM borders will be horizontal lines.
    // .betweenChildren borders will result in individual RECTANGLE render commands being generated.
    ushort betweenChildren = 0;

	construct(ushort all_sides) -> {
		.left = all_sides,
		.right = all_sides,
		.top = all_sides,
		.bottom = all_sides,
		.betweenChildren = 0,
	};
}
@extern struct Clay_BorderElementConfig {
    Color color = Colors.Black; // Controls the color of all borders with width > 0. Conventionally represented as 0-255, but interpretation is up to the renderer.
    Clay_BorderWidth width = {}; // Controls the widths of individual borders. At least one of these should be > 0 for a BORDER render command to be generated.

	construct(ushort all_sides, Color color) -> {
		:color,
		.width = .(all_sides)
	};

	static Self Right(ushort width, Color color) -> {
		:color,
		.width = {
			.right = width,
		}
	};
	static Self Left(ushort width, Color color) -> {
		:color,
		.width = {
			.left = width,
		}
	};
	static Self Top(ushort width, Color color) -> {
		:color,
		.width = {
			.top = width,
		}
	};
	static Self Bottom(ushort width, Color color) -> {
		:color,
		.width = {
			.bottom = width,
		}
	};

	static Self Vert(ushort vert_width, Color color) -> {
		:color,
		.width = {
			.top = vert_width,
			.bottom = vert_width,
		}
	};

	static Self VertBetween(ushort vert_width, Color color) -> {
		:color,
		.width = {
			.top = vert_width,
			.bottom = vert_width,
			.betweenChildren = vert_width,
		}
	};

	static Self Between(ushort vert_width, Color color) -> {
		:color,
		.width = {
			.betweenChildren = vert_width,
		}
	};
}

@extern
struct Clay_ElementDeclaration {
    // Primarily created via the CLAY_ID(), CLAY_IDI(), CLAY_ID_LOCAL() and CLAY_IDI_LOCAL() macros.
    // Represents a hashed string ID used for identifying and finding specific clay UI elements, required by functions such as Clay_PointerOver() and Clay_GetElementData().
    Clay_ElementId id = {};
    // Controls various settings that affect the size and position of an element, as well as the sizes and positions of any child elements.
    Clay_LayoutConfig layout = {};
    // Controls the background color of the resulting element.
    // By convention specified as 0-255, but interpretation is up to the renderer.
    // If no other config is specified, .backgroundColor will generate a RECTANGLE render command, otherwise it will be passed as a property to IMAGE or CUSTOM render commands.
    Color backgroundColor = Colors.Transparent;
    // Controls the "radius", or corner rounding of elements, including rectangles, borders and images.
    Clay_CornerRadius cornerRadius = .(0);
    // Controls settings related to image elements.
    Clay_ImageElementConfig image = {};
    // Controls whether and how an element "floats", which means it layers over the top of other elements in z order, and doesn't affect the position and size of siblings or parent elements.
    // Note: in order to activate floating, .floating.attachTo must be set to something other than the default value.
    Clay_FloatingElementConfig floating = {};
    // Used to create CUSTOM render commands, usually to render element types not supported by Clay.
    Clay_CustomElementConfig custom = { .customData = NULL };
    // Controls whether an element should clip its contents and allow scrolling rather than expanding to contain them.
    Clay_ClipElementConfig clip = {};
    // Controls settings related to element borders, and will generate BORDER render commands.
    Clay_BorderElementConfig border = {};
    // A pointer that will be transparently passed through to resulting render commands.
    void^ userData = NULL;
}

@extern struct Clay_Arena {
	c:uintptr_t nextAllocation;
	c:size_t capacity;
	char^ memory;
}


@extern struct Clay_ErrorHandler {
    // A user provided function to call when Clay encounters an error during layout.
    // void (*errorHandlerFunction)(Clay_ErrorData errorText);
	// TODO: c:any !
	// c:any errorHandlerFunction;
	c:void^ errorHandlerFunction;
    // A pointer that will be transparently passed through to the error handler when it is called.
    void^ userData;
}

@extern struct Clay_RenderCommand {
	// TODO: ...
}
@extern struct Clay_RenderCommandArray {
	int capacity;
	int length;
	Clay_RenderCommand^ internalArray;
}

@extern struct Clay_Dimensions {
	float width = 0; // TODO: don't default? so that both must be filled? + default constructor?
	float height = 0;
}

@extern struct Clay_ScrollContainerData {
    // Note: This is a pointer to the real internal scroll position, mutating it may cause a change in final layout.
    // Intended for use with external functionality that modifies scroll position, such as scroll bars or auto scrolling.
    Vec2^ scrollPosition;
    // The bounding box of the scroll element.
    Clay_Dimensions scrollContainerDimensions;
    // The outer dimensions of the inner scroll container content, including the padding of the parent scroll container.
    Clay_Dimensions contentDimensions;
    // The config that was originally passed to the scroll element.
    Clay_ClipElementConfig config;
    // Indicates whether an actual scroll container matched the provided ID or if the default struct was returned.
    bool found;
}

// Bounding box and other data for a specific UI element.
@extern struct Clay_ElementData {
    // The rectangle that encloses this UI element, with the position relative to the root of the layout.
    Rectangle boundingBox;
    // Indicates whether an actual Element matched the provided ID or if the default struct was returned.
    bool found;
}

struct Clay_FrameGlobalData {
	Vec2 mouse_pos;
}

// -----------------------------------------
// Clay_XXX functions ----------------------
// -----------------------------------------
struct Clay {
	static Clay_FrameGlobalData? frame_global_data = none;

	static void SetFrameGlobalData(Clay_FrameGlobalData new_frame_global_data) {
		frame_global_data = new_frame_global_data;
	}

	static Clay_FrameGlobalData& GetFrameGlobalData() -> frame_global_data.! else panic("GetFrameGlobalData-Error: SetFrameGlobalData not called!");

	static Clay_FloatingElementConfig FloatingPassthru(Vec2 offset) -> {
		.attachTo = CLAY_ATTACH_TO_PARENT,
		:offset,
		// .attachPoints = {
		// 	.element = CLAY_ATTACH_POINT_CENTER_CENTER,
		// 	.parent = CLAY_ATTACH_POINT_LEFT_CENTER,
		// },
		.pointerCaptureMode = CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH,
	};

	// Returns the size, in bytes, of the minimum amount of memory Clay requires to operate at its current settings.
	static ulong MinMemorySize() -> c:Clay_MinMemorySize();

	// Creates an arena for clay to use for its internal allocations, given a certain capacity in bytes and a pointer to an allocation of at least that size.
	// Intended to be used with Clay_MinMemorySize in the following way:
	// uint32_t minMemoryRequired = Clay_MinMemorySize();
	// Clay_Arena clayMemory = Clay_CreateArenaWithCapacityAndMemory(minMemoryRequired, malloc(minMemoryRequired));
	static Clay_Arena CreateArenaWithCapacityAndMemory(c:uint64_t totalMemorySize) -> c:Clay_CreateArenaWithCapacityAndMemory(totalMemorySize, malloc(totalMemorySize));

	static void Raylib_Initialize(int window_width, int window_height, char^ window_name, int flags) { c:Clay_Raylib_Initialize(window_width, window_height, window_name, flags); }

	// TODO: can we return void's? (is this good w/ all compilers?)
	static void Raylib_Close() -> c:Clay_Raylib_Close();

	static void Raylib_Render(Clay_RenderCommandArray render_commands, Font^ fonts) -> c:Clay_Raylib_Render(render_commands, fonts);

	static void SetDebugModeEnabled(bool enabled) -> c:Clay_SetDebugModeEnabled(enabled);

	static void BeginLayout() -> c:Clay_BeginLayout();
	static Clay_RenderCommandArray EndLayout() -> c:Clay_EndLayout();

	// Updates the state of Clay's internal scroll data, updating scroll content positions if scrollDelta is non zero, and progressing momentum scrolling.
	// - enableDragScrolling when set to true will enable mobile device like "touch drag" scroll of scroll containers, including momentum scrolling after the touch has ended.
	// - scrollDelta is the amount to scroll this frame on each axis in pixels.
	// - deltaTime is the time in seconds since the last "frame" (scroll update)
	static void UpdateScrollContainers(bool enableDragScrolling, Vec2 scrollDelta, float deltaTime) -> c:Clay_UpdateScrollContainers(enableDragScrolling, scrollDelta, deltaTime);

	// Sets the state of the "pointer" (i.e. the mouse or touch) in Clay's internal data. Used for detecting and responding to mouse events in the debug view,
	// as well as for Clay_Hovered() and scroll element handling.
	static void SetPointerState(Vec2 position, bool pointerDown) -> c:Clay_SetPointerState(position, pointerDown);

	// Updates the layout dimensions in response to the window or outer container being resized.
	static void SetLayoutDimensions(Clay_Dimensions dimensions) -> c:Clay_SetLayoutDimensions(dimensions);

	// Returns data representing the state of the scrolling element with the provided ID.
	// The returned Clay_ScrollContainerData contains a `found` bool that will be true if a scroll element was found with the provided ID.
	// An imperative function that returns true if the pointer position provided by Clay_SetPointerState is within the element with the provided ID's bounding box.
	// This ID can be calculated either with CLAY_ID() for string literal IDs, or Clay_GetElementId for dynamic strings.
	static Clay_ScrollContainerData GetScrollContainerData(Clay_ElementId id) -> c:Clay_GetScrollContainerData(id);

	// An imperative function that returns true if the pointer position provided by Clay_SetPointerState is within the element with the provided ID's bounding box.
	// This ID can be calculated either with CLAY_ID() for string literal IDs, or Clay_GetElementId for dynamic strings.
	static bool PointerOver(Clay_ElementId elementId) -> c:Clay_PointerOver(elementId);

	// Returns true if the pointer position provided by Clay_SetPointerState is within the current element's bounding box.
	// Works during element declaration, e.g. CLAY({ .backgroundColor = Clay_Hovered() ? BLUE : RED });
	static bool Hovered() -> c:Clay_Hovered();

	static bool Pressed() -> c:Clay_Hovered() && mouse.LeftClickPressed();

	// // Bind a callback that will be called when the pointer position provided by Clay_SetPointerState is within the current element's bounding box.
	// // - onHoverFunction is a function pointer to a user defined function.
	// // - userData is a pointer that will be transparently passed through when the onHoverFunction is called.
	// TODO: need better function pointer (or typedef)
	// void Clay_OnHover(void (*onHoverFunction)(Clay_ElementId elementId, Clay_PointerData pointerData, intptr_t userData), intptr_t userData);

	// Initialize Clay's internal arena and setup required data before layout can begin. Only needs to be called once.
	// - arena can be created using Clay_CreateArenaWithCapacityAndMemory()
	// - layoutDimensions are the initial bounding dimensions of the layout (i.e. the screen width and height for a full screen layout)
	// - errorHandler is used by Clay to inform you if something has gone wrong in configuration or layout.
	static Clay_Context^ Initialize(Clay_Arena arena, Clay_Dimensions layoutDimensions, Clay_ErrorHandler errorHandler) -> c:Clay_Initialize(arena, layoutDimensions, errorHandler);
	// Returns the Context that clay is currently using. Used when using multiple instances of clay simultaneously.
	static Clay_Context^ GetCurrentContext() -> c:Clay_GetCurrentContext();

	// Sets the context that clay will use to compute the layout.
	// Used to restore a context saved from Clay_GetCurrentContext when using multiple instances of clay simultaneously.
	static void SetCurrentContext(Clay_Context^ context) { c:Clay_SetCurrentContext(context); }

	// Calculates a hash ID from the given idString.
	// Generally only used for dynamic strings when CLAY_ID("stringLiteral") can't be used.
	static Clay_ElementId GetElementId(Clay_String idString) -> c:Clay_GetElementId(idString);
	// Calculates a hash ID from the given idString and index.
	// - index is used to avoid constructing dynamic ID strings in loops.
	// Generally only used for dynamic strings when CLAY_IDI("stringLiteral", index) can't be used.
	static Clay_ElementId GetElementIdWithIndex(Clay_String idString, uint index) -> c:Clay_GetElementIdWithIndex(idString, index);
	// Returns layout data such as the final calculated bounding box for an element with a given ID.
	// The returned Clay_ElementData contains a `found` bool that will be true if an element with the provided ID was found.
	// This ID can be calculated either with CLAY_ID() for string literal IDs, or Clay_GetElementId for dynamic strings.
	static Clay_ElementData GetElementData(Clay_ElementId id) -> c:Clay_GetElementData(id);

	// NOTE: CUSTOM
	static Rectangle GetBoundingBox(Clay_ElementId id) -> Clay.GetElementData(id).boundingBox;

	// Returns true if Clay's internal debug tools are currently enabled.
	static bool IsDebugModeEnabled() -> c:Clay_IsDebugModeEnabled();
	// Enables and disables visibility culling. By default, Clay will not generate render commands for elements whose bounding box is entirely outside the screen.
	static void SetCullingEnabled(bool enabled) -> c:Clay_SetCullingEnabled(enabled);
	// Returns the maximum number of UI elements supported by Clay's current configuration.
	static int GetMaxElementCount() -> c:Clay_GetMaxElementCount();
	// Modifies the maximum number of UI elements supported by Clay's current configuration.
	// This may require reallocating additional memory, and re-calling Clay_Initialize();
	static void SetMaxElementCount(int maxElementCount) -> c:Clay_SetMaxElementCount(maxElementCount);
	// Returns the maximum number of measured "words" (whitespace seperated runs of characters) that Clay can store in its internal text measurement cache.
	static int GetMaxMeasureTextCacheWordCount() -> c:Clay_GetMaxMeasureTextCacheWordCount();
	// Modifies the maximum number of measured "words" (whitespace seperated runs of characters) that Clay can store in its internal text measurement cache.
	// This may require reallocating additional memory, and re-calling Clay_Initialize();
	static void SetMaxMeasureTextCacheWordCount(int maxMeasureTextCacheWordCount) -> c:Clay_SetMaxMeasureTextCacheWordCount(maxMeasureTextCacheWordCount);
	// Resets Clay's internal text measurement cache, useful if memory to represent strings is being re-used.
	// Similar behaviour can be achieved on an individual text element level by using Clay_TextElementConfig.hashStringContents
	static void ResetMeasureTextCache() -> c:Clay_ResetMeasureTextCache();


	// TODO: out-of-order, do more cleanly :)
	// Binds a callback function that Clay will call to determine the dimensions of a given string slice.
	// - measureTextFunction is a user provided function that adheres to the interface Clay_Dimensions (Clay_StringSlice text, Clay_TextElementConfig *config, void *userData);
	// - userData is a pointer that will be transparently passed through when the measureTextFunction is called.
	// TODO: fn-ptr: Clay_Dimensions (*measureTextFunction)(Clay_StringSlice text, Clay_TextElementConfig *config, void *userData)
	// TODO: c:any
	static void SetMeasureTextFunction(c:void^ measureTextFunction, void^ userData) -> c:Clay_SetMeasureTextFunction(measureTextFunction, userData);
	// Experimental - Used in cases where Clay needs to integrate with a system that manages its own scrolling containers externally.
	// Please reach out if you plan to use this function, as it may be subject to change.
	// TODO: fn-ptr: Clay_Vector2 (*queryScrollOffsetFunction)(uint32_t elementId, void *userData)
	/// TODO: c:any
	static void SetQueryScrollOffsetFunction(c:void^ queryScrollOffsetFunction, void^ userData) -> c:Clay_SetQueryScrollOffsetFunction(queryScrollOffsetFunction, userData);

	// NOTE: EXTRA ===================================
	static bool VisuallyHovered(Clay_ElementId id) -> Clay.GetBoundingBox(id).Contains(GetFrameGlobalData().mouse_pos);
}

// -----------------------------------------
// INTERNAL --------------------------------
// -----------------------------------------
@extern Clay_ElementId Clay__HashString(Clay_String key, uint offset, uint seed);

// -----------------------------------------
// MACROS ----------------------------------
// -----------------------------------------
// NOTE: anything called str_literal MUST BE A c string LITERAL!!!

@extern Clay_String CLAY_STRING(char^ str_literal);

// CLAY_ID() is used to generate and attach a Clay_ElementId to a layout element during declaration.
// Note this macro only works with String literals and won't compile if used with a char* variable. To use a heap allocated char* string as an ID, use CLAY_SID.
// To regenerate the same ID outside of layout declaration when using utility functions such as Clay_PointerOver, use the Clay_GetElementId function.
@extern Clay_ElementId CLAY_ID(char^ str_literal);

// // A version of CLAY_ID that can be used with heap allocated char * data. The underlying char data will not be copied internally and should live until at least the next frame.
// @extern Clay_ElementId CLAY_SID(char^ str);

// Used for generating ids for sequential elements (such as in a for loop) without having to construct dynamic strings at runtime.
// Note this macro only works with String literals and won't compile if used with a char* variable. To use a heap allocated char* string as an ID, use CLAY_SIDI.
@extern Clay_ElementId CLAY_IDI(char^ str_literal, int offset);

// // A version of CLAY_IDI that can be used with heap allocated char * data. The underlying char data will not be copied internally and should live until at least the next frame.
// @extern Clay_ElementId CLAY_SIDI(char^ str, int offset);

// CLAY_ID_LOCAL() is used to generate and attach a Clay_ElementId to a layout element during declaration.
// Unlike CLAY_ID which needs to be globally unique, a local ID is based on the ID of it's parent and only needs to be unique among its siblings.
// As a result, local id is suitable for use in reusable components and loops.
// Note this macro only works with String literals and won't compile if used with a char* variable. To use a heap allocated char* string as an ID, use CLAY_SID_LOCAL.
@extern Clay_ElementId CLAY_ID_LOCAL(char^ str_literal);

// // A version of CLAY_ID_LOCAL that can be used with heap allocated char * data. The underlying char data will not be copied internally and should live until at least the next frame.
// @extern Clay_ElementId CLAY_SID_LOCAL(char^ str_literal);

// An offset version of CLAY_ID_LOCAL. Generates a Clay_ElementId string id from the provided char *label, combined with the int index.
// Used for generating ids for sequential elements (such as in a for loop) without having to construct dynamic strings at runtime.
// Note this macro only works with String literals and won't compile if used with a char* variable. To use a heap allocated char* string as an ID, use CLAY_SIDI_LOCAL.
@extern Clay_ElementId CLAY_IDI_LOCAL(char^ str_literal, int offset);

// // A version of CLAY_IDI_LOCAL that can be used with heap allocated char * data. The underlying char data will not be copied internally and should live until at least the next frame.
// @extern Clay_ElementId CLAY_SIDI_LOCAL(char^ str, int offset);

/// STYLING --------------------------------------------------------------------
// The element will be sized to fit its children (plus padding and gaps), up to max. If max is left unspecified, it will default to FLOAT_MAX. When elements are compressed to fit into a smaller parent, this element will not shrink below min.
@extern Clay_SizingAxis CLAY_SIZING_FIT(float min = 0, float max = c:FLT_MAX);

// The element will grow to fill available space in its parent, up to max. If max is left unspecified, it will default to FLOAT_MAX. When elements are compressed to fit into a smaller parent, this element will not shrink below min.
@extern Clay_SizingAxis CLAY_SIZING_GROW(float min = 0, float max = c:FLT_MAX);

// The final size will always be exactly the provided fixed value. Shorthand for CLAY_SIZING_FIT(fixed, fixed)
@extern Clay_SizingAxis CLAY_SIZING_FIXED(float fixed);

// Final size will be a percentage of parent size, minus padding and child gaps. percent is assumed to be a float between 0 and 1.
@extern Clay_SizingAxis CLAY_SIZING_PERCENT(float percent_0_to_1);

// TEXT ------------------------------------------------------------------------
@extern void CLAY_TEXT(Clay_String str, Clay_TextElementConfig^ ptr_from_CLAY_TEXT_CONFIG);
// TODO: see if this is necessary...
@extern Clay_TextElementConfig^ CLAY_TEXT_CONFIG(Clay_TextElementConfig config); // stores the config and returns as a ptr, for use in CLAY_TEXT

void clay_text(char^ str_that_must_exist_til_next_frame, Clay_TextElementConfig config) {
	CLAY_TEXT(.(str_that_must_exist_til_next_frame), c:Clay__StoreTextElementConfig(config));
}


// -----------------------------------------------------------------
void clay_x_grow_spacer() {
	$clay({
		.layout = {
			.sizing = {
				.width = CLAY_SIZING_GROW(),
				.height = CLAY_SIZING_FIXED(0),
			} 
		}
	}) {
		// inside begin/end
	};
}

void clay_x_spacer(float amt) {
	$clay({
		.layout = {
			.sizing = {
				.width = CLAY_SIZING_FIXED(amt),
				.height = CLAY_SIZING_FIXED(0),
			} 
		}
	}) {
		// inside begin/end
	};
}

void clay_y_grow_spacer() {
	$clay({
		.layout = {
			.sizing = {
				.width = CLAY_SIZING_FIXED(0),
				.height = CLAY_SIZING_GROW(),
			} 
		}
	}) {};
}

void clay_y_spacer(float amt) {
	$clay({
		.layout = {
			.sizing = {
				.width = CLAY_SIZING_FIXED(0),
				.height = CLAY_SIZING_FIXED(amt),
			} 
		}
	});
}



// ----------
void Clay__OpenConfiguredElement(Clay_ElementDeclaration decl) {
	c:Clay__OpenElement();
	c:Clay__ConfigureOpenElement(decl);
}
@extern void Clay__CloseElement();

bool clay__begin(Clay_ElementDeclaration decl) {
	Clay__OpenConfiguredElement(decl);
	return true;
}
void clay__end(bool _) {
	Clay__CloseElement();
}

bool HORIZ__begin(Clay_ElementDeclaration decl = {}) {
	decl.layout.layoutDirection = CLAY_LEFT_TO_RIGHT;
	Clay__OpenConfiguredElement(decl);
	return true;
}
void HORIZ__end(bool _) -> Clay__CloseElement();

bool HORIZ_FIXED__begin(float fixed_amount, Clay_ElementDeclaration decl = {}) {
	decl.layout.sizing = { .width = CLAY_SIZING_GROW(), .height = CLAY_SIZING_FIXED(fixed_amount), };
	decl.layout.layoutDirection = CLAY_LEFT_TO_RIGHT;
	Clay__OpenConfiguredElement(decl);
	return true;
}
void HORIZ_FIXED__end(bool _) -> Clay__CloseElement();

bool HORIZ_GROW__begin(Clay_ElementDeclaration decl = {}) {
	decl.layout.sizing = .Grow();
	decl.layout.layoutDirection = CLAY_LEFT_TO_RIGHT;
	Clay__OpenConfiguredElement(decl);
	return true;
}
void HORIZ_GROW__end(bool _) -> Clay__CloseElement();

bool VERT__begin(Clay_ElementDeclaration decl = {}) {
	decl.layout.layoutDirection = CLAY_TOP_TO_BOTTOM;
	Clay__OpenConfiguredElement(decl);
	return true;
}
void VERT__end(bool _) -> Clay__CloseElement();

bool VERT_FIXED__begin(float fixed_amount, Clay_ElementDeclaration decl = {}) {
	decl.layout.sizing = { CLAY_SIZING_FIXED(fixed_amount), CLAY_SIZING_GROW(), };
	decl.layout.layoutDirection = CLAY_TOP_TO_BOTTOM;
	Clay__OpenConfiguredElement(decl);
	return true;
}
void VERT_FIXED__end(bool _) -> Clay__CloseElement();

bool VERT_GROW__begin(Clay_ElementDeclaration decl = {}) {
	decl.layout.sizing = .Grow();
	decl.layout.layoutDirection = CLAY_TOP_TO_BOTTOM;
	Clay__OpenConfiguredElement(decl);
	return true;
}
void VERT_GROW__end(bool _) -> Clay__CloseElement();
