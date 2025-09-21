import std;
import thread;
import warn;

struct LoaderResult_Gif {
	char^ path_done;
}

struct LoaderResult_Failure {
	ProgramWarningKind kind;
	char^ msg; // :leak-ed...
}

choice LoaderResultChoice {
	LoaderResult_Gif,
	LoaderResult_Failure,
	;
}

struct LoaderResult {
	int id;
	LoaderResultChoice payload;

	void Submit() {
		loader_result_queue_mutex.lock();
		{
			loader_result_queue.add(this);
		}
		loader_result_queue_mutex.unlock();
	}

	static int ProcureID() {
		loader_result_id_counter_mutex.lock();
		defer loader_result_id_counter_mutex.unlock();
		return loader_result_id_counter++;
	}

	// :leak from msg if malloced
	static void FailWith(int id, char^ msg) {
		LoaderResult{
			:id,
			.payload = LoaderResult_Failure{
				.kind = .LOADER_FAILURE, :msg
			},
		}.Submit();
	}
}


// user_data: char^ path
// NOTE: user_data (path) not freed since passed back to system
struct LoadGifParams {
	char^ file_path;
	int id;
}
void LoadGif(void^ user_data) {
	LoadGifParams^ params = user_data;
	
	Path output_dir = Env.edit_global_dir/f"temp_projects/{params#id}"; // :leak
	io.mkdir_if_nonexistent(output_dir);

	Path output_file_pattern = output_dir/"%04d.png"; // :leak
	char^ cmd = f"ffmpeg -i '{params#file_path}' '{output_file_pattern.str}'"; // Q: how many digits should we use? :thinking:
	defer free(cmd);

	int exit_code = system(cmd);
	if (exit_code != 0) {
		 return LoaderResult.FailWith(params#id, "gif ffmpeg frame-decompose failed");
	}

	LoaderResult{
		.id = params#id,
		.payload = LoaderResult_Gif{
			.path_done = params#file_path, // unused rn... get rid?
		},
	}.Submit();
}

pthread_mutex_t loader_result_id_counter_mutex;
int loader_result_id_counter = 0; // TODO: need to serialize!

pthread_mutex_t loader_result_queue_mutex;
LoaderResult[] loader_result_queue = {};
