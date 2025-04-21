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
import face;

int KIND_RECT = 0;
int KIND_CIRCLE = 1;
int KIND_IMAGE = 2;
int KIND_FX_FN = 3;
int KIND_VIDEO = 4;
int KIND_FACE = 5;
interface ElementImpl {
	void Draw(Element^ e, float current_time);

	void UpdateState(float lt);

	void UI(CustomLayerUIParams& params);

	char^ ImplTypeStr();

	CustomLayer^ CustomLayersList();

	int Kind();
	void _FillYaml(yaml_object& yo);
}

ElementImpl^ ElementImplFromYaml(int kind, yaml_object& yo) {
	ElementImpl^ it;
	switch (kind) {
		KIND_RECT -> {
			it = RectElement.Make();
		},
		KIND_CIRCLE -> {
			it = CircleElement.Make();
		},
		KIND_IMAGE -> {
			it = ImageElement.Make(yo.get_str("file_path"));
		},
		KIND_FX_FN -> {
			let em = CustomPureFnElement.Make(yo.get_str("fn_name"));
			let custom_layer_list_s = yaml_serializer.Obj(yo.get_obj("custom_layer_list"), true);
			em#custom_layer_list = CustomLayer.Deserialize(custom_layer_list_s);
			// TODO: need to actually transfer over old when re-loading fn-ptr!

			it = em;
		},
		KIND_VIDEO -> {
			it = VideoElement.Make(yo.get_str("video_file_path"), yo.get_float("dec_fr"));
		},
		KIND_FACE -> {
			it = FaceElement.Make();
		},
		else -> {
			println(t"[WARNING]: ElementImplFromYaml unknown case {kind}");
			it = RectElement.Make();
		}
	}

	return it;
}

yaml_object ElementImplToYaml(ElementImpl^ impl) {
	yaml_object yo = {};
	yo.put_int("kind", impl#Kind());
	impl#_FillYaml(yo);
	return yo;
}

struct RectElement : ElementImpl {
	void UI(CustomLayerUIParams& params) {}
	void UpdateState(float lt) {}
	void Draw(Element^ e, float current_time) {
		d.RectRot(e#pos, e#scale, e#rotation, e#TintColor());
	}

	int Kind() -> KIND_RECT;
	void _FillYaml(yaml_object& yo) { }

	char^ ImplTypeStr() -> "rect";
	CustomLayer^ CustomLayersList() -> NULL;

	static Self^ Make() -> malloc(sizeof<Self>);
}

struct CircleElement : ElementImpl {
	void UI(CustomLayerUIParams& params) {}
	void UpdateState(float lt) {}
	void Draw(Element^ e, float current_time) {
		d.Circle(e#pos + e#scale.scale(0.5), e#scale.x / 2, e#TintColor()); // TODO: allow ellipse
	}

	int Kind() -> KIND_CIRCLE;
	void _FillYaml(yaml_object& yo) { }

	char^ ImplTypeStr() -> "circle";
	CustomLayer^ CustomLayersList() -> NULL;


	static Self^ Make() -> malloc(sizeof<Self>);
}

struct ImageCache {
	static StrMap<Texture> cache;

	static Texture Get(char^ file_path) {
		if (cache.has(file_path)) {
			return cache.get(file_path);
		}
		Texture tex = rl.LoadTexture(file_path);
		cache.put(file_path, tex);
		return tex;
	}
	
	static void Unload() {
		for (let pair in cache) {
			pair.value.delete();
		}
	}
}

struct ImageElement : ElementImpl {
	char^ file_path;
	
	void UI(CustomLayerUIParams& params) {}
	void UpdateState(float lt) {}
	void Draw(Element^ e, float current_time) {
		d.TextureRotCenter(ImageCache.Get(file_path), e#pos + e#scale.scale(0.5), e#scale, e#rotation, e#TintColor());
	}

	int Kind() -> KIND_IMAGE;
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
	void UpdateState(float lt) {}
	void Draw(Element^ e, float current_time) {
		if (loaded) {
			int frame_idx = ((current_time - (e#start_time - start_offset)) * (dec_fr * speed)) as int % frames.size; 
			d.TextureAtSize(frames.get(frame_idx), e#pos.x, e#pos.y, e#scale.x, e#scale.y);
		}
	}

	int Kind() -> KIND_VIDEO;
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

struct FaceElement : ElementImpl {
	List<Face> face_data = .();
	//char^ open_path = OpenImageFileDialog("Select open mouth image");
	//char^ close_path = OpenImageFileDialog("Select close mouth image");
	//char^ sound_path = OpenImageFileDialog("Select sound file");


	Texture open = rl.LoadTexture("popcat_open_trans.png");
	Texture close = rl.LoadTexture("popcat_close_trans.png");

	// hard coded 
	Color alpha = c:WHITE;
	
	float yaw_flip = 1;
	int yaw_thresh = 20;

	c:Sound pop = c:LoadSound("assets/pop.mp3");
	bool popping = true;

	CustomLayer^ CustomLayersList() -> NULL;

	void UI(CustomLayerUIParams& params) {}
	void UpdateState(float lt) {}
	void Draw(Element^ e, float current_time) {
		if (face_data.is_empty()) {
			return;
		}
		alpha.a = 150;

		// todo: unhard framerate
		int frame_rate = face_data.get(0).frame_rate;
		float frame_width = face_data.get(0).frame_width as float;
		float frame_height = face_data.get(0).frame_height as float;

		float height_weight = 900.0/ frame_height;
		float width_weight = 1200.0/ frame_width;
		
		Face f = face_data.get(((current_time - e#start_time) * frame_rate) as int % face_data.size);

		yaw_flip = (f.yaw > yaw_thresh) ? -1.0 | 1.0;

		float face_w = (f.w as float * width_weight);
		float face_h = (f.h as float * height_weight);
		int face_x = ((f.x as float * width_weight) + face_w/2.0) as int;
		int face_y = (f.y as float * height_weight + face_h/2.0) as int;

		Rectangle openSourceRec = { 0, 0, yaw_flip * open.width, open.height};
		Rectangle closeSourceRec = { 0, 0, yaw_flip * close.width, close.height};
		Rectangle sourceRec = { 0, 0, f.w as float, f.h as float };

        Rectangle destRec = { face_x, face_y, face_w, face_h};
        Vec2 origin = { face_w/2, face_h/2};
		int roll = f.roll;
		int roll_thresh = 90;
		int base = (roll > 0) ? 180 | -180;
		if (dabs(roll) > roll_thresh) {
			roll = (base - roll) % 180;
		}

		if (popping == false && f.m == 1) {
			popping = true;
			c:PlaySound(pop);
		}
		if (f.m == 0) {
			popping = false;
		}
		if (f.m == 1) {
			c:DrawTexturePro(open, openSourceRec, c:destRec, c:origin, roll, alpha);
			// d.TextureAtSize(open, f.x, f.y, f.w, f.h);
		}
		else {
			c:DrawTexturePro(close, closeSourceRec, c:destRec, c:origin, roll, alpha);
			// d.TextureAtSize(close, f.x, f.y, f.w, f.h);
		}
	}

	int Kind() -> KIND_FACE;
	void _FillYaml(yaml_object& yo) {
	}
	void _FillFromYaml(yaml_object& yo) {
	}

	char^ ImplTypeStr() -> "face";
	List<CustomLayer>^ CustomLayers() -> NULL;

	static Self^ Make() {
		List<Face> face_data = cv_pipe();
		return Box<Self>.Make({ .face_data = face_data });
	}
}

c:`typedef CustomFnHandle (*CustomPureFnGetter)(void);`;
c:`typedef CustomStructHandle (*CustomArgsNewFn)(void);`;
c:`typedef void (*CustomPureFnWithoutCustomParams)(FxArgs*);`;
c:`typedef void (*CustomPureFnWithCustomParams)(FxArgs*, void*);`;

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
}


float custom_layer_timeline_width = GlobalSettings.get_float("custom_layer_timeline_width", 100);

PanelExpander custom_layer_timeline_expander = { ^custom_layer_timeline_width, "custom_layer_timeline_width", .min = 100, .reverse = true };

struct CustomLayer {
	char^ name;
	CustomLayerKind kind;
	// TODO: bool keyed = false; ?

	// non-serialized
	bool deleted_member = false; // true when this used to be a named member, but has since been removed/renamed

	static Self Deserialize(yaml_serializer& s) {
		let kind_s = s.into_obj("kind");
		return {
			.name = s.obj.get_str("name"),
			.kind = CustomLayerKind.Deserialize(kind_s),
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

	void UI(using CustomLayerUIParams& params) {
		#clay({
			.layout = {
				// TODO: ?
				.sizing = {
					.width = CLAY_SIZING_GROW(),
					.height = CLAY_SIZING_FIXED(rem(1.5))
				},
				.childAlignment = {
					.y = CLAY_ALIGN_Y_CENTER
				}
			}
		}) {
			#clay({
				.layout = {
					.sizing = {
						.width = CLAY_SIZING_FIXED(100),
						.height = CLAY_SIZING_GROW(),
					},
					.childAlignment = {
						.y = CLAY_ALIGN_Y_CENTER
					}
				},
				.scroll = { .horizontal = true }
			}) {
				clay_text(name, {
					.fontSize = rem(1),
					.textColor = Colors.White,
				});
			}

			Clay_ElementId content_id = .(t"{^this}-content");
			#clay({
				.id = content_id,
				.layout = {
					.sizing = Clay_Sizing.Grow(),
					.childAlignment = {
						.y = CLAY_ALIGN_Y_CENTER
					}
				},
				.scroll = { .horizontal = true },
			}) {
				// CONTENT PART
				switch (kind) {
					CustomLayerBool it -> {
						// TODO: check-box UI
						if (ClayButton(*it.value ? "x" | " ", .(t"{it.value}"), .(rem(1), rem(1)))) {
							it.kl_value.InsertValue(curr_local_time, !(*it.value));
							it.kl_value.Set(it.value, curr_local_time);
						}
					},
					CustomLayerFloat it -> {
						let changed = SlidingFloatTextBox(.(t"{it.value}"), it.value);
						if (changed is Some) {
							it.kl_value.InsertValue(curr_local_time, changed as Some);
							it.kl_value.Set(it.value, curr_local_time);
						}
					},
					CustomLayerInt it -> {
						// TODO: int-sliding-textbox
						let changed = SlidingIntTextBox(.(t"{it.value}"), it.value);
						if (changed is Some) {
							it.kl_value.InsertValue(curr_local_time, changed as Some);
							it.kl_value.Set(it.value, curr_local_time);
						}
					},
					CustomLayerVec2 it -> {
						#clay({
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
						}

						#clay({
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
						}
					},
					CustomLayerColor it -> {
						#clay({
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
							let changed = SlidingUCharTextBox(.(t"{it.value}-r"), ^it.value#r, { .min = 0, .max = 255 });
							if (changed is Some) {
								it.kl_value.InsertValue(curr_local_time, (*it.value) with {
									r = changed as Some
								});
								it.kl_value.Set(it.value, curr_local_time);
							}
						}

						#clay({
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
							let changed = SlidingUCharTextBox(.(t"{it.value}-g"), ^it.value#g, { .min = 0, .max = 255 });
							if (changed is Some) {
								it.kl_value.InsertValue(curr_local_time, (*it.value) with {
									g = changed as Some
								});
								it.kl_value.Set(it.value, curr_local_time);
							}
						}

						#clay({
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
							let changed = SlidingUCharTextBox(.(t"{it.value}-b"), ^it.value#b, { .min = 0, .max = 255 });
							if (changed is Some) {
								it.kl_value.InsertValue(curr_local_time, (*it.value) with {
									b = changed as Some
								});
								it.kl_value.Set(it.value, curr_local_time);
							}
						}

						#clay({
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
							let changed = SlidingUCharTextBox(.(t"{it.value}-a"), ^it.value#a, { .min = 0, .max = 255 });
							if (changed is Some) {
								it.kl_value.InsertValue(curr_local_time, (*it.value) with {
									a = changed as Some
								});
								it.kl_value.Set(it.value, curr_local_time);
							}
						}

						#clay({
							.layout = {
								.sizing = .(rem(1), rem(1)),
							},
							.backgroundColor = *it.value,
							.border = .(1, theme.panel_border), // TODO: better color
						}) {}
					},
					CustomLayerStr it -> {
						Rectangle rect = Clay.GetBoundingBox(content_id);
						char^ change_text = TextBox(UiElementID.ID(it.value, 0), .(t"{^this}-text"), *it.value, Clay_Sizing.Grow(), rem(1));

						if (change_text != NULL) {
							it.kl_value.InsertValue(curr_local_time, strdup(change_text)); // NOTE: keyframes MUST delete str as it is owned!!!
							it.kl_value.Set(it.value, curr_local_time);
						}
					},
					CustomLayerList it -> { // it is NOT ref!!??
						if (!it.immutable) {
							if (ClayButton("+", .(t"{^this}-add"), Clay_Sizing.Grow(), rem(1))) {
								it.AddLayer();
							}
						}
					}
				}
			}

			custom_layer_timeline_expander.Update();

			// TIMELINE PART
			Clay_ElementId timeline_id = .(t"{^this}-timeline");
			#clay({
				.id = timeline_id,
				.layout = {
					.sizing = {
						.width = CLAY_SIZING_FIXED(custom_layer_timeline_width),
						.height = CLAY_SIZING_GROW()
					}
				},
			}) {
				Rectangle rect = Clay.GetElementData(timeline_id).boundingBox;

				switch (kind) {
					CustomLayerBool it -> {
						it.kl_value.UI(rect, params.max_elem_time, params.curr_local_time);
					},
					CustomLayerFloat it -> {
						it.kl_value.UI(rect, params.max_elem_time, params.curr_local_time);
					},
					CustomLayerInt it -> {
						it.kl_value.UI(rect, params.max_elem_time, params.curr_local_time);
					},
					CustomLayerVec2 it -> {
						it.kl_value.UI(rect, params.max_elem_time, params.curr_local_time);
					},
					CustomLayerColor it -> {
						it.kl_value.UI(rect, params.max_elem_time, params.curr_local_time);
					},
					CustomLayerStr it -> {
						it.kl_value.UI(rect, params.max_elem_time, params.curr_local_time);
					},
					CustomLayerList it -> {
						// ... list itself has no timeline
					},
				}
			}
		}

		if (kind is CustomLayerList) {
			let& list = kind as CustomLayerList;

			for (let& child in list.layers) {
				child.UI(params);
			}
		}

	}
}


struct CustomPureFnElement : ElementImpl {
	char^ fn_name;
	CustomLayer custom_layer_list;
	Opt<CustomStructHandle> custom_args_handle;

	int Kind() -> KIND_FX_FN;
	void _FillYaml(yaml_object& yo) {
		yo.put_literal("fn_name", fn_name);
		yo.put_obj("custom_layer_list", custom_layer_list.Serialize());
	}

	void UI(CustomLayerUIParams& params) {
		if (custom_args_handle is Some) {
			custom_layer_list.UI(params);
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

				c:CustomPureFnGetter fn_getter = ok;
				CustomFnHandle fn_handle = fn_getter();

				FxArgs base_args = {
					.pos = e#pos,
					.scale = e#scale,
					.rotation = e#rotation,
					.color = e#color,
					// .lt = cur
					// .text = ""
				};

				if (fn_handle.custom_arg_t_name != NULL) {
					c:CustomPureFnWithCustomParams fn = fn_handle.ptr;

					if (custom_args_handle is None) {
						let fx_new_fn_name = t"__scriptgen_NewFxArgs_{fn_handle.custom_arg_t_name}";
						let fn_args_new_res = code_man.GetFn(fx_new_fn_name); // creates handle
						switch (fn_args_new_res) {
							void^ ok -> {
								c:CustomArgsNewFn args_new_fn = ok;
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
												layers.add(old_layer with { deleted_member = true });
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
								println("[TODO]: transfer old custom layer values!");
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
					c:CustomPureFnWithoutCustomParams fn = fn_handle.ptr;
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
struct Layer {
	bool visible;
}

struct Element {
	// TODO: load up from project-save
	static int num_elements_created = 0; // TODO: make per-project!
	static char^ NextElementName() -> f"Elem {Self.num_elements_created++}";

	ElementImpl^ content_impl;

	char^ name;

	// temporal
	float start_time; // inclusive
	float duration;   // exclusive: i.e. at `start_time+duration`, this has just stopped playing
	// ^ TODO: maybe use `int` as frame-counts for these..?

	// layer
	int layer;
	
	CustomLayer default_layers; // CustomLayerList
	bool ready = false; // NOTE: never use an Element (specifically their layers) when not ready

	// transform-related/common args
	Vec2 pos;

	Vec2 scale;
	bool uniform_scale; // TODO:

	float rotation;

	float opacity;

	Color color;

	bool visible; // currently unused in program overall...

	char^ err_msg; // not-serialized
	
	Data^ data;


	Color TintColor() {
		Color tint = color;
		tint.a = (tint.a as float * (opacity / 100.0)) as..;
		return tint;
	}

	List<CustomLayer>^ CustomLayersListInternalPtr() -> content_impl#CustomLayersList() == NULL ? NULL | ^((content_impl#CustomLayersList())#kind as CustomLayerList).layers;

	void Serialize(Path p, bool is_load) {
		yaml_serializer s = yaml_serializer.IO(p, is_load);
		defer s.finish();

		s.str_default(name, "name", "UNTITLED");
		s.float_default(start_time, "start_time", 0);
		s.float_default(duration, "end_time", 0);
		s.int_default(layer, "layer", 0);

		if (is_load) {
			let default_layers_s = s.into_obj("default_layers");
			default_layers = CustomLayer.Deserialize(default_layers_s);
		} else {
			s.obj.put_obj("default_layers", default_layers.Serialize());
		}

		// serialize.float_default(pos.x, "pos.x", 0);
		// serialize.float_default(pos.y, "pos.y", 0);
		// // serialize.int_default(pos.y, "pos.y", 0); // TODO: bool - uniform_scale
		// serialize.float_default(scale.x, "scale.x", 100);
		// serialize.float_default(scale.y, "scale.y", 100);
		// serialize.float_default(rotation, "rotation", 0);
		// serialize.float_default(opacity, "opacity", 0);

		//	 TODO: important!!! toby!! not working on windows!!
		// serialize.uchar_default(color.r, "color.r", 0);
		// serialize.uchar_default(color.g, "color.g", 0);
		// serialize.uchar_default(color.b, "color.b", 0);
		// serialize.uchar_default(color.a, "color.a", 0);

		// serialize.int_default(color.r, "color.r", 0);
		// serialize.int_default(color.g, "color.g", 0);
		// serialize.int_default(color.b, "color.b", 0);
		// serialize.int_default(color.a, "color.a", 0);
		// serialize.int_default(pos.y, "pos.y", 0); // TODO: bool - visible
		// serialize.int_default(pos.y, "pos.y", 0); // TODO: char^ - err_msg???

		// impl
		if (is_load) {
			content_impl = ElementImplFromYaml(s.obj.get_int("kind"), s.obj.get_obj("impl"));
		} else {
			s.obj.put_int("kind", content_impl#Kind());
			s.obj.put_object("impl", ElementImplToYaml(content_impl));
		}

		// keyframe layers!!!
	}

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
		_GetFloatLayer(3).value = ^opacity;
		_GetColorLayer(4).value = ^color;
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
	construct(ElementImpl^ content_impl, char^ name, float start_time, float duration, int layer, Vec2 pos, Vec2 scale) -> {
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
		return mp_world_space.Between(pos, pos + scale);
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

	void UI(CustomLayerUIParams& params) {
		default_layers.UI(params);
		content_impl#UI(params);
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
					for (let i = 0; i < layer_list.layers.size; i++;) {
						let layer_name = layer_list.layers.get(i).name;
						layer_map.put(layer_name, i);
					}
	
					// Insert keyframes into the appropriate layer
					for (let i = 0; i < data.data.size; i++;) {
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

// KeyframeLayer make_interesting_layer_x() {
// 	KeyframeLayer layer = .();
// 	for (int i = 0; i != 6 * 4; i++;) {
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
// 	for (int i = 0; i != 36; i++;) {
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
// 	for (int i = 0; i != 3 * 4; i++;) {
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
// 	for (int i = 0; i != 18; i++;) {
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
