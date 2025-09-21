import edit;

import rl;
import clay_lib;
import warn;
import ui_elements;
import std;
import theming;
import textures;
import globals;
import cursor;

void LayoutUI() {
	// File drop listener
	if (rl.IsFileDropped()) {
		OnFileDropped();
	}

	$clay({
		.id = CLAY_ID(c"main"),
		.layout = {
			.sizing = .(window_width, window_height),
			// .padding = { .left = left_panel_width as int }
			.layoutDirection = CLAY_TOP_TO_BOTTOM,
		}, 
		.backgroundColor = Colors.Transparent,
	}) {
		ProjectBarUI();

		$clay({
			.layout = {
				.sizing = .Grow(),
			}
		}) {
			SidePanel();

			$clay({
				.id = CLAY_ID(c"video-area-wrapper"),
				.layout = {
					.sizing = { CLAY_SIZING_GROW(), CLAY_SIZING_GROW() },
					.padding = .(16), 
					.childGap = 16,
					.childAlignment = { CLAY_ALIGN_X_CENTER, CLAY_ALIGN_Y_CENTER },
				}, 
				.backgroundColor = Colors.Black,
			}) {
				// NOTE: wrong on first render (render twice for first frame to avoid)
				let parent_bounds = Clay.GetElementData(CLAY_ID(c"video-area-wrapper")).boundingBox;
				parent_bounds.width -= 32; // 16 padding on each side!
				parent_bounds.height -= 32;

				// manually fit this element, since aspect-ratio image scaling causes it to overflow on GROW mode... :/
				Rectangle fitted = parent_bounds.FitIntoSelfWithAspectRatio(canvas.width(), canvas.height());

				$clay({
					.id = CLAY_ID(c"video"),
					.floating = {
						.attachTo = CLAY_ATTACH_TO_PARENT,
						.attachPoints = {
							.element = CLAY_ATTACH_POINT_CENTER_CENTER,
							.parent = CLAY_ATTACH_POINT_CENTER_CENTER,
						}
					},
					.layout = {
						.sizing = .(fitted.width, fitted.height),
					}, 
					.image = .(canvas.texture),
				}) {
					canvas_rect = Clay.GetElementData(CLAY_ID(c"video")).boundingBox;
				};
			};
		};
		BottomPanel();

		DisplayModals();
		warning_log.Update();
	};
}

struct RestoreSelectionDragStateEntry {
	ElementHandle eh;
	float start_time;
	float duration;
}
struct RestoreSelectionDragState {
	RestoreSelectionDragStateEntry[] entries;

	construct(Composition& comp) {
		RestoreSelectionDragStateEntry[] entries = {};

		for (let! eh in comp.selection) {
			let el = comp.elements.Get(eh);
			if (el == NULL) {
				warn(.MISC, "element not found in restore selection, what");
				continue; 
			}
			entries.add({
				:eh,
				.start_time = el#start_time,
				.duration = el#duration,
			});
		}

		return { :entries };
	}

	void Apply(Composition& comp) {
		for (let& entry in entries) {
			let el_ptr = comp.elements.Get(entry.eh);
			if (el_ptr == NULL) { warn(.MISC, "failed to find elem in RestoreSelectionDragState.Apply"); continue; }
			
			el_ptr#start_time = entry.start_time;
			el_ptr#duration = entry.duration;
		}
	}
}

struct CompositionTimelineUIState {
	float t_at_drag_start = 0;
	float x_at_mdrag_start = 0;

	float t_specific_at_drag_start = 0; // start or end t for _start/_end drag!

	int layer_i_at_drag_start = 0;
	int last_significant_layer_i = 0; // updated whenever after each detected change

	float layer_f_at_mdrag_start_relative_marker = 0;

	float current_caret_time_at_drag_start = 0;

	bool is_mdragging_view = false; // middle-click-dragging

	ViewRange view_range_at_mdrag_start = { .start = 0, .end = 0 };
	ViewRange vertical_view_range_at_mdrag_start = { .start = 0, .end = 0 };

	bool is_dragging_caret = false; // left-click-dragging

	bool is_dragging_selection_start = false;
	bool is_dragging_selection_end = false;

	bool is_dragging_selection = false;

	RestoreSelectionDragState? restore_selection_drag_state = none;

	float? display_snap_line_at_t = none;

// --------------------------------------------------------------------
	bool is_ldragging_any() -> is_dragging_caret || is_dragging_selection_start || is_dragging_selection_end || is_dragging_selection;
	bool is_mdragging_any() -> is_mdragging_view;

	void stop_ldragging_any() {
		is_dragging_caret = false;
		is_dragging_selection_start = false;
		is_dragging_selection_end = false;
		is_dragging_selection = false;

		restore_selection_drag_state = none;
	}
	void stop_mdragging_any() {
		is_mdragging_view = false; 
	}
}

CompositionTimelineUIState composition_ui_state = {}; // TODO: rework `using xxxx` to work like match (reference extend or reference...), and thus fix the issue of not persisting the hot-reload status of the variable
CompositionTimelineUIState& ermmmmmmm() -> composition_ui_state; // Q: why am I doing this? -- todo-> comp.ui_state

enum CompositionTimelineElementHoverKind {
	Body,
	Begin,
	End,
}

void CompositionTimelineUI_Clay() {
	let& composition_ui_state_TODO_REF = composition_ui_state;
	using composition_ui_state_TODO_REF;

	// bool hovering_timeline_back = false;

	if (!has_comp()) {
		$HORIZ_GROW({
			.backgroundColor = theme.button,
		}) {
			clay_text("No Active Composition", { .fontSize = rem(1), .textColor = Colors.White });
		};
		return;
	}

	let& comp = Comp();
	using comp;

	Clay_ElementId layer_container_id = .("CompositionTimelineUI");
	Rectangle layer_container_bounds = Clay.GetBoundingBox(layer_container_id).PadUp(CompositionTimelineSecondTickerUI_height()); // include ticker timeline for dragging time :)
	float layer_info_width = 40;
	float scrollable_timeline_width = layer_container_bounds.width; // space for timeline
	float layer_height = layer_container_bounds.height / vertical_view_range_slider.range.width();
	float time_to_width_pixels = scrollable_timeline_width / std.max(0.00001, view_range_slider.range.width()); // TODO: better error-handling!
	float width_pixels_to_time = view_range_slider.range.width() / std.max(1, scrollable_timeline_width);
	float unit_to_height_pixels = layer_container_bounds.height / std.max(0.00001, vertical_view_range_slider.range.width()); // TODO: better error-handling!
	float y_scroll = -(layers.size as float - vertical_view_range_slider.range.end) * unit_to_height_pixels;

	EditLayer^ hovered_layer = NULL;
	int? hovered_layer_i = none;
	ElementHandle? hovered_elem_handle = none;
	CompositionTimelineElementHoverKind elem_hover_kind = .Body;

	bool is_hovering_caret_moving_location = false;

	$VERT_GROW({
		.backgroundColor = theme.button,
	}) {
		is_hovering_caret_moving_location = CompositionTimelineSecondTickerUI(comp, layer_info_width, time_to_width_pixels);
		$HORIZ_GROW({
			.border = Clay_BorderElementConfig.Between(1, theme.panel_border)
		}) {
			$VERT_FIXED(layer_info_width, {
				.layout = {
					.sizing = .Grow(),
				},
				.clip = {
					.vertical = true,
					.childOffset = {
						.y = y_scroll
					},
				},
				.border = {
					.color = theme.panel_border,
					.width = { .betweenChildren = 1, .bottom = 1 },
				}
			}) {
				for (int i = layers.size - 1; i >= 0; i--) { // TODO: culling based on vertical view range!
					EditLayer^ layer = layers[i];
					$HORIZ_FIXED(layer_height) {
						// layer info section
						$VERT_FIXED(layer_info_width, { .border = Clay_BorderElementConfig.Right(1, theme.panel_border) }) {
							if (ClayIconButton(layer#visible ? Textures.eye_open_icon | Textures.empty, .Grow(), Clay_Sizing(rem(1), rem(1)))) {
								layer#visible = !layer#visible;
							}
						};
					};
				}
			};

			$VERT_GROW({
				.id = layer_container_id,
				.layout = {
					.sizing = .Grow(),
				},
				.clip = {
					.vertical = true,
					.horizontal = true,
					.childOffset = {
						.x = -view_range_slider.range.start * time_to_width_pixels,
						.y = y_scroll
					},
				},
				.backgroundColor = theme.panel,
			}) {
				// --------------------------------------------------------------
				// TODO: fix mismatch in vert space (cuts off bottom row!!!)
				// --------------------------------------------------------------

				for (int layer_i = layers.size - 1; layer_i >= 0; layer_i--) { // TODO: culling based on vertical view range!
					EditLayer^ layer = layers[layer_i];
					let layer_theme = theme.elem_ui_pink; // TODO:

					Clay_ElementId layer_id = .(t"{layer}");

					if (Clay.VisuallyHovered(layer_id)) { // NOTE: (question) ... is this accurate? even when scissored?
						hovered_layer = layer;
						hovered_layer_i = layer_i;
					}

					bool has_top_border = (layer_i != layers.size - 1);
					if (has_top_border) {
						$HORIZ_FIXED(1, { .backgroundColor = theme.panel_border });
					}
					$HORIZ({
						.id = layer_id,
						.backgroundColor = layer#visible ? Colors.Transparent | theme.panel_disabled,
						.layout = {
							.sizing = .(visual_view_range_max_time * time_to_width_pixels, layer_height),
						},
					}) {
						// layer info section
						float last_time = 0;
						for (let& elem in layer#elem_iter()) {
							let handle = elem.handle();

							Clay_ElementId elem_id = .(t"{^elem}-elem");

							float inset_expand_amt = 8; // (pixels)

							float lr_expand_amt = inset_expand_amt; // TODO: make these not overlap with prev/next element-rects!
							float lr_inset_amt = inset_expand_amt; // TODO: make these not overlap with itself <= width/2

							Rectangle lr_expanded_rect = 
								with let rect = Clay.GetBoundingBox(elem_id) in
								rect.PadLeftRight(lr_expand_amt);

							let elem_theme = &{
								if (comp.IsSelected(handle)) { return theme.elem_ui_blue; }
								// TODO: warning colouring
								return layer_theme;
							};
							if (!layer#visible) {
								elem_theme.bg = elem_theme.bg.Darkened(16);
							}

							bool effectively_hovered = lr_expanded_rect.Contains(mouse_pos);
							// NOTE: second part of hover behavior somewhat wrong... do extra checking (false positives!!)
							if (effectively_hovered) {
								// TODO: check real collision w Clay.Hover() ?

								hovered_elem_handle = handle;

								elem_hover_kind = match (true) {
									(mouse_pos.x < (lr_expanded_rect.x + lr_expand_amt + lr_inset_amt)) -> .Begin,
									(mouse_pos.x > (lr_expanded_rect.x + lr_expanded_rect.width - lr_expand_amt - lr_inset_amt)) -> .End,
									else -> .Body,
								};

								elem_theme.bg = elem_theme.bg.Darkened(8);
							}

							$clay({
								.layout = { .sizing = { .Zero, .fixed(layer_height) } }, // NOTE: hack to get around issues with clip/floating in clay
							}) {
								$clay({ .layout = { .sizing = .(elem.start_time * time_to_width_pixels, 0) } });
								$clay({
									.id = elem_id,
									.backgroundColor = elem_theme.bg,
									.layout = {
										.sizing = { CLAY_SIZING_FIXED(elem.duration * time_to_width_pixels), CLAY_SIZING_GROW() },
										.layoutDirection = CLAY_TOP_TO_BOTTOM
									},
									.border = .(1, elem_theme.border),
								}) {
									clay_text(elem.NameUIText(), { .textColor = elem_theme.text, .fontSize = std.mini((layer_height * 0.5) as ushort, rem(1)) });
									clay_y_grow_spacer();
									clay_text(elem.content_impl#ImplTypeStr(), { .textColor = elem_theme.text, .fontSize = std.mini((layer_height * 0.3) as ushort, rem(0.5)) });
								};

							};
							last_time = elem.end_time();
						}
					};
				}

				// floating things here ------------
				if (current_time >= view_range_slider.range.start && (current_time) < view_range_slider.range.end) {
					Clay_ElementId current_caret_id = .("composition-timeline-current-caret");
					$VERT_FIXED(1, {
						.id = current_caret_id,
						.backgroundColor = theme.timeline_current_caret,
						.floating = {
							.offset = { (current_time - view_range_slider.range.start) *  time_to_width_pixels, 0 },
							.attachTo = CLAY_ATTACH_TO_PARENT,
						}
					});
					if (Clay.GetBoundingBox(current_caret_id).PadLeftRight(4).Contains(mouse_pos)) {
						is_hovering_caret_moving_location = true;
					}
				}

				// TODO: selection box & snap lines here!
				// ---------------------------------
			};

			vertical_view_range_slider.Update("vertical_view_range_slider", 0, layers.size, 1);
		};
		$HORIZ({ .layout = { .sizing = { .width = CLAY_SIZING_GROW() } } }) {
			view_range_slider.Update("view_range_slider", 0, visual_view_range_max_time, 1);
			if (!view_range_slider.IsInteracting()) { visual_view_range_max_time = calc_view_range_max_time(); }

			$clay({ .backgroundColor = theme.button, .layout = { .sizing = .(rem(1), rem(1)) }});
		};
	};

		// float timeline_view_start = 0;
		// float timeline_view_duration = max_time;
		//
		// int show_layers = std.maxi(layers.size + 1, 3);
		// float height = composition_timeline_height;
		// float layer_height = height / show_layers;
		//
		// float whole_width = window_width as float - left_panel_width;
		// Vec2 whole_tl = v2(left_panel_width + 1, window_height as float - height);
		// Vec2 whole_dimens = v2(whole_width, height);
		// Rectangle whole_rect = Rectangle.FromV(whole_tl, whole_dimens);
		//
		// float info_width = 32;
		//
		// for (int i in 0..show_layers) { // empty skeleton for layers
		// 	float x = whole_tl.x;
		// 	float y = whole_rect.b() - (i + 1) as float * layer_height;
		// 	Rectangle r = .(x, y, info_width, layer_height);
		//
		// 	d.RectR(r.Inset(1), theme.button);
		// 	d.RectR(.(x, y, whole_width, 1), theme.panel_border);
		//
		// 	if (layers.size > i) {
		// 		// layer info ui -------
		// 		let& layer = layers.get(i);
		//
		// 		if (Button(r.tl(), r.dimen(), "")) {
		// 			layer.visible = !layer.visible;
		// 		}
		//
		// 		d.Text(t"L{i}", x as int + 6, y as int + 6, 12, theme.timeline_layer_info_gray);
		//
		// 		if (layer.visible) {
		// 			d.TextureAtRect(Textures.eye_open_icon, r.Inset(6).FitIntoSelfWithAspectRatio(1, 1));
		// 		}
		// 		// ---------------------
		// 	}
		// }
		//
		// Vec2 tl = whole_tl + v2(info_width, 0);
		// Vec2 dimens = whole_dimens - v2(info_width, 0);
		//
		// bool pressed_inside = mouse.LeftClickPressed() && mouse.GetPos().InV(tl, dimens);
		//
		// float width = dimens.x;
		//
		// for (int i in 0..elements.size) {
		// 	let& elem = elements.get(i);
		// 	// elem.TimelineUI();
		// 	float x = tl.x + (elem.start_time - timeline_view_start) / timeline_view_duration * width;
		// 	float y = whole_rect.b() - (elem.layer + 1) as float * layer_height;
		//
		// 	float w = elem.duration / timeline_view_duration * width;
		//
		// 	Rectangle r = .(x, y, w, layer_height);
		//
		// 	bool has_err = elem.err_msg != NULL;
		// 	TimelineElementColorSet color_set = (selected_elem_i == i) ? theme.elem_ui_blue | 
		// 		((has_err) ? theme.elem_ui_yellow | theme.elem_ui_pink);
		// 		// selected -> blue
		// 		// warning -> yellow
		// 		// otherwise -> pink
		//
		// 	d.RectR(r, color_set.border);
		// 	d.RectR(r.Inset(1), color_set.bg);
		//
		// 	d.Text(t"{elem.NameUIText()}", x as int + 6, y as int + 6, 12, color_set.text);
		// 	d.Text(elem.content_impl#ImplTypeStr(), x as int + 6, (y + layer_height) as int - 18, 12, color_set.text);
		//
		// 	bool hovering = mouse.GetPos().Between(r.tl(), r.br());
		// 	if (has_err) {
		// 		Vec2 warning_dimen = v2(16, 16);
		// 		d.TextureAtSizeV(Textures.warning_icon, r.br() - warning_dimen - v2(6, 6), warning_dimen);
		//
		// 		if (hovering) {
		// 			Vec2 options_tl = mouse.GetPos() + v2(0, 10);
		// 			Vec2 options_dims = c:MeasureTextEx(c:GetFontDefault(), elem.err_msg, 16, 1);
		// 			d.RectR(Rectangle.FromV(options_tl, options_dims).Pad(6), theme.button);
		// 			d.Text(elem.err_msg, options_tl.x as.., options_tl.y as.., 16, Colors.White);
		// 		}
		// 	}
		//
		// 	if (timeline.is_dragging_elem_any()) {
		// 		if (timeline.dragging_elem_start || timeline.dragging_elem_end) {
		// 			cursor_type = CursorType.ResizeHoriz;
		// 		} else {
		// 			cursor_type = CursorType.Pointer;
		// 		}
		// 	} else if (hovering) {
		// 		if (mouse.GetPos().Between(r.tl(), r.tl() + v2(10, layer_height))) {
		// 			cursor_type = CursorType.ResizeHoriz;
		// 		} else if (mouse.GetPos().Between(r.br() - v2(10, layer_height), r.br())) {
		// 			cursor_type = CursorType.ResizeHoriz;
		// 		} else {
		// 			cursor_type = CursorType.Pointer;
		// 		}
		// 	}
		//
		//
		// 	if (hovering && mouse.LeftClickPressed()) {
		// 		selected_elem_i = i;
		//
		// 		if (mouse.GetPos().Between(r.tl(), r.tl() + v2(10, layer_height))) {
		// 			timeline.dragging_elem_start = true;
		// 		} else if (mouse.GetPos().Between(r.br() - v2(10, layer_height), r.br())) {
		// 			timeline.dragging_elem_end = true;
		// 		} else {
		// 			timeline.dragging_elem = true;
		// 		}
		// 		timeline.elem_drag_init_mouse_x = mouse.GetPos().x;
		// 		timeline.elem_drag_init_start = elem.start_time;
		// 		timeline.elem_drag_init_end = elem.end_time();
		// 	}
		// }
		//
		// d.Rect(whole_rect.bl(), v2(dimens.x, 1), theme.panel_border); // TODO: change
		//
		// d.Rect(tl + v2(dimens.x * current_time / max_time, 0), v2(1, dimens.y), theme.active);

		// mouse interactions --------------------
		// if (pressed_inside && !timeline.is_dragging_elem_any()) {
		// 	timeline.dragging_caret = true;
		// }
		//
		// if (mouse.LeftClickDown()) {
		// 	float t_on_timeline_unbounded = (mouse.GetPos().x - tl.x) / dimens.x * max_time;
		// 	float t_on_timeline_bounded = std.clamp(t_on_timeline_unbounded, 0, max_time);
		// 	if (timeline.dragging_caret) {
		// 		float new_time = (mouse.GetPos().x - tl.x) / dimens.x * max_time;
		// 		if (new_time <= 0) { new_time = 0; }
		// 		if (new_time >= max_time) { new_time = max_time; }
		// 		SetTime(new_time); // TODO: add snap-to-frame-set-time
		// 		SetFrame(current_frame);
		// 	} else if (timeline.dragging_elem) {
		// 		float og_t_on_timeline = (timeline.elem_drag_init_mouse_x - tl.x) / dimens.x * max_time;
		// 		let& selected_elem = elements.get(selected_elem_i);
		// 		selected_elem.start_time = SnapToNearestFramesTime(timeline.elem_drag_init_start + (t_on_timeline_unbounded - og_t_on_timeline));
		// 		selected_elem.start_time = std.max(0, selected_elem.start_time);
		//
		// 		selected_elem.layer = (((whole_rect.b() - mouse.GetPos().y) / layer_height) as int);
		// 		AddLayersTill(selected_elem.layer);
		// 	} else if (timeline.dragging_elem_start) {
		// 		float og_t_on_timeline = (timeline.elem_drag_init_mouse_x - tl.x) / dimens.x * max_time;
		// 		let& selected_elem = elements.get(selected_elem_i);
		// 		selected_elem.start_time = SnapToNearestFramesTime(timeline.elem_drag_init_start + (t_on_timeline_unbounded - og_t_on_timeline));
		// 		selected_elem.start_time = std.max(0, selected_elem.start_time);
		// 		selected_elem.duration = (timeline.elem_drag_init_end - timeline.elem_drag_init_start) - (selected_elem.start_time - timeline.elem_drag_init_start);
		// 	} else if (timeline.dragging_elem_end) {
		// 		float og_t_on_timeline = (timeline.elem_drag_init_mouse_x - tl.x) / dimens.x * max_time;
		// 		let& selected_elem = elements.get(selected_elem_i);
		// 		selected_elem.duration = SnapToNearestFramesTime((timeline.elem_drag_init_end - timeline.elem_drag_init_start) + (t_on_timeline_unbounded - og_t_on_timeline));
		// 	}
		// }
		//
		// if (!mouse.LeftClickDown()) {
		// 	timeline.dragging_caret = false;
		// 	timeline.dragging_elem = false;
		// 	timeline.dragging_elem_start = false;
		// 	timeline.dragging_elem_end = false;
		//
		// 	// CullEmptyLayers();
		// }


	float t_at_mouse_x = view_range_slider.range.start + std.clamp((mouse_pos.x - layer_container_bounds.x) / layer_container_bounds.width, 0, 1) * view_range_slider.range.width();
	float t_delta = t_at_mouse_x - t_at_drag_start;
	float layer_f_relative = mouse_pos.y / layer_height;

	// =================================================
	// interactions & updates ==========================
	// =================================================

	//  dragging --------------
	if (is_mdragging_view) {
		float t_mdrag_delta = -(mouse_pos.x - x_at_mdrag_start) / time_to_width_pixels; // invert for 'drag-like' interaction (ie: pulling view backwards to move forwards)
		float layer_f_delta = layer_f_relative - layer_f_at_mdrag_start_relative_marker;

		float allowable_t_mdrag_delta = std.clamp(t_mdrag_delta, -view_range_at_mdrag_start.start, visual_view_range_max_time - view_range_at_mdrag_start.end);
		float allowable_layer_f_mdrag_delta = std.clamp(layer_f_delta, -vertical_view_range_at_mdrag_start.start, layers.size as float - vertical_view_range_at_mdrag_start.end);

		view_range_slider.range = {
			.start = view_range_at_mdrag_start.start + allowable_t_mdrag_delta,
			.end = view_range_at_mdrag_start.end + allowable_t_mdrag_delta,
		};

		vertical_view_range_slider.range = {
			.start = vertical_view_range_at_mdrag_start.start + allowable_layer_f_mdrag_delta,
			.end = vertical_view_range_at_mdrag_start.end + allowable_layer_f_mdrag_delta,
		};
	}

	if (is_dragging_caret) {
		current_time = t_at_mouse_x;
	} else if (is_dragging_selection || is_dragging_selection_start || is_dragging_selection_end) {
		if (restore_selection_drag_state is Some) {
			restore_selection_drag_state.!.Apply(comp);
		}

		float min_t_delta = -c:FLT_MAX;
		float max_t_delta = c:FLT_MAX;
		{
			float min_start_time_in_selection = c:FLT_MAX;
			float max_start_time_in_selection = 0;
			float min_end_time_in_selection = c:FLT_MAX;
			for el in effective_selection_iter() {
				min_start_time_in_selection = std.min(min_start_time_in_selection, el.start_time);
				min_end_time_in_selection = std.min(min_end_time_in_selection, el.end_time());

				max_start_time_in_selection = std.max(max_start_time_in_selection, el.start_time);
			}

			// don't allow scaling elements into nothing! or scaling into negative time space!
			if (is_dragging_selection_end) {
				min_t_delta = -(t_specific_at_drag_start-max_start_time_in_selection) + time_per_frame;
			} else if (is_dragging_selection_start) {
				min_t_delta = -min_start_time_in_selection;
				max_t_delta = min_end_time_in_selection - t_specific_at_drag_start - time_per_frame;
			} else if (is_dragging_selection) {
				min_t_delta = -min_start_time_in_selection;
			}
		}

		// attempt snap-lines!
		display_snap_line_at_t = none;
		// TODO: snapping scuffed/non-functional!!!
		// TODO: regular when !snapped
		// if (!key.AltIsDown()) {
		// 	float[] selection_snap_points = {}; // TODO: store offsets for is_dragging_selection
		// 	defer selection_snap_points.delete();
		//
		// 	float[] snap_points = {};
		// 	defer snap_points.delete();
		//
		// 	if (is_dragging_selection) { // NOTE: use t_delta, not limited form here :)
		// 		// TODO: unique_add
		// 		for el in effective_selection_iter() {
		// 			selection_snap_points.add(el.start_time + t_delta);
		// 			selection_snap_points.add(el.end_time() + t_delta);
		// 		}
		// 		// TODO: dedupe!! :optimize since very bad -> O(n^2) for large selections!
		// 		
		// 	} else if (is_dragging_selection_start || is_dragging_selection_end) {
		// 		selection_snap_points.add(t_specific_at_drag_start + t_delta);
		// 	}
		// 	
		// 	for el in elements {
		// 		let eh = el.handle();
		// 		bool el_in_eff_sel = &{
		// 			for eff_sel_eh in effective_selection {
		// 				if (eff_sel_eh == eh) { return true; }
		// 			}
		// 			return false;
		// 		};
		//
		// 		if (el_in_eff_sel) { // PROCESS SNAP POINTS FROM END/START OF THIS ELEM
		// 			continue;
		// 		}
		//
		// 		if (is_dragging_selection) {
		// 			snap_points.add(el.start_time);
		// 			snap_points.add(el.end_time());
		// 		} else if (is_dragging_selection_start) {
		// 			snap_points.add(el.start_time);
		// 		} else if (is_dragging_selection_end) {
		// 			snap_points.add(el.end_time());
		// 		}
		// 	}
		// 	
		// 	float? selection_snap_best = none;
		// 	float? snap_best = none;
		// 	float min_snap_dist = c:FLT_MAX;
		// 	{
		// 		for selection_snap_point in selection_snap_points {
		// 			for snap_point in snap_points {
		// 				// TODO: continue (maybe filter these out-pre!!) :optimize
		// 				float snap_point_delta = snap_point - t_at_drag_start;
		// 				if (snap_point_delta >= min_t_delta && snap_point_delta <= max_t_delta) {
		// 					float snap_dist = std.abs(selection_snap_point - snap_point);
		// 					if (snap_dist < (min_snap_dist)) {
		// 						min_snap_dist = snap_dist;
		// 						selection_snap_best = selection_snap_point;
		// 						snap_best = snap_point;
		// 					}
		// 				}
		// 			}
		// 		}
		// 	}
		//
		// 	float snap_dist_threshold = width_pixels_to_time * 20; // 20 pixels
		// 	if (min_snap_dist <= snap_dist_threshold) {
		// 		// do snap!
		// 		{
		// 			float snap_to = snap_best.!;
		// 			for el in effective_selection_iter() {
		// 				if (is_dragging_selection) {
		// 					todo("wah");
		// 				} else if (is_dragging_selection_start) {
		// 					float og_end_time = el.end_time();
		// 					el.start_time = snap_to;
		// 					el.duration = og_end_time - el.start_time;
		// 				} else if (is_dragging_selection_end) {
		// 					el.duration = snap_to - el.start_time;
		// 				}
		// 			}
		// 			
		// 			display_snap_line_at_t = snap_to;
		// 		}
		// 	}
		// }
		
		if (display_snap_line_at_t is None) { // regular dragging (not holding Alt/Option, or failed to snap)
			float limited_t_delta = std.clamp(t_delta, min_t_delta, max_t_delta);

			for el in effective_selection_iter() {
				if (is_dragging_selection) {
					el.start_time += limited_t_delta;
				} else if (is_dragging_selection_start) {
					el.start_time += limited_t_delta;
					el.duration -= limited_t_delta;
				} else if (is_dragging_selection_end) {
					el.duration += limited_t_delta;
				}
			}
		}

		// correct sorting by removing all then adding back + y-movement!
		{
			// remove-all from all layers... (keeps sorted easier ;D)
			for el in effective_selection_iter() {
				for layer_eh, i in el.layer#element_handles {
					if (el.handle() == layer_eh) {
						el.layer#element_handles.remove_at(i);
						break;
					}
				}
			}

			int layer_i_diff = &{
				if (is_dragging_selection && hovered_layer_i is Some && hovered_layer_i.! != last_significant_layer_i) {
					int min_i = last_significant_layer_i;
					int max_i = last_significant_layer_i;

					for el in effective_selection_iter() {
						int el_layer_i = el.layer#get_index_in_comp(comp).! or 0;
						min_i = std.mini(min_i, el_layer_i);
						max_i = std.maxi(max_i, el_layer_i);
					}

					defer last_significant_layer_i = hovered_layer_i.!;
					return std.clampi(hovered_layer_i.! - last_significant_layer_i, -min_i, layers.size - 1 - max_i);
				}
				return 0;
			};

			// add back to same (or diff) layer!
			for el in effective_selection_iter() {
				int curr_layer_i = el.layer#get_index_in_comp(comp).! else continue;
				let new_layer = layers[curr_layer_i + layer_i_diff];
				el.layer = new_layer;
				new_layer#AddElement(el.handle());
			}
		}
	}

	{ //  cursor for element-related hovering/dragging
		if (is_dragging_selection) {
			cursor_type = .Pointer;
		} else if (is_dragging_selection_start || is_dragging_selection_end) {
			cursor_type = .ResizeHoriz;
		} else if (hovered_elem_handle is Some) {
			cursor_type = match (elem_hover_kind) {
				.Begin -> .ResizeHoriz,
				.Body -> .Pointer,
				.End -> .ResizeHoriz,
			};
		}
	} // /cursor for element-related hovering/dragging
	// /dragging --------------

	//  stopping --------------
	if (is_ldragging_any() && mouse.LeftClickReleased()) {
		stop_ldragging_any();
	}

	if (is_mdragging_any() && mouse.MiddleClickReleased()) {
		stop_mdragging_any();
	}
	// /stopping --------------


	//  starting --------------
	if (!is_ldragging_any() && mouse.LeftClickPressed() && layer_container_bounds.Contains(mouse_pos)) {
		t_at_drag_start = t_at_mouse_x;
		layer_i_at_drag_start = hovered_layer_i.! or &{ warn(.MISC, "bogus layer_i_at_drag_start"); return 0; };
		last_significant_layer_i = layer_i_at_drag_start;

		// TODO: do we need: is_hovering_caret_moving_location
		if (hovered_elem_handle is Some) {
			// // TODO: only add if not in
			bool already_in_selection = &{
				for eh in selection {
					if (eh == hovered_elem_handle.!) { return true; }
				}
				return false;
			};
			if (!already_in_selection) {
				if (!key.ShiftIsDown()) { // add to selection when shifting!!
					selection.clear();
				}
				selection.add(hovered_elem_handle.!);
			}
			primary_selection = hovered_elem_handle.!;

			effective_selection.clear();
			switch (elem_hover_kind) {
				.Body -> {
					is_dragging_selection = true;
					for eh in selection {
						effective_selection.add(eh);
					}
				},
				.Begin -> {
					is_dragging_selection_start = true; 

					float primary_start = elements.GetRef(primary_selection.!).start_time; // NOTE: danger!!
					t_specific_at_drag_start = primary_start;
					for el in selection_iter() {
						if (el.start_time == primary_start) {
							effective_selection.add(el.handle());
						}
					}
				},
				.End -> {
					is_dragging_selection_end = true;

					float primary_end = elements.GetRef(primary_selection.!).end_time(); // NOTE: danger!!
					t_specific_at_drag_start = primary_end;
					for el in selection_iter() {
						if (el.end_time() == primary_end) {
							effective_selection.add(el.handle());
						}
					}
				},
			}
			restore_selection_drag_state = RestoreSelectionDragState(comp);
		} else {
			is_dragging_caret = true;
			current_caret_time_at_drag_start = current_time;
		}
	}

	if (!is_mdragging_any() && mouse.MiddleClickPressed() && layer_container_bounds.Contains(mouse_pos)) {
		x_at_mdrag_start = mouse_pos.x;
		layer_f_at_mdrag_start_relative_marker = layer_f_relative;
		view_range_at_mdrag_start = view_range_slider.range;
		vertical_view_range_at_mdrag_start = vertical_view_range_slider.range;

		is_mdragging_view = true;
	}
	// /starting --------------

	if (!mouse.LeftClickDown()) {
		AddExtraEmptyLayerIfNone();
	}
}

void BottomPanel() {
	$Panel(composition_timeline_panel_expander) {
		$HORIZ_GROW() {
			$Panel(asset_manager_panel_expander) {
				AssetManagerUI();
			};
			CompositionTimelineUI_Clay();
		};
	};
}

