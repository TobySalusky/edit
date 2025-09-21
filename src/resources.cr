import std;

struct Resources {
	GifResource^ Gif(int id) -> gifs.get_ptr(id);
	// --------------------
	void LoadGif(int id) {
		Texture[] textures = {};

		// io.list_dir_files();
		// textures.zeroed_increase_size_to();

		gifs.insert(id, GifResource{
			:textures
		});
	}

	// --------------------
	Project& project;
	HashMap<int, GifResource> gifs;
}

struct GifResource {
	Texture[] textures;
}

// TODO: get last_mod_time -> do reloading!
