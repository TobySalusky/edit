import rl;
import keyframing;
import maths;
import theming;
import std;
import code_manager;
import script_interface;
import ui_elements;
import data;
import yaml;
import clay_lib;
import ui_elements;
import encode_decode;
import globals;
import textures;
import cursor;
import warn;
import resources;

//  global ui stuff ---------------------------------------------
ColorPicker global_color_picker = {};
CustomLayerColor^ getting_color_picked = NULL;
bool global_color_picker_pinned_open = GlobalSettings.get_bool("global_color_picker_pinned_open", false);
// /global ui stuff ---------------------------------------------


enum ElementKind {
	RECT,
	CIRCLE,
	IMAGE,
	IMAGE_SEQUENCE,
	FX_FN,
	VIDEO,
	FACE,
	;
}
interface ElementImpl {
	void Draw(Element^ e, float current_time);

	void UpdateState(float lt);

	void UI(CustomLayerUIParams& params);
	void TimelineUI(CustomLayerUIParams& params);

	char^ ImplTypeStr();

	CustomLayer^ CustomLayersList();

	ElementKind Kind();
	void _FillYaml(yaml_object& yo);
}

ElementImpl^ ElementImplFromYaml(ElementKind kind, yaml_object& yo) {
	ElementImpl^ it;
	switch (kind) {
		.RECT -> {
			it = RectElement.Make();
		},
		.CIRCLE -> {
			it = CircleElement.Make();
		},
		.IMAGE -> {
			it = ImageElement.Make(yo.get_str("file_path"));
		},
		.FX_FN -> {
			let em = CustomPureFnElement.Make(yo.get_str("fn_name"));
			let custom_layer_list_s = yaml_serializer.Obj(yo.get_obj("custom_layer_list"), true);
			em#custom_layer_list = CustomLayer.Deserialize(custom_layer_list_s);
			// TODO: need to actually transfer over old when re-loading fn-ptr!

			it = em;
		},
		.VIDEO -> {
			it = VideoElement.Make(yo.get_str("video_file_path"), yo.get_float("dec_fr"));
		},
		else -> {
			println(t"[WARNING]: ElementImplFromYaml unknown case {kind as int}");
			it = RectElement.Make();
		}
	}

	return it;
}

yaml_object ElementImplToYaml(ElementImpl^ impl) {
	yaml_object yo = {};
	yo.put_int("kind", impl#Kind() as int);
	impl#_FillYaml(yo);
	return yo;
}

struct RectElement : ElementImpl {
	void UI(CustomLayerUIParams& params) {}
	void TimelineUI(CustomLayerUIParams& params) {}
	void UpdateState(float lt) {}
	void Draw(Element^ e, float current_time) {
		d.RectRot(e#pos, e#scale, e#rotation, e#TintColor());
	}

	ElementKind Kind() -> .RECT;
	void _FillYaml(yaml_object& yo) { }

	char^ ImplTypeStr() -> "rect";
	CustomLayer^ CustomLayersList() -> NULL;

	static Self^ Make() -> malloc(sizeof<Self>);
}

struct CircleElement : ElementImpl {
	void UI(CustomLayerUIParams& params) {}
	void TimelineUI(CustomLayerUIParams& params) {}
	void UpdateState(float lt) {}
	void Draw(Element^ e, float current_time) {
		d.Circle(e#pos + e#scale.scale(0.5), e#scale.x / 2, e#TintColor()); // TODO: allow ellipse
	}

	ElementKind Kind() -> .CIRCLE;
	void _FillYaml(yaml_object& yo) { }

	char^ ImplTypeStr() -> "circle";
	CustomLayer^ CustomLayersList() -> NULL;


	static Self^ Make() -> malloc(sizeof<Self>);
}

struct ImageCache {
	static HashMap<char^, Texture^> cache = .();
	static StableArena<Texture> texture_storage = { .block_size_in_elements = 512 };

	static Texture& Get(char^ file_path) {
		if (cache.has(file_path)) {
			return *cache.get(file_path);
		}
		Texture tex = rl.LoadTexture(file_path);
		let ptr = texture_storage.push_get_ptr(tex);
		cache.insert(file_path, ptr);
		return *ptr;
	}
	
	static void Unload() {
		for (let pair in cache) {
			pair.value#delete();
		}
		cache.delete();
	}
}

struct ImageSequenceElement : ElementImpl {
	float time_per_frame;
	int resource_id;
	Texture[]^ textures = NULL;
	
	// ----------------------------
	void UI(CustomLayerUIParams& params) {
		// $HORIZ_FIXED(rem(1)) {
		// 	if (ClayButton("Reload Frames", .(t"{^this}-reload"), {})) {
		// 		ReloadFrames();
		// 	}
		// };
	}
	void TimelineUI(CustomLayerUIParams& params) {
		// $HORIZ_FIXED(rem(1));
	}
	void UpdateState(float lt) {}
	void Draw(Element^ e, float current_time) {
		if (textures == NULL) {
			return; 
		}
		if (textures#is_empty()) { return; }

		int i = (((current_time - e#start_time) / time_per_frame) as int) % textures#size;
		let& texture = (*textures)[i];

		d.TextureRotCenter(texture, e#pos + e#scale.scale(0.5), e#scale, e#rotation, e#TintColor());
	}

	ElementKind Kind() -> .IMAGE_SEQUENCE;
	void _FillYaml(yaml_object& yo) {
		// yo.put_literal("file_path", file_path);
		todo("ImageSequence - serialize!");
	}

	char^ ImplTypeStr() -> "img-seq";
	CustomLayer^ CustomLayersList() -> NULL;

	static Self^ Make(float time_per_frame, int resource_id) {
		return Box<Self>.Make({ :time_per_frame, :resource_id }); 
	}
}

struct ImageElement : ElementImpl {
	char^ file_path;
	
	void UI(CustomLayerUIParams& params) {}
	void TimelineUI(CustomLayerUIParams& params) {}
	void UpdateState(float lt) {}
	void Draw(Element^ e, float current_time) {
		// d.RectRot(e#pos, e#scale, e#rotation, Colors.Red);
		d.TextureRotCenter(ImageCache.Get(file_path), e#pos + e#scale.scale(0.5), e#scale, e#rotation, e#TintColor());
	}

	ElementKind Kind() -> .IMAGE;
	void _FillYaml(yaml_object& yo) {
		yo.put_literal("file_path", file_path);
	}

	char^ ImplTypeStr() -> "img";
	CustomLayer^ CustomLayersList() -> NULL;

	static Self^ Make(char^ file_path) -> Box<Self>.Make({ :file_path });
}

struct VideoElement : ElementImpl {
	char^ video_file_path;

	float dec_fr; // frame rate of video from decoding; set once loaded
	List<Texture> frames = {}; // set once loaded
	float speed = 1;
	float start_offset = 0; // offset from start of video in seconds
	bool loaded = false;
	bool loading = false;
	bool wrap = true;

	float CalculateMaximumDuration() {
		if (loaded) {
			float max_duration = (frames.size as float / (dec_fr * speed)) - start_offset;
			return max_duration;
		}
		return -1;
	}

	void UI(CustomLayerUIParams& params) {}
	void TimelineUI(CustomLayerUIParams& params) {}
	void UpdateState(float lt) {}
	void Draw(Element^ e, float current_time) {
		if (loaded) {
			int frame_idx = ((current_time - (e#start_time - start_offset)) * (dec_fr * speed)) as int % frames.size; 
			d.TextureRotCenter(frames.get(frame_idx), e#pos + e#scale.scale(0.5), e#scale, e#rotation, e#TintColor());
		}
	}

	ElementKind Kind() -> .VIDEO;
	void _FillYaml(yaml_object& yo) {
		yo.put_literal("video_file_path", video_file_path);
		yo.put_float("dec_fr", dec_fr);
	}

	char^ ImplTypeStr() -> "video";
	CustomLayer^ CustomLayersList() -> NULL;

	static Self^ Make(char^ video_path, float dec_fr = 0) {
		// NOTE: default dec_fr=0 is invalid, overwritten when loaded...
		// TODO: ensure that you get real dec_fr in blocking manner!!! (because we want video to take up correct space and not flicker to a new size!)
		char^ vfp = strdup(video_path);
		return Box<Self>.Make({ 
			.video_file_path = vfp,
			:dec_fr
		});
	}
}

struct CustomLayerBool {
	bool^ value;
	KeyframeLayer<bool> kl_value;
}

struct CustomLayerFloat {
	float^ value;
	KeyframeLayer<float> kl_value;
}

struct CustomLayerInt {
	int^ value;
	KeyframeLayer<int> kl_value;
}

struct CustomLayerColor {
	Color^ value;
	KeyframeLayer<Color> kl_value;
}

struct CustomLayerVec2 {
	Vec2^ value;
	KeyframeLayer<Vec2> kl_value;
}

struct CustomLayerStr {
	char^^ value;
	KeyframeLayer<char^> kl_value;
}

struct CustomLayerListAdder<T, CustomLayerT> {
	static void AddLayer(using CustomLayerList& list) {
		let fs = list_ptr as List<T>^;

		fs#add(KeyframeInterpolator<T>.DefaultValue()); // TODO: check whether resized
		layers.add({
			.name = f"[{layers.size}]",
			.deleted_member = false,
			.kind = CustomLayerT{
				.value = NULL, // NOTE: set below
				.kl_value = .()
			}
		});

		if (layers.size != fs#size) {
			assert(layers.size == fs#size, "layers.size != fs#size   !!!");
		}

		for (int i in 0..layers.size) {
			(layers.get(i).kind as CustomLayerT).value = ^fs#get(i);
		}
	}
}

struct CustomLayerList {
	CustomStructMemberType type;

	List<CustomLayer> layers;
	void^ list_ptr;
	bool immutable = false; // constant # of elements!

	bool is_open = true; // non-serialized

	void AddLayer() {
		switch (type) {
			CustomStructMemberTypeBool -> {
				CustomLayerListAdder<bool, CustomLayerBool>.AddLayer(this);
			},
			CustomStructMemberTypeFloat -> {
				CustomLayerListAdder<float, CustomLayerFloat>.AddLayer(this);
			},
			CustomStructMemberTypeStr -> {
				CustomLayerListAdder<char^, CustomLayerStr>.AddLayer(this);
			},
			CustomStructMemberTypeInt -> {
				CustomLayerListAdder<int, CustomLayerInt>.AddLayer(this);
			},
			CustomStructMemberTypeColor -> {
				CustomLayerListAdder<Color, CustomLayerColor>.AddLayer(this);
			},
			CustomStructMemberTypeVec2 -> {
				CustomLayerListAdder<Vec2, CustomLayerVec2>.AddLayer(this);
			},
			else -> {
				println("[WARNING]: AddLayer {kind = ?} not impl!!");
			}
		}
	}
}

choice CustomLayerKind {
	CustomLayerBool,
	CustomLayerFloat,
	CustomLayerInt,
	CustomLayerVec2,
	CustomLayerColor,
	CustomLayerStr,
	CustomLayerList,
	;

	void StealData(Self& stealee) {
		assert(this == stealee, "stealee is bad, nope");
		
		switch (this) {
			CustomLayerBool it -> {
				it.kl_value = stealee as CustomLayerBool.kl_value;
			},
			CustomLayerFloat it -> {
				it.kl_value = stealee as CustomLayerFloat.kl_value;
			},
			CustomLayerInt it -> {
				it.kl_value = stealee as CustomLayerInt.kl_value;
			},
			CustomLayerVec2 it -> {
				it.kl_value = stealee as CustomLayerVec2.kl_value;
			},
			CustomLayerColor it -> {
				it.kl_value = stealee as CustomLayerColor.kl_value;
			},
			CustomLayerStr it -> {
				it.kl_value = stealee as CustomLayerStr.kl_value;
			},
			CustomLayerList it -> {
				let& stolen = stealee as CustomLayerList;
				for (int i in 0..stolen.layers.size) {
					it.AddLayer();
					if (it.layers.get(i).kind == stolen.layers.get(i).kind) {
						it.layers.get(i).kind.StealData(stolen.layers.get(i).kind);
					} else {
						println(t"[WARNING]: desirialize - CustomLayerList, layers[{i}].kind != old_layers[{i}].kind");
					}
				}
				// TODO: wee sus on this one, just check ok? :7))))))333
				// it.layers = ;
			},
		}
	}

	bool operator:==(Self& other) { // not full equality, just type really, maybe this should be a function but i like how this looks more... so sue me, ok?!!
		return match (this) {
			CustomLayerBool -> other is CustomLayerBool,
			CustomLayerFloat -> other is CustomLayerFloat,
			CustomLayerInt -> other is CustomLayerInt,
			CustomLayerVec2 -> other is CustomLayerVec2,
			CustomLayerColor -> other is CustomLayerColor,
			CustomLayerStr -> other is CustomLayerStr,
			CustomLayerList it -> other is CustomLayerList && it.type == (other as CustomLayerList).type,
		};
	}

	static Self Deserialize(yaml_serializer& s) {
		assert(s.is_load, "s.is_load please");
		string which = string(s.obj.get_str("which"));
		defer which.delete();

		void^ value = NULL; // NOTE: real value ptrs need to be linked post-load!

		let kl_value_s = s.into_obj("kl_value");

		if (which == .("bool")) {
			return CustomLayerBool{
				:value,
				.kl_value = KeyframeLayer<bool>.Deserialize(kl_value_s)
			};
		} else if (which == .("float")) {
			KeyframeLayer<float> kl_value = {};
			return CustomLayerFloat{
				:value,
				.kl_value = KeyframeLayer<float>.Deserialize(kl_value_s)
			};
		} else if (which == .("int")) {
			return CustomLayerInt{
				:value,
				.kl_value = KeyframeLayer<int>.Deserialize(kl_value_s)
			};
		} else if (which == .("Vec2")) {
			return CustomLayerVec2{
				:value,
				.kl_value = KeyframeLayer<Vec2>.Deserialize(kl_value_s)
			};
		} else if (which == .("Color")) {
			return CustomLayerColor{
				:value,
				.kl_value = KeyframeLayer<Color>.Deserialize(kl_value_s)
			};
		} else if (which == .("str")) {
			return CustomLayerStr{
				:value,
				.kl_value = KeyframeLayer<char^>.Deserialize(kl_value_s)
			};
		} else if (which == .("list")) {
			let type_s = s.into_obj("type");
			let layers_s = s.into_obj("layers");
			return CustomLayerList{
				.type = CustomStructMemberType.Deserialize(type_s),
				.layers = ListSerializer<CustomLayer>.Deserialize(layers_s),
				.list_ptr = NULL,
				.immutable = s.obj.get_bool("immutable"),
			};
		}

		panic("Deserialize - unreachable!");
		CustomLayerBool _;
		return _;
	}

	void SerializeStore(yaml_serializer& s) {
		assert(!s.is_load, "!s.is_load please");
		switch (this) {
			CustomLayerBool it -> {
				s.obj.put_literal("which", "bool");
				s.obj.put_obj("kl_value", it.kl_value.Serialize());
			},
			CustomLayerFloat it -> {
				s.obj.put_literal("which", "float");
				s.obj.put_obj("kl_value", it.kl_value.Serialize());
			},
			CustomLayerInt it -> {
				s.obj.put_literal("which", "int");
				s.obj.put_obj("kl_value", it.kl_value.Serialize());
			},
			CustomLayerVec2 it -> {
				s.obj.put_literal("which", "Vec2");
				s.obj.put_obj("kl_value", it.kl_value.Serialize());
			},
			CustomLayerColor it -> {
				s.obj.put_literal("which", "Color");
				s.obj.put_obj("kl_value", it.kl_value.Serialize());
			},
			CustomLayerStr it -> {
				s.obj.put_literal("which", "str");
				s.obj.put_obj("kl_value", it.kl_value.Serialize());
			},
			CustomLayerList it -> {
				s.obj.put_literal("which", "list");
				let type_s = s.into_obj("type");
				it.type.SerializeStore(type_s);
				s.obj.put_obj("layers", ListSerializer<CustomLayer>.Serialize(it.layers));
				s.obj.put_bool("immutable", it.immutable);
			},
		}
	}
}

struct CustomLayerUIParams {
	float max_elem_time;
	float curr_local_time;

	float& global_time;
	Element& element;
}


float element_variables_width = GlobalSettings.get_float("element_variables_width", 100);
float element_timeline_width = 1; // TODO: get set per frame... do better?
PanelExpander element_variables_expander = { ^element_variables_width, "element_variables_width", .min = 100 };

struct CustomLayer {
	char^ name;
	CustomLayerKind kind;

	char^ value_fn_expr_str = NULL;
	void^ value_fn = NULL;

	// TODO: bool keyed = false; ?

	// non-serialized
	bool deleted_member = false; // true when this used to be a named member, but has since been removed/renamed

	static Self Deserialize(yaml_serializer& s) {
		let kind_s = s.into_obj("kind");
		return {
			.name = s.obj.get_str("name"),
			.kind = CustomLayerKind.Deserialize(kind_s),
			.value_fn_expr_str = "", // TODO:
			.value_fn = NULL,
		};
	}

	yaml_object Serialize() {
		yaml_object obj = {};
		obj.put_literal("name", name);
		let kind_s = yaml_serializer.Obj(obj.put_empty("kind"), false);
		kind.SerializeStore(kind_s);
		return obj;
	}

	void UpdateState(float lt) {
		switch (kind) {
			CustomLayerBool it -> {
				if (it.value == NULL) { break; }
				it.kl_value.Set(it.value, lt);
			},
			CustomLayerFloat it -> {
				if (it.value == NULL) { break; }
				it.kl_value.Set(it.value, lt);
			},
			CustomLayerInt it -> {
				if (it.value == NULL) { break; }
				it.kl_value.Set(it.value, lt);
			},
			CustomLayerVec2 it -> {
				if (it.value == NULL) { break; }
				it.kl_value.Set(it.value, lt);
			},
			CustomLayerColor it -> {
				if (it.value == NULL) { break; }
				it.kl_value.Set(it.value, lt);
			},
			CustomLayerStr it -> {
				if (it.value == NULL) { break; }
				it.kl_value.Set(it.value, lt);
			},
			CustomLayerList it -> {
				for (let& layer in it.layers) {
					layer.UpdateState(lt);
				}
			}
		}
	}

	static float row_height = rem(1.5);
	static Clay_Sizing row_sizing = { .width = CLAY_SIZING_GROW(), .height = CLAY_SIZING_FIXED(row_height) };
	static Clay_ChildAlignment align_y_center = { .y = CLAY_ALIGN_Y_CENTER };
	void UI(using CustomLayerUIParams& params) {
		Color bg = kind is CustomLayerList ? (kind as CustomLayerList.immutable ? theme.button | Colors.Transparent) | Colors.Transparent;
		$clay({
			.layout = {
				.sizing = row_sizing,
				.childAlignment = align_y_center,
			},
			.backgroundColor = bg,
		}) {
			if (kind is CustomLayerList) {
				let& list = kind as CustomLayerList;
				$clay({ .layout = { .sizing = .(4, 0) }}) {};
				clay_text(name, {
					.fontSize = rem(1),
					.textColor = Colors.White,
				});
				clay_x_grow_spacer();

				if (!list.immutable) {
					if (ClayButton("+", .(t"{^list}-add"), .(rem(1), rem(1)))) {
						list.AddLayer();
					}
				}

				if (ClayButton(list.is_open ? "^" | "v", .(t"{^list.is_open}"), .(rem(1), rem(1)))) {
					list.is_open = !list.is_open;
				}
			} else {
				$clay({
					.layout = {
						.sizing = {
							.width = CLAY_SIZING_FIXED(100),
							.height = CLAY_SIZING_GROW(),
						},
						.childAlignment = align_y_center,
					},
					// .scroll = { .horizontal = true }
				}) {
					clay_text(name, {
						.fontSize = rem(1),
						.textColor = Colors.White,
					});
				};

				Clay_ElementId content_id = .(t"{^this}-content");
				$clay({
					.id = content_id,
					.layout = {
						.sizing = .Grow(),
						.childAlignment = align_y_center,
					},
					// .scroll = { .horizontal = true },
				}) {
					// CONTENT PART
					switch (kind) {
						CustomLayerBool it -> {
							// TODO: check-box UI
							if (ClayButton(*it.value ? "x" | " ", .(t"{it.value}"), .(rem(1), rem(1)))) {
								it.kl_value.InsertValue(curr_local_time, !(*it.value));
								it.kl_value.Set(it.value, curr_local_time);
							}

							it.kl_value.ControlButtons(it.value, params);
						},
						CustomLayerFloat it -> {
							let changed = SlidingFloatTextBox(.(t"{it.value}"), it.value);
							if (changed is Some) {
								it.kl_value.InsertValue(curr_local_time, changed as Some);
								it.kl_value.Set(it.value, curr_local_time);
							}

							it.kl_value.ControlButtons(it.value, params);
						},
						CustomLayerInt it -> {
							// TODO: int-sliding-textbox
							let changed = SlidingIntTextBox(.(t"{it.value}"), it.value);
							if (changed is Some) {
								it.kl_value.InsertValue(curr_local_time, changed as Some);
								it.kl_value.Set(it.value, curr_local_time);
							}

							it.kl_value.ControlButtons(it.value, params);
						},
						CustomLayerVec2 it -> {
							$clay({
								.layout = {
									.sizing = {
										.width = CLAY_SIZING_FIXED(60),
										.height = CLAY_SIZING_GROW(),
									},
									.childAlignment = {
										.y = CLAY_ALIGN_Y_CENTER
									}
								}
							}) {
								let changed = SlidingFloatTextBox(.(t"{it.value}-x"), ^it.value#x);
								if (changed is Some) {
									it.kl_value.InsertValue(curr_local_time, v2(changed as Some, it.value#y));
									it.kl_value.Set(it.value, curr_local_time);
								}
							};

							$clay({
								.layout = {
									.sizing = {
										.width = CLAY_SIZING_FIXED(60),
										.height = CLAY_SIZING_GROW(),
									},
									.childAlignment = {
										.y = CLAY_ALIGN_Y_CENTER
									}
								}
							}) {
								let changed = SlidingFloatTextBox(.(t"{it.value}-y"), ^it.value#y);
								if (changed is Some) {
									it.kl_value.InsertValue(curr_local_time, v2(it.value#x, changed as Some));
									it.kl_value.Set(it.value, curr_local_time);
								}
							};

							it.kl_value.ControlButtons(it.value, params);
						},
						CustomLayerColor it -> {
							Clay_ElementId color_tile_id = .(t"{it.value}-color-tile");
							bool visual_hovered = Clay.VisuallyHovered(color_tile_id);
							$clay({
								.id = color_tile_id,
								.layout = {
									.sizing = .(rem(1), rem(1)),
								},
								.backgroundColor = *it.value,
								.border = .(1, (visual_hovered) ? theme.panel_border_highlight | theme.panel_border), // TODO: better color
							}) {
								bool tile_hovered = Clay.Hovered();
								if (tile_hovered) {
									cursor_type = .Pointer;

									if (mouse.LeftClickPressed()) {
										getting_color_picked = (getting_color_picked == ^it) ? NULL | ^it;
									}
								}

								if (^it == getting_color_picked) {
									// TODO: wrap into pop-up
									Clay_ElementId color_popup_id = .(t"{it.value}-color-tile-popup");
									$VERT({
										.id = color_popup_id,
										.backgroundColor = theme.panel,
										.border = .(1, theme.panel_border),
										.floating = {
											.attachTo = CLAY_ATTACH_TO_PARENT,
											.attachPoints = { //TODO: based on fitting on screen (under/over)... (popup)
												.element = CLAY_ATTACH_POINT_LEFT_TOP,
												.parent = CLAY_ATTACH_POINT_LEFT_BOTTOM,
											}
										}
									}) {
										$HORIZ_GROW() {
											if (ClayIconButton(Textures.pin_icon)) {
												global_color_picker_pinned_open = GlobalSettings.set_bool("global_color_picker_pinned_open", !global_color_picker_pinned_open);
											}
											clay_x_grow_spacer();
											if (ClayIconButton(Textures.close_icon)) {
												getting_color_picked = NULL;
											}
										};

										$clay({
											.layout = { .sizing = .(200, 200), },
										}) {
											let color_res = global_color_picker.Update("global-color-picker", rem(0.5));
											if (color_res is Some) { // changed!
												it.kl_value.InsertValue(curr_local_time, color_res.!);
												it.kl_value.Set(it.value, curr_local_time);
											}
										};
									};

									if (!global_color_picker_pinned_open && mouse.LeftClickPressed() && !Clay.GetBoundingBox(color_popup_id).Contains(mouse_pos) && !tile_hovered) {
										getting_color_picked = NULL;
									}
								}
							};

							it.kl_value.ControlButtons(it.value, params);
						},
						CustomLayerStr it -> {
							Rectangle rect = Clay.GetBoundingBox(content_id);
							char^ change_text = TextBox(UiElementID.ID(it.value, 0), .(t"{^this}-text"), *it.value, .Grow(), rem(1));

							if (change_text != NULL) {
								it.kl_value.InsertValue(curr_local_time, strdup(change_text)); // NOTE: keyframes MUST delete str as it is owned!!!
								it.kl_value.Set(it.value, curr_local_time);
							}

							it.kl_value.ControlButtons(it.value, params);
						},
						CustomLayerList it -> {
							unreachable();
						}
					}

					// value_fn
					{
						char^ change_text = TextBox(UiElementID.ID(^this, 0), .(t"{^this}-vfnstr"), value_fn_expr_str, .Grow(), rem(1));
						if (change_text != NULL) {
							if (value_fn_expr_str != NULL) { free(value_fn_expr_str); }
							value_fn_expr_str = strdup(change_text);

							// TRY TO COMPILE CODE
							char^ code_prelude = "";
							char^ ret_t_str = "float";
							char^ code = t"{code_prelude}\n{ret_t_str} THE_VALUE_FN() -> {value_fn_expr_str};";

							// let maybe_fn = AttemptCompileCrustSnippet(code, "THE_VALUE_FN");
						}
					}
				};
			}
		};

		// lists (children) ----------
		if (kind is CustomLayerList) {
			let& list = kind as CustomLayerList;

			if (list.is_open) {

				$clay({
					.layout = {
						.layoutDirection = CLAY_TOP_TO_BOTTOM,
						.padding = { 12, 0, 0, 0},
						.sizing = {
							.width = CLAY_SIZING_GROW()
						}
					}
				}) {
					for (let& child in list.layers) {
						child.UI(params);
					}
				};
			}
		}
	}

	void AttemptCompileCrustSnippet(char^ code, char^ name_of_desired_fn) {
		{ // crust compilation
			io.rmrf_if_existent("tcc_temp");
			io.mkdir("tcc_temp");

			let code = t"include path(\"../../std\");import std;\nint fn(int a) \{ return {expr}; }";
			io.write_file_text("tcc_temp/temp.cr", code);

			system(t"crust build tcc_temp -out-dir:tcc_tout -build-type:cgen -unity-build");
		}

		TCCState& tcc = *.new().! else return Err{};
		defer tcc.delete();

		tcc.set_options("-g");
		tcc.set_output_type(TCC_OUTPUT_MEMORY);
		// typedef int TCCBtFunc(void *udata, void *pc, const char *file, int line, const char* func, const char *msg);
		tcc.set_backtrace_func(NULL, (void^ udata, void^ pc, c:const_char_star file, int line, c:const_char_star func, c:const_char_star msg):int -> {
			println(t"backtrace from: {file as char^}");
			// panic("bad news bears");

			return 0;
		});

		{
			tcc.add_include_path("tcc_tout");
			tcc.add_file("tcc_tout/__unity__.c");
		}
		tcc.relocate().! else return Err{};

		fn_ptr<int(int)> fn = (tcc.get_symbol("fn").! else return Err{}) as ..;

		for i in 0..10 {
			println(t"{fn(i)=}");
		}
		
		return Unit{};
	}

	void TimelineUI(using CustomLayerUIParams& params) {
		// TIMELINE PART
		Clay_ElementId timeline_id = .(t"{^this}-timeline");
		$clay({
			.id = timeline_id,
			.layout = {
				.sizing = row_sizing,
			},
		}) {
			Rectangle rect = Clay.GetElementData(timeline_id).boundingBox;

			switch (kind) {
				CustomLayerBool it -> {
					it.kl_value.UI(rect, params);
				},
				CustomLayerFloat it -> {
					it.kl_value.UI(rect, params);
				},
				CustomLayerInt it -> {
					it.kl_value.UI(rect, params);
				},
				CustomLayerVec2 it -> {
					it.kl_value.UI(rect, params);
				},
				CustomLayerColor it -> {
					it.kl_value.UI(rect, params);
				},
				CustomLayerStr it -> {
					it.kl_value.UI(rect, params);
				},
				CustomLayerList it -> {
					// ... list itself has no timeline
				},
			}
		};

		// lists (children) ----------
		if (kind is CustomLayerList) {
			let& list = kind as CustomLayerList;

			if (list.is_open) {
				for (let& child in list.layers) {
					child.TimelineUI(params);
				}
			}
		}
	}
}


struct CustomPureFnElement : ElementImpl {
	char^ fn_name;
	CustomLayer custom_layer_list;
	Opt<CustomStructHandle> custom_args_handle;

	ElementKind Kind() -> .FX_FN;
	void _FillYaml(yaml_object& yo) {
		yo.put_literal("fn_name", fn_name);
		yo.put_obj("custom_layer_list", custom_layer_list.Serialize());
	}

	void UI(CustomLayerUIParams& params) {
		if (custom_args_handle is Some) {
			custom_layer_list.UI(params);
		}
	}
	void TimelineUI(CustomLayerUIParams& params) {
		if (custom_args_handle is Some) {
			custom_layer_list.TimelineUI(params);
		}
	}
	void UpdateState(float lt) {
		if (custom_args_handle is Some) {
			custom_layer_list.UpdateState(lt);
		}
	}

	void Draw(Element^ e, float current_time) {
		let fn_getter_res = code_man.GetFn(t"__scriptgen_NewFxFn_{fn_name}"); // creates handle

		switch (fn_getter_res) {
			void^ ok -> {

				fn_ptr<CustomFnHandle()> fn_getter = ok as ..;
				CustomFnHandle fn_handle = fn_getter();

				FxArgs base_args = {
					.pos = e#pos,
					.scale = e#scale,
					.rotation = e#rotation,
					.color = e#color,
					.local_time = current_time - e#start_time,
					.composition_time = current_time,
					._element = e,
					// .text = ""
				};

				if (fn_handle.custom_arg_t_name != NULL) {
					fn_ptr<void(FxArgs^, void^)> fn = fn_handle.ptr as ..;

					if (custom_args_handle is None) {
						let fx_new_fn_name = t"__scriptgen_NewFxArgs_{fn_handle.custom_arg_t_name}";
						let fn_args_new_res = code_man.GetFn(fx_new_fn_name); // creates handle
						switch (fn_args_new_res) {
							void^ ok -> {
								fn_ptr<CustomStructHandle()> args_new_fn = ok as ..;
								CustomStructHandle the_struct_handle = args_new_fn();

								println(t"called {fx_new_fn_name}: -> struct w/ {the_struct_handle.members.size} members");
								// for (let& member in the_struct_handle.members) {
								// 	printf("%p %f %d\n", member.name, member.name, strlen(member.name));
								// }

								List<CustomLayer> layers = {};
								for (let& member in the_struct_handle.members) {
									layers.add({
										.name = member.name,
										.deleted_member = false,
										.kind = match (member.t) {
											CustomStructMemberTypeBool -> CustomLayerBool{
												.value = member.ptr,
												.kl_value = .(),
											},
											CustomStructMemberTypeFloat -> CustomLayerFloat{
												.value = member.ptr,
												.kl_value = .(),
											},
											CustomStructMemberTypeInt -> CustomLayerInt{
												.value = member.ptr,
												.kl_value = .(),
											},
											CustomStructMemberTypeVec2 -> CustomLayerVec2{
												.value = member.ptr,
												.kl_value = .(),
											},
											CustomStructMemberTypeColor -> CustomLayerColor{
												.value = member.ptr,
												.kl_value = .(),
											},
											CustomStructMemberTypeStr -> CustomLayerStr{
												.value = member.ptr,
												.kl_value = .(),
											},
											CustomStructMemberTypeList l -> CustomLayerList{
												.layers = .(),
												.list_ptr = l.list_ptr,
												.type = *l.elem_t
											},
											else -> {
												// println(t"{member.t is CustomStructMemberTypeFloat=}");
												// println(t"{member.t is CustomStructMemberTypeDouble=}");
												// println(t"{member.t is CustomStructMemberTypeBool=}");
												// println(t"{member.t is CustomStructMemberTypeUChar=}");
												// println(t"{member.t is CustomStructMemberTypeChar=}");
												// println(t"{member.t is CustomStructMemberTypeUShort=}");
												// println(t"{member.t is CustomStructMemberTypeShort=}");
												// println(t"{member.t is CustomStructMemberTypeUInt=}");
												// println(t"{member.t is CustomStructMemberTypeInt=}");
												// println(t"{member.t is CustomStructMemberTypeULong=}");
												// println(t"{member.t is CustomStructMemberTypeLong=}");
												// println(t"{member.t is CustomStructMemberTypeStr=}");
												// println(t"{member.t is CustomStructMemberTypeVec2=}");
												// println(t"{member.t is CustomStructMemberTypeColor=}");
												// println(t"{member.t is CustomStructMemberTypeList=}");
												// println(t"{member.t is CustomStructMemberTypeCustomStruct=}");

												println("unimplemented type element.cr Draw()");
												c:c:`printf("unimpl.kind == %d... omg!\n", member->t.kind);`;
												panic("nope!");
												return CustomLayerFloat{
													.value = member.ptr,
													.kl_value = .(),
												};
											}
										}
									});
								}

								// data transfer -------------------
								@partial switch (custom_layer_list.kind) {
									CustomLayerList it -> {
										for (let& old_layer in it.layers) {
											bool found = false;
											bool found_but_bad = false;
											for (let& new_layer in layers) {
												if (str_eq(old_layer.name, new_layer.name)) {
													if (new_layer.kind == old_layer.kind) {
														found = true;
														new_layer.kind.StealData(old_layer.kind);
													} else {
														found_but_bad = true;
														println(t"[NOTE]: while doing deserialize-custom-transfer, found {old_layer.name}, whose type seems to have changed [TODO: proper transfer in this case (mark deleted_member = true)], old_layer.which = {(old_layer.kind as c:any).kind as int}, new_layer.which = {(new_layer.kind as c:any).kind as int}");
													}
													break;
												}
											}
											
											if (!found) {
												layers.add(old_layer with { .deleted_member = true });
											} else if (found_but_bad) {
												println("[TODO]: found_but_bad case (data transfer on-deserialize)");
												// layers.add(old_);
											}
										}
									},
									else -> {
										println("[WARNING]: custom_layer_list must be CustomLayerList!");
									}
								}
								// -------------------------------

								// TODO: move over old layers/keyframe layers!
								custom_layer_list = {
									.name = "Custom Properties",
									.kind = CustomLayerList{ // TODO: should be CustomLayerStruct
										:layers,
										.list_ptr = NULL,
										.type = CustomStructMemberTypeFloat{},
										.immutable = true,
									}
								};
								println("[TODO]: transfer old custom layer values! (if struct was modified... we currently assume it wasn't)");
								custom_args_handle = the_struct_handle;
							},
							char^ err -> {
								e#err_msg = t"failed to create new custom args `{fn_handle.custom_arg_t_name}`";
								return;
							}
						}
					}

					switch (custom_args_handle) {
						CustomStructHandle args_handle -> {
							// println(t"calling __scriptgen_NewFxFn_{fn_name}(<Args>, <CustomArgs>)");
							fn(^base_args, args_handle.ptr);
						},
						None -> {
							e#err_msg = "[INTERNAL-ERROR]: custom_args_handle is None";
						}
					}
				} else {
					fn_ptr<void(FxArgs^)> fn = fn_handle.ptr as ..;
					custom_args_handle = none;

					// println(t"calling __scriptgen_NewFxFn_{fn_name}(<Args>)");
					fn(^base_args);
				}

				e#err_msg = NULL;
			},
			char^ err -> {
				e#err_msg = t"Failed to load effect `{fn_name}`. Make sure it exists and is correctly named in script.cr and is marked @fx_fn! Error: {err}";
			}
		}
	}
	char^ ImplTypeStr() -> "fx";

	static Self^ Make(char^ fn_name) -> Box<Self>.Make({
		:fn_name,
		.custom_layer_list = {
			.name = "Custom Properties",
			.kind = CustomLayerList{ // TODO: should be CustomLayerStruct
				.layers = {},
				.list_ptr = NULL,
				.type = CustomStructMemberTypeFloat{},
				.immutable = true,
			}
		},
		.custom_args_handle = none
	});

	CustomLayer^ CustomLayersList() -> ^custom_layer_list;
}

// layer metadata
// (elements are stored separately)
struct EditLayer {
	Composition^ comp;
	bool is_audio_layer = false;

	ElementHandle[] element_handles = {}; // must be kept sorted!!
	bool visible = true;
	bool has_been_configured = false; // any settings have ever been changed (meaning this layer should not be destroyed all willy nilly by UI)

	ElementIterable elem_iter() -> {
		:comp,
		.handles = element_handles,
	};

	static Self^ new(Composition^ comp) -> Box<Self>.Make({
		:comp,
	});

	// warns on failure... maybe shouldn't?
	int? get_index_in_comp(Composition& comp) {
		for layer, i in comp.layers {
			if (layer == ^this) {
				return i;
			}
		}
		warn(.MISSING_LAYER_IN_COMPOSITION);
		return none;
	}

	void AddElement(ElementHandle eh) {
		element_handles.insert_ordered_by_user_data(eh, (ElementHandle& a, ElementHandle& b, void^ user_data):int -> {
			Composition^ comp = user_data;
			let ap = comp#elements.Get(a);
			let bp = comp#elements.Get(b);
			if (ap == NULL || bp == NULL) { return 0; }

			if (ap#start_time > bp#start_time) { return 1; }
			if (ap#start_time == bp#start_time) { return 0; }
			return -1;
		}, comp);
		// TODO: keep sorted??
	}

	void DeleteElement(ElementHandle eh) {
		for (int i = element_handles.size - 1; i >= 0; i--) {
			if (eh == element_handles[i]) {
				element_handles.remove_at(i);
			}
		}
	}
}

struct ElementIterable {
	Composition^ comp;
	ElementHandle[]& handles;

	ElementIter iter() -> {
		:comp,
		:handles,
		.i = 0,
	};
}
struct ElementIter {
	Composition^ comp;
	ElementHandle[]& handles;
	int i = 0;
	
	bool has_next() -> (i) < handles.size && comp#elements.Has(handles[i]);
	Element& next() -> comp#elements.GetRef(handles[i++]);
}

struct ElementHandle {
	int id;
	int last_index = -1;

	construct(int id) -> { :id };

	bool operator:==(Self other) -> id == other.id; // NOTE: don't care abt last_index, since that is caching-only

	// Element^ Get() -> active_elements.!#Get(this);
	// bool Exists() -> active_elements.!#Has(this);
	//
	// Element& GetRef() -> active_elements.!#GetRef(this);
}

struct Element {
	static int next_element_id = 0;

	// TODO: load up from project-save
	static int num_elements_created = 0; // TODO: make per-project!
	static char^ NextElementName() -> f"Elem {Self.num_elements_created++}";
	int id;
	ElementHandle handle() -> .(id);
	ElementHandle into() -> .(id);

	ElementImpl^ content_impl;

	char^ name;

	// temporal
	float start_time; // inclusive
	float duration;   // exclusive: i.e. at `start_time+duration`, this has just stopped playing
	// ^ TODO: maybe use `int` as frame-counts for these..?

	// layer
	EditLayer^ layer;

	ElementHandle? linked_to = none; // TODO: can maybe add start_time_offset..?
	
	CustomLayer default_layers; // CustomLayerList
	bool ready = false; // NOTE: never use an Element (specifically their layers) when not ready

	// transform-related/common args
	Vec2 pos;

	Vec2 scale;
	bool uniform_scale; // TODO:

	float rotation;
	Vec2 CoM = { 0.5, 0.5 }; // center of rotation/scaling: [0, 1] -> on image; outside [0, 1]: not currently supported... (TODO:?)

	float opacity;

	Color color;

	bool visible; // currently unused in program overall...

	char^ err_msg; // not-serialized
	
	Data^ data;

	// Opt<float> _LastKeyframeTime(char^ key_name, float current_local_time, CustomLayerList& list) {
	// 	for (let& layer in list.layers) {
	// 		if (str_eq(key_name, layer.name)) {
	// 		}
	// 	}
	// 	return none;
	// }

	ElementKind Kind() -> content_impl#Kind();
	bool IsVideo() -> Kind() == .VIDEO;

	char^ NameUIText() {
		if (IsVideo()) {
			Element& elem = this;
			VideoElement^ vid = (c:elem#content_impl.ptr);
			if (vid#loading) {
				return t"{name} (loading{LoadingDotDotDotStr()})"; 
			}
		}
		return name;
	}

	Color TintColor() {
		Color tint = color;
		tint.a = (tint.a as float * (opacity / 100.0)) as..;
		return tint;
	}

	List<CustomLayer>^ CustomLayersListInternalPtr() -> content_impl#CustomLayersList() == NULL ? NULL | ^((content_impl#CustomLayersList())#kind as CustomLayerList).layers;

	CustomLayerList^ DefaultLayersListAsList() -> ^(default_layers.kind as CustomLayerList);
	CustomLayerList^ CustomLayersListAsList() -> content_impl#CustomLayersList() == NULL ? NULL | ^(content_impl#CustomLayersList()#kind as CustomLayerList);

	// void Serialize(Path p, bool is_load) {
	// 	yaml_serializer s = yaml_serializer.IO(p, is_load);
	// 	defer s.finish();
	//
	// 	s.str_default(name, "name", "UNTITLED");
	// 	s.float_default(start_time, "start_time", 0);
	// 	s.float_default(duration, "end_time", 0);
	// 	s.int_default(layer, "layer", 0);
	//
	// 	if (is_load) {
	// 		let default_layers_s = s.into_obj("default_layers");
	// 		default_layers = CustomLayer.Deserialize(default_layers_s);
	// 	} else {
	// 		s.obj.put_obj("default_layers", default_layers.Serialize());
	// 	}
	//
	// 	// serialize.float_default(pos.x, "pos.x", 0);
	// 	// serialize.float_default(pos.y, "pos.y", 0);
	// 	// // serialize.int_default(pos.y, "pos.y", 0); // TODO: bool - uniform_scale
	// 	// serialize.float_default(scale.x, "scale.x", 100);
	// 	// serialize.float_default(scale.y, "scale.y", 100);
	// 	// serialize.float_default(rotation, "rotation", 0);
	// 	// serialize.float_default(opacity, "opacity", 0);
	//
	// 	//	 TODO: important!!! toby!! not working on windows!!
	// 	// serialize.uchar_default(color.r, "color.r", 0);
	// 	// serialize.uchar_default(color.g, "color.g", 0);
	// 	// serialize.uchar_default(color.b, "color.b", 0);
	// 	// serialize.uchar_default(color.a, "color.a", 0);
	//
	// 	// serialize.int_default(color.r, "color.r", 0);
	// 	// serialize.int_default(color.g, "color.g", 0);
	// 	// serialize.int_default(color.b, "color.b", 0);
	// 	// serialize.int_default(color.a, "color.a", 0);
	// 	// serialize.int_default(pos.y, "pos.y", 0); // TODO: bool - visible
	// 	// serialize.int_default(pos.y, "pos.y", 0); // TODO: char^ - err_msg???
	//
	// 	// impl
	// 	if (is_load) {
	// 		content_impl = ElementImplFromYaml(s.obj.get_int("kind") as ElementKind, s.obj.get_obj("impl"));
	// 	} else {
	// 		s.obj.put_int("kind", Kind() as int);
	// 		s.obj.put_object("impl", ElementImplToYaml(content_impl));
	// 	}
	//
	// 	// keyframe layers!!!
	// }

	CustomLayerFloat& _GetFloatLayer(int i) {
		return ((default_layers.kind as CustomLayerList).layers.get(i)).kind as CustomLayerFloat;

	}

	CustomLayerVec2& _GetVec2Layer(int i) {
		return ((default_layers.kind as CustomLayerList).layers.get(i)).kind as CustomLayerVec2;
	}

	CustomLayerColor& _GetColorLayer(int i) {
		return ((default_layers.kind as CustomLayerList).layers.get(i)).kind as CustomLayerColor;
	}

	KeyframeLayer<Vec2>& kl_pos() -> _GetVec2Layer(0).kl_value;
	KeyframeLayer<Vec2>& kl_scale() -> _GetVec2Layer(1).kl_value;
	KeyframeLayer<float>& kl_rot() -> _GetFloatLayer(2).kl_value;
	KeyframeLayer<float>& kl_opacity() -> _GetFloatLayer(3).kl_value;
	KeyframeLayer<Color>& kl_color() -> _GetColorLayer(1).kl_value;

	void LinkDefaultLayers() {
		_GetVec2Layer(0).value  = ^pos;
		_GetVec2Layer(1).value  = ^scale;
		_GetFloatLayer(2).value = ^rotation;
		_GetVec2Layer(3).value = ^CoM;
		_GetFloatLayer(4).value = ^opacity;
		_GetColorLayer(5).value = ^color;
		ready = true;
	}

	static CustomLayer CreateUnititializedDefaultLayers() {
		List<CustomLayer> layers = {};
		layers.add({
			.name = "pos",
			.kind = CustomLayerVec2{
				.value = NULL,
				.kl_value = .()
			}
		});
		layers.add({
			.name = "scale",
			.kind = CustomLayerVec2{
				.value = NULL,
				.kl_value = .()
			}
		});
		layers.add({
			.name = "rotation",
			.kind = CustomLayerFloat{
				.value = NULL,
				.kl_value = .()
			}
		});
		layers.add({
			.name = "CoM",
			.kind = CustomLayerVec2{
				.value = NULL,
				.kl_value = .()
			}
		});
		layers.add({
			.name = "opacity",
			.kind = CustomLayerFloat{
				.value = NULL,
				.kl_value = .()
			}
		});
		layers.add({
			.name = "color",
			.kind = CustomLayerColor{
				.value = NULL,
				.kl_value = .()
			}
		});

		return {
			.name = "Standard Properties",
			.kind = CustomLayerList{
				:layers,
				.type = CustomStructMemberTypeFloat{}, // TODO: ????
				.list_ptr = NULL, // TODO: ?
				.immutable = true,
			}
		};
	}

	// name: pass NULL for auto-generated name
	construct(ElementImpl^ content_impl, char^ name, float start_time, float duration, EditLayer^ layer, Vec2 pos, Vec2 scale) -> {
		.id = next_element_id++,
		:content_impl,
		.name = (name != NULL) ? name | Element.NextElementName(),
		:pos,
		:scale,
		.uniform_scale = true,
		.rotation = 0,
		.opacity = 100,
		.color = Colors.White,
		.visible = true,
		.data = NULL,
		.err_msg = NULL,
		:start_time,
		:duration,
		:layer,
		.default_layers = Self.CreateUnititializedDefaultLayers()
	};

	// TODO: make sure that inclusion/exclusion is done right here
	bool CollidesWith(float other_start_time, float other_duration) -> end_time() > other_start_time && (other_start_time + other_duration) > start_time;

	// TODO: content type: rectangle, ellipse, image, text, etc
	// IDEA: text -> keyframe the text, morph between

	float end_time() -> start_time + duration;
	// bool IsVisibleAtTime(float time) -> visible && (time >= start_time && end_time() > time);
	bool ActiveAtTime(float time) -> time >= start_time && end_time() > time;

	bool Hovered() {
		// TODO:(worldspace)
		return ws_mouse_pos.Between(pos, pos + scale);
	}

	void DrawGizmos() {
		let gizmoColor = Color{.r=255,.g=0,.b=255,.a=50};
		// d.RectRot(pos, scale, rotation, gizmoColor);
		d.RectOutline(pos, scale, hex("00000088"));
		d.Circle(pos + scale * v2(0.5, 0.5), 10, hex("9999FF55"));
	}

	void Draw(float current_time) {
		content_impl#Draw(^this, current_time);
		// d.RectRot(pos, scale, rotation, color);
	}

	static float row_height = rem(1.5);
	static Clay_Sizing row_sizing = { .width = CLAY_SIZING_GROW(), .height = CLAY_SIZING_FIXED(row_height) };
	void TimelineLines(CustomLayerUIParams& params) {
		for (float second = 0.1; second < params.max_elem_time; second += 0.1) {
			float line_x = element_timeline_width * (second / params.max_elem_time);
			$clay({
				.layout = {
					.sizing = {
						.width = CLAY_SIZING_FIXED(1),
						.height = CLAY_SIZING_GROW(),
					}
				},
				.floating = Clay.FloatingPassthru({ line_x, 0 }),
				.backgroundColor = theme.timeline_tenth_second_line,
			}) {};
		}

		for (float second = 1; second < params.max_elem_time; second++) {
			float line_x = element_timeline_width * (second / params.max_elem_time);
			$clay({
				.layout = {
					.sizing = {
						.width = CLAY_SIZING_FIXED(1),
						.height = CLAY_SIZING_GROW(),
					}
				},
				.floating = Clay.FloatingPassthru({ line_x, 0 }),
				.backgroundColor = theme.timeline_second_line,
			}) {};
		}

		float line_x = element_timeline_width * (params.curr_local_time / params.max_elem_time);
		$clay({
			.layout = {
				.sizing = {
					.width = CLAY_SIZING_FIXED(1),
					.height = CLAY_SIZING_GROW(),
				}
			},
			.floating = Clay.FloatingPassthru({ line_x, 0 }),
			.backgroundColor = Colors.Orange,
		}) {};
	}

	static bool timeline_dragging = false;
	@html
	void UI(CustomLayerUIParams& params) {
		$clay({
			.layout = {
				.sizing = .Grow(),
			},
			// .scroll = { // TODO: only scroll when too many layers!!
			// 	.vertical = true,
			// }
		}) {
			$Panel(element_variables_expander) {
				default_layers.UI(params);
				content_impl#UI(params);
			};

			$clay({
				.layout = {
					.sizing = .Grow(),
					.layoutDirection = CLAY_TOP_TO_BOTTOM,
				},
				.id = CLAY_ID(c"keyframe-timeline")
			}) {
				Rectangle rect = Clay.GetElementData(CLAY_ID(c"keyframe-timeline")).boundingBox;
				element_timeline_width = rect.width;

				if (mouse.LeftClickReleased()) {
					timeline_dragging = false;
				}
				if (Clay.Hovered() && mouse.LeftClickPressed()) {
					timeline_dragging = true;
				}
				if (timeline_dragging) {
					// TODO: use time_per_frame
					params.global_time = std.clamp(start_time + rect.Amount01(mouse.GetPos()).x * params.max_elem_time, params.element.start_time, params.element.end_time() - (1.0 / 60));
				}
				TimelineLines(params);
				default_layers.TimelineUI(params);
				content_impl#TimelineUI(params);
			};
		};
	}

	void UpdateState(float t) {
		float lt = t - start_time;
		default_layers.UpdateState(lt);
		opacity = std.clamp(opacity, 0, 100);
		// scale.y = scale.x; // uniform scale

		// TODO: color
		content_impl#UpdateState(lt);

		// println(t"{pos.x} {pos.y} {scale.x} {scale.y} {kl_pos_x.HasValue()} a");
		// pos = v2(300, 200) * v2(t, t);
		// scale = v2(100, 100) * v2(1.0 + t, t * 2);
	}

	void ClearTimelinesCompletely() {
		// TODO:
		println("TODO: ClearTimelinesCompletely");
		// kl_pos_x.Clear();
		// kl_pos_y.Clear();
		// kl_scale.Clear();
		// kl_rotation.Clear();
		// kl_opacity.Clear();
	}

	void ApplyData(Data^ data) {
		this.data = data;
	}

	// Apply keyframe data to an element's keyframes
    void ApplyKeyframeData(Data data, float start_time = 0.0, float frame_offset = 0.1) {
        let frame_time = start_time;

		// Custom float data
		List<CustomLayer>^ custom_layers_list_ptr = CustomLayersListInternalPtr();
		if (custom_layers_list_ptr != NULL && ListContainsString(data.headers, "Value")) {
			for (let& layer in *custom_layers_list_ptr) {
				if (layer.kind is CustomLayerList) {
					let& layer_list = layer.kind as CustomLayerList;
					StrMap<int> layer_map = .();
	
					// Create a map of layer names to layer indices
					for (let i = 0; i < layer_list.layers.size; i++) {
						let layer_name = layer_list.layers.get(i).name;
						layer_map.put(layer_name, i);
					}
	
					// Insert keyframes into the appropriate layer
					for (let i = 0; i < data.data.size; i++) {
						let row = data.data.get(i);
						let layer_name = row.get(t"Name");
	
						if (!layer_map.has(layer_name)) {
							// Add a new layer if it doesn't exist
							if (ListContainsString(data.headers, "Value")) {
								CustomLayerListAdder<float, CustomLayerFloat>.AddLayer(layer_list);
							} else if (ListContainsString(data.headers, "Text")) {
								CustomLayerListAdder<char^, CustomLayerStr>.AddLayer(layer_list);
							}
	
							let new_layer = ^layer_list.layers.get(layer_list.layers.size - 1);
							new_layer#name = layer_name;
							layer_map.put(layer_name, layer_list.layers.size - 1);
						}

							// Handle float values
							if (ListContainsString(data.headers, "Value") && !StringContains(row.get(t"Value"),"\"")) {
								let value = row.get_float(t"Value");
								let keyframe = ListContainsString(data.headers, "Time") ? row.get_float(t"Time") | frame_time;
								let out_interpolation_mode = KeyframeInterpolationMode.Linear;
								let in_interpolation_mode = KeyframeInterpolationMode.Linear;
		
								(layer_list.layers.get(layer_map.get(layer_name)).kind as CustomLayerFloat).kl_value.Insert({
									.time = keyframe,
									.value = value,
									.out_interpolation_mode = out_interpolation_mode,
									.in_interpolation_mode = in_interpolation_mode
								});
							}
		
							// // Handle string values
							// if (ListContainsString(data.headers, "Value") && StringContains(row.get(t"Value"),"\"")) {
							// 	let text_value = row.get(t"Value");
							// 	println(t"found text value: {text_value}");
							// 	(layer_list.layers.get(layer_map.get(layer_name)).kind as CustomLayerStr).value.Set({
							// 		.time = keyframe,
							// 		.value = text_value,
							// 		.out_interpolation_mode = out_interpolation_mode,
							// 		.in_interpolation_mode = in_interpolation_mode
							// 	});
							// }
					}
				}
			}
		}
	
		// Default keyframed parameters
        for (let& row in data.data) {
            let keyframe_t = frame_time;
            frame_time = frame_time + frame_offset;
            if (ListContainsString(data.headers, "Time")) {
                keyframe_t = row.get_float(t"Time");
            }

            if (ListContainsString(data.headers, "X")) { // this sucks...
				float x = row.get_float("X");
				float y = (ListContainsString(data.headers, "Y"))  ? row.get_float("Y") | x;
				if (ListContainsString(data.headers, "Y")) {
					println("[WARNING]: please put Y in your data row, WHAT ARE YOU DOING?!!!");
				}
                kl_pos().InsertValue(
                    keyframe_t,
                    v2(x, y)
				);
            }
            if (ListContainsString(data.headers, "Scale")) {
				float scale = row.get_float(t"Scale");
                kl_scale().InsertValue(
                    keyframe_t,
                    v2(scale, scale)
				);
            }
            if (ListContainsString(data.headers, "Rotation")) {
                kl_rot().InsertValue(
                    keyframe_t,
                    row.get_float(t"Rotation")
				);
            }
            if (ListContainsString(data.headers, "Opacity")) {
                kl_opacity().InsertValue(
                    keyframe_t,
                    row.get_float(t"Opacity")
				);
            }
        }
    }
}


// NOTE: FxArgs-facing API
// float LastKeyframeTime(Element& elem, char^ key_name, float current_local_time) {
// 	// // TODO: improve API
// 	// @partial switch (elem._LastKeyframeTime(key_name, current_local_time, *elem.DefaultLayersListAsList())) {
// 	// 	float it -> {
// 	// 		return it;
// 	// 	}
// 	// }
// 	//
// 	// if (elem.CustomLayersListAsList() != NULL) {
// 	// 	@partial switch (elem._LastKeyframeTime(key_name, current_local_time, *elem.CustomLayersListAsList())) {
// 	// 		float it -> {
// 	// 			return it;
// 	// 		}
// 	// 	}
// 	// }
//
// 	return 0;
// }


// KeyframeLayer make_interesting_layer_x() {
// 	KeyframeLayer layer = .();
// 	for (int i = 0; i != 6 * 4; i++) {
// 		layer.keyframes.add({
// 			.time = i as float / 4,
// 			.value = 600 + ((i % 2 == 0) ? 1 | -1) * 200
// 		});
// 	}
// 	return layer;
// }
//
// KeyframeLayer make_interesting_layer_y() {
// 	KeyframeLayer layer = .();
// 	for (int i = 0; i != 36; i++) {
// 		layer.keyframes.add({
// 			.time = i as float / 6,
// 			.value = Sin01(0.5 * i) * 600
// 		});
// 	}
// 	return layer;
// }
//
// KeyframeLayer make_rotation() {
// 	KeyframeLayer layer = .();
// 	layer.keyframes.add({
// 		.time = 0,
// 		.value = 0
// 	});
// 	layer.keyframes.add({
// 		.time = 5,
// 		.value = 360
// 	});
// 	return layer;
// }
//
// KeyframeLayer make_cool_layer_x() {
// 	KeyframeLayer layer = .();
// 	for (int i = 0; i != 3 * 4; i++) {
// 		layer.keyframes.add({
// 			.time = i as float / 4 * 2.0,
// 			.value = 600 + ((i % 2 == 0) ? 1 | -1) * 200
// 		});
// 	}
// 	return layer;
// }
//
// KeyframeLayer make_cool_layer_y() {
// 	KeyframeLayer layer = .();
// 	for (int i = 0; i != 18; i++) {
// 		layer.keyframes.add({
// 			.time = i as float / 3,
// 			.value = Sin01(0.5 * i) * 600
// 		});
// 	}
// 	return layer;
// }
//
// Element make_cool_fn_element() -> {
// 	.content_impl = CustomPureFnElement.new("cool_effect"),
// 	.name = "cool_fn",
// 	.pos = v2(0, 0),
// 	.scale = v2(20, 20),
// 	.uniform_scale = true,
// 	.rotation = 0,
// 	.opacity = 1,
// 	.color = Colors.Orange,
// 	.kl_pos_x = make_cool_layer_x(),
// 	.kl_pos_y = make_cool_layer_y(),
// 	.kl_rotation = make_rotation(),
// 	.kl_opacity = .(),
// 	.kl_scale = .(),
// 	.visible = false,
// 	.err_msg = NULL
// };
//
// Element make_custom_effect_element(char^ effect_name) -> {
// 	.content_impl = CustomPureFnElement.new(effect_name),
// 	.name = effect_name,
// 	.pos = v2(400, 400),
// 	.scale = v2(150, 150),
// 	.uniform_scale = true,
// 	.rotation = 0,
// 	.opacity = 1,
// 	.color = Colors.Green,
// 	.kl_pos_x = .(),
// 	.kl_pos_y = .(),
// 	.kl_rotation = .(),
// 	.kl_opacity = .(),
// 	.kl_scale = .(),
// 	.visible = true,
// 	.err_msg = NULL
// };
//
// Element make_perlin_element() {
// 	let it = make_custom_effect_element("perlin_field");
//
// 	it.kl_pos_x.Insert({
// 		.time = 0,
// 		.value = 0,
// 	});
// 	it.kl_pos_y.Insert({
// 		.time = 0,
// 		.value = 200,
// 	});
//
// 	it.kl_pos_x.Insert({
// 		.time = 2.5,
// 		.value = 500,
// 	});
// 	it.kl_pos_y.Insert({
// 		.time = 2.5,
// 		.value = 400,
// 	});
//
// 	it.kl_pos_x.Insert({
// 		.time = 5,
// 		.value = 1000,
// 	});
// 	it.kl_pos_y.Insert({
// 		.time = 5,
// 		.value = 200,
// 	});
//
// 	return it;
// }
//
// Element make_interesting_element() -> {
// 	.content_impl = make_rect(),
// 	.name = Element.NextElementName(),
// 	.pos = v2(0, 0),
// 	.scale = v2(200, 200),
// 	.uniform_scale = true,
// 	.rotation = 0,
// 	.opacity = 1,
// 	.color = c:BLUE,
// 	.kl_pos_x = make_interesting_layer_x(),
// 	.kl_pos_y = make_interesting_layer_y(),
// 	.kl_rotation = make_rotation(),
// 	.kl_opacity = .(),
// 	.kl_scale = .(),
// 	.visible = false,
// 	.err_msg = NULL
// };
//
// Element make_element() -> {
// 	.content_impl = make_circle(),
// 	.name = Element.NextElementName(),
// 	.pos = v2(400, 400),
// 	.scale = v2(150, 150),
// 	.uniform_scale = true,
// 	.rotation = 0,
// 	.opacity = 1,
// 	.color = c:GREEN,
// 	.kl_pos_x = .(),
// 	.kl_pos_y = .(),
// 	.kl_rotation = .(),
// 	.kl_opacity = .(),
// 	.kl_scale = .(),
// 	.visible = true,
// 	.err_msg = NULL
// };
//
// Element make_image_element(char^ file_path) -> {
// 	.content_impl = make_image(file_path),
// 	.name = Element.NextElementName(),
// 	.pos = v2(400, 400),
// 	.scale = v2(150, 150),
// 	.uniform_scale = true,
// 	.rotation = 0,
// 	.opacity = 1,
// 	.color = c:GREEN,
// 	.kl_pos_x = .(),
// 	.kl_pos_y = .(),
// 	.kl_rotation = .(),
// 	.kl_opacity = .(),
// 	.kl_scale = .(),
// 	.visible = true,
// 	.err_msg = NULL
// };

struct StableArena<T> {
	int block_size_in_elements;

	List<char^> memory_blocks = {};
	int capacity = 0;
	int size = 0;

	void add(T val) {
		if (size >= capacity) {
			memory_blocks.add(malloc(sizeof<T> * block_size_in_elements));
			capacity += block_size_in_elements;
		}
		size++;
		this[size - 1] = val;
	}

	T^ push_get_ptr(T val) {
		add(val);
		return ^this[size - 1];
	}

	void delete() {
		for (let& block in memory_blocks) {
			free(block);
		}
	}

	T& operator:[](int i) {
		if ((i) < 0 || i >= size) {
			panic(f"StableArena[{i=}] OOB for {size=}");
		}
		let block_as_elem_t_ptr = memory_blocks[i / block_size_in_elements] as T^;
		return block_as_elem_t_ptr [i % block_size_in_elements];
	}

	StableArenaIterator<T> iter() -> { .ptr = ^this };
}

struct StableArenaIterator<T> {
	int i = 0;
	StableArena<T>^ ptr;

	bool has_next() -> (i) < ptr#size;
	T& next() -> (*ptr)[i++];
}

struct ElementStorage {
	StableArena<Element> impl = {
		.block_size_in_elements = 256,
	};

	StableArenaIterator<Element> iter() -> impl.iter();

	Element^ Get(ElementHandle& id) {
		if (id.last_index == -1 || impl[id.last_index].id != id.id) {
			for (int i = 0; (i) < impl.size; i++) {
				let& elem = impl[i];
				if (elem.id == id.id) {
					id.last_index = i;
					return ^elem;
				}
			}
			return NULL;
		}
		return ^impl[id.last_index];
	}
	bool Has(ElementHandle& id) -> Get(id) != NULL;

	Element? GetOptConcrete(ElementHandle& id) {
		let em = Get(id);
		if (em == NULL) { return none; }
		return *em;
	}

	Element& GetRef(ElementHandle& id) {
		let em = Get(id);
		if (em == NULL) { panic(t"GetForSure({id.id=}) failed"); }
		return *em;
	}

	Element& Add(Element element) {
		impl.add(element);
		let handle = ElementHandle{
			.id = element.id,
			.last_index = impl.size - 1,
		};
		return GetRef(handle); // TODO: do less safely b/c we're all good :)
	}
}
// ElementStorage^? active_elements = none;

// -------------------------------------
struct Project {
	char^ name;
	bool is_untitled;

	Composition^[] comps;
	int? selected_comp_index;

	Path project_dir;
	Path resource_dir;

	Resources resources;

	static Self^ new() {
		Project^ res = malloc(sizeof(Project));

		*res =
			with let project_dir = Env.edit_temp_projects/f"{res}" in
		{
			.name = "Untitled", // untitled
			.is_untitled = true,
			.comps = {},
			.selected_comp_index = none,
			:project_dir,
			.resource_dir = project_dir/"resources", // TODO
			.resources = {
				.project = *res,
				.gifs = .(),
			}
		};

		io.mkdir_if_nonexistent(res#project_dir);
		io.mkdir_if_nonexistent(res#resource_dir);

		return res;
	}
}

struct Composition {
	Project^ proj;

	int width;
	int height;

	ElementStorage elements;
	EditLayer^[] layers;
	EditLayer^[] audio_layers;

	ElementHandle[] selection;
	ElementHandle? primary_selection = none;
	ElementHandle[] effective_selection;

	ViewRangeSlider vertical_view_range_slider;
	ViewRangeSlider view_range_slider;

	int frame_rate;
	float time_per_frame;

	int current_frame;
	float current_time;

	float effective_max_time() {
		float max_time = 0;
		for (let& layer in layers) {
			if (!layer#element_handles.is_empty() && elements.Has(layer#element_handles.back())) {
				max_time = std.max(max_time, elements.GetRef(layer#element_handles.back()).end_time());
			}
		}
		return max_time;
	}
	int effective_max_frames() -> (effective_max_time() * frame_rate) as int;
	// ------------------------------------
	ElementIterable selection_iter() -> {
		.comp = ^this,
		.handles = selection,
	};

	ElementIterable effective_selection_iter() -> {
		.comp = ^this,
		.handles = effective_selection,
	};

	static Self^ new(Project^ proj, int width, int height) {
		Self^ self = malloc(sizeof<Self>);

		int frame_rate = 60;
		float time_per_frame = 1.0 / frame_rate;

		int current_frame = 0;
		float current_time = 0;

		float max_time = GlobalSettings.get_float("default_max_time", 5); // 5 second default, can be changed in saves/globalsettings.yaml
		int max_frames = (max_time * frame_rate) as int;

		ViewRangeSlider view_range_slider = {
			.range = {
				.start = 0,
				.end = max_time,
			}
		};

		ViewRangeSlider vertical_view_range_slider = {
			.range = {
				.start = 0,
				.end = 3, // since we start w/ 3 layers!
			},
			.vertical = true,
			.reverse = true,
		};

		*self = {
			:proj,
			:width, :height,
			.elements = {},
			.selection = {},
			.effective_selection = {},
			.layers = {},
			.audio_layers = {},
			:frame_rate,
			:time_per_frame,
			:current_frame,
			:current_time,
			:view_range_slider,
			:vertical_view_range_slider,
		};

		self#AddVisualLayer();
		self#AddVisualLayer();
		self#AddVisualLayer();

		self#AddAudioLayer();
		self#AddAudioLayer();

		return self;
	}

	bool IsSelected(ElementHandle handle) {
		for (let! selected in selection) {
			if (selected == handle) { return true; }
		}
		return false;
	}

	void AddVisualLayer() {
		layers.add(EditLayer.new(^this));
	}

	void AddAudioLayer() {
		let layer = EditLayer.new(^this);
		layer#is_audio_layer = true;
		audio_layers.add(layer);
	}

	// void SetSelection(ElementHandle eh) {
	// 	selection.clear();
	// 	selection.add(eh);
	// }

	// void AddToSelection(ElementHandle eh) {
	// 	for (let handle in selection) {
	// 		if (handle.id == eh.id) { return; }
	// 	}
	// 	selection.add(eh);
	// }

	void _DeleteElement(ElementHandle eh) {
		// let& el = elements.Get(eh).! else return;
		if (!elements.Has(eh)) { return; }
		elements.GetRef(eh).layer#DeleteElement(eh);
		// TODO: mark element as deleted
	}

	void COMMIT_ACTION(Action action, Action undo_action) {
		ActionArgs args = { .comp = this };
		action.impl#Apply(args);
	}

	void NOTE_ACTION(Action action, Action undo_action) {
		
	}

	void PUSH_ACTION() {

	}

	void POP_ACTION() {

	}
}



// -------------------------------------

interface ActionImpl {
	ActionInfo Info();
	void Apply(ActionArgs& args);
	void delete(ActionDeleteArgs& args);
}
struct Action {
	static int next_id = 0;

	int id;
	ActionImpl^ impl;

	construct(ActionImpl^ impl) -> { .id = next_id++, :impl };

	ActionInfo Info() -> impl#Info();
	void Apply(ActionArgs& args) -> impl#Apply(args);
}

struct ActionInfo {
	char^ name;
}
struct ActionArgs {
	Composition& comp;
}
struct ActionDeleteArgs {
	Composition& comp;
}

struct UndoRedoAction {
	Action redo;
	Action undo;
}

// current state is reached by always deepest traversal always visiting last (newest-added) child first
struct UndoNode {
	UndoRedoAction action;
	UndoNode^ parent = NULL;
	UndoNode[] children = {};

	void AddChild(UndoNode node) {
		children.add(node);
		for (let& child in children) { // list may have been realloc-ed elsewhere!
			child.parent = ^this;
		}
	}
}

struct UndoTree {
	UndoNode dummy_root; // pls never access its `action`!
	UndoNode^ curr;

	Self^ new() {
		Self^ self = malloc(sizeof<Self>);
		self#dummy_root.children = {};
		self#dummy_root.parent = NULL;
		// NOTE: action is left uninit..... :/

		self#curr = ^self#dummy_root;

		return self;
	}

	void AddUndo(UndoNode undo) {
		curr#AddChild(undo);
		curr = ^curr#children.back();
	}

	void Undo(ActionArgs args) {
		if (curr#parent == NULL) { return; } // we are the 'dummy_root' (meaning there's nothing to undo!)

		curr#action.undo.Apply(args);
		curr = curr#parent;
	}
	void Redo(ActionArgs args) {
		if (curr#children.is_empty()) { return; } // no level below (i.e: nothing to redo!)

		curr = ^curr#children.back();
		curr#action.redo.Apply(args);
	}
}
