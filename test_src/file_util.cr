import std;
import rl;

Texture pixel = rl.LoadTextureFromImageDestructively(rl.GenImageColor(1, 1, Colors.White));

struct ShaderHotReloadBundle {
	Shader shader;
	long last_stat_mtime;
}

struct ShaderHotReload {
	static StrMap<ShaderHotReloadBundle> bundles = .();

	static Shader& _Load(char^ path, long last_stat_mtime = 0) {
		println(t"loading shader: {path}");
		if (bundles.has(path)) {
			bundles.get(path).shader.delete();
		}
		bundles.put(path, { rl.LoadShader(NULL, path), :last_stat_mtime });

		return bundles.get(path).shader;
	}

	static Shader& Get(char^ path) {
		if (!bundles.has(path)) {

			return _Load(path, 0);
		}

		let stat = io.stat_res(path);
		if (stat is Ok && stat as Ok.st_mtime != bundles.get(path).last_stat_mtime) {
			return _Load(path, stat as Ok.st_mtime);
		}

		return bundles.get(path).shader;
	}
}

struct TextureHotReloadBundle {
	Texture texture;
	long last_stat_mtime;
}

struct TextureHotReload {
	static StrMap<TextureHotReloadBundle> bundles = .();

	static Texture& _Load(char^ path, long last_stat_mtime) {
		println(t"loading texture: {path}");
		if (bundles.has(path)) {
			bundles.get(path).texture.delete();
		}
		bundles.put(path, { rl.LoadTexture(path), :last_stat_mtime });
		return bundles.get(path).texture;
	}

	static Texture& Get(char^ path) {
		if (!bundles.has(path)) {
			return _Load(path, 0); // TODO: initialize w/ proper stat
		}

		let stat = io.stat_res(path);
		if (stat is Ok && stat as Ok.st_mtime != bundles.get(path).last_stat_mtime) {
			return _Load(path, stat as Ok.st_mtime);
		}

		return bundles.get(path).texture;
	}
}


struct TextureCache {
	static StrMap<Texture> textures = .();
	static Texture& Get(char^ path) {
		if (!io.file_exists(path)) {
			println(t"[WARNING]: Texture.Get: requested path '{path}' was not found!!! [... returning pixel texture]");
			return pixel; // NOTE: FILE DNE (log?)
		}
		if (!textures.has(path)) {
			textures.put(path, rl.LoadTexture(path));
		}
		return textures.get(path);
	}
}
