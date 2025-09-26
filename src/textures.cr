import rl;

struct TexturesLib {
	Texture pixel;
	Texture empty;
	Texture eye_open_icon;
	Texture eye_closed_icon;
	Texture warning_icon;
	Texture image_icon;
	Texture play_icon;
	Texture pause_icon;
	Texture muted_icon;
	Texture unmuted_icon;
	Texture close_icon;
	Texture pin_icon;
	Texture keyframe_left_arrow_icon;
	Texture keyframe_right_arrow_icon;
	Texture keyframe_add_icon;
	Texture keyframe_remove_icon;
	Texture header_bg;

	static Texture LoadAssetsPng(char^ png_name) {
		return rl.LoadTexture(t"assets/{png_name}.png");
	}

	static void LoadAssets() {
		Textures = {
			.pixel = LoadAssetsPng("pixel"),
			.empty = LoadAssetsPng("empty"),
			.eye_open_icon = LoadAssetsPng("eye_open"),
			.eye_closed_icon = LoadAssetsPng("eye_closed"),
			.warning_icon = LoadAssetsPng("warning_dark"),
			.image_icon = LoadAssetsPng("image"),
			.play_icon = LoadAssetsPng("play"),
			.pause_icon = LoadAssetsPng("pause"),
			.muted_icon = LoadAssetsPng("muted"),
			.unmuted_icon = LoadAssetsPng("unmuted"),
			.close_icon = LoadAssetsPng("close"),
			.pin_icon = LoadAssetsPng("pin"),
			.keyframe_right_arrow_icon = LoadAssetsPng("keyframe_right_arrow"),
			.keyframe_left_arrow_icon = LoadAssetsPng("keyframe_left_arrow"),
			.keyframe_add_icon = LoadAssetsPng("keyframe_add"),
			.keyframe_remove_icon = LoadAssetsPng("keyframe_remove"),
			.header_bg = LoadAssetsPng("header_bg"),
		};
	}
}
TexturesLib Textures;
