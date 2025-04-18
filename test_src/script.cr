import std;
import rl;
import script_interface;
import list;

import perlin; // used by `perlin_field` effect

import file_util;

import data;

int CANVAS_WIDTH = 1200;
int CANVAS_HEIGHT = 900;

// @fx_args
// struct PointSwarmArgs {
// 	List<float> fs;
// 	float dot_size;
// }

// @fx_fn
// void PointSwarm(FxArgs& args, using PointSwarmArgs& margs) {
// 	for (int i in 0..(fs.size/2)) {
// 		Vec2 p = v2(fs.get(i*2), fs.get(i*2 + 1));
// 		d.Circle(p, dot_size, Colors.Red);
//
// 		for (int j in 0..(fs.size/2)) {
// 			if (i != j) {
// 				Vec2 other_p = v2(fs.get(j*2), fs.get(j*2 + 1));
// 				d.Line(p, other_p, 3, Colors.Yellow);
// 			}
// 		}
// 	}
// }



Texture pixel = rl.LoadTextureFromImageDestructively(rl.GenImageColor(1, 1, Colors.White));

@fx_args
struct PathGradArgs {
	int path_radius = 5; // TODO: range bounds
	bool texture_mode = false;
}

Texture grass_texture = rl.LoadTexture("script_assets/path/grass.jpg");
Texture brick_texture = rl.LoadTexture("script_assets/path/brick.jpg");
RenderTexture render_target = RenderTexture(1200, 900);

@fx_fn
void PathGrad(FxArgs& args, using PathGradArgs& margs) {
	Shader& path_grad_shader = ShaderHotReload.Get("script_assets/path/path_grad.frag");
	Texture& path_img = TextureHotReload.Get("script_assets/path/p1.png");

	if (!path_grad_shader.IsValid()) { return; }
	// render_target.Begin();
	// d.ClearBackground(Colors.Red);
	path_grad_shader.Begin();
		path_grad_shader.SetInt("path_radius", std.mini(path_radius, 100));
		path_grad_shader.SetInt("texture_mode", texture_mode ? 1 | 0);
		path_grad_shader.SetTexture("grass_texture", grass_texture);
		path_grad_shader.SetTexture("brick_texture", brick_texture);
		d.TextureAtSizeVColor(path_img, {0,0}, {1200, 900}, Colors.White);
	path_grad_shader.End();
	// render_target.End();
	//
	// d.Texture(render_target.texture, {0, 0});
}

@fx_args
struct PointSwarmArgs {
	List<Vec2> points = .();
	float dot_size = 10;
}

@fx_fn
void PointSwarm(FxArgs& args, using PointSwarmArgs& margs) {
	for (int i in 0..points.size) {
		Vec2 p = points.get(i);
		d.Circle(p, dot_size, Colors.Red);

		for (int j in 0..points.size) {
			if (i != j) {
				Vec2 other_p = points.get(j);
				d.Line(p, other_p, 3, Colors.Yellow);
			}
		}
	}
}

@fx_args
struct StringWheelArgs {
	List<char^> strs = .(); // list of string

	char^ what = f"nope"; // NOTE: string constants dangerous over re-compile!

	float font_size = 32;
	float rot = 30;

	Color c = Colors.Orange;
	int i = 7;

	List<int> ints = .();
	List<Vec2> Vec2s = .();
	List<float> floats = .();
	List<Color> colors = .();
}

@fx_fn
void StringWheel(using FxArgs& args, using StringWheelArgs& margs) {
	Vec2 screen_center = v2(CANVAS_WIDTH, CANVAS_HEIGHT).scale(0.5);
	for (int i in 0..strs.size) {
		float str_rot = rot + (360.0 / strs.size) * i;
		d.TextAngle(strs.get(i), screen_center, .MiddleLeft, str_rot, font_size, Colors.White);
	}
}

// @fx_fn
// void MyFx(FxArgs& args, using MyArgs& margs) {
// 	Bar(margs.bar1, 1, Colors.Red, margs.my_scalar);
// 	Bar(margs.bar2, 2, Colors.Orange, margs.my_scalar);
// 	Bar(margs.bar3, 3, Colors.Yellow, margs.my_scalar);
// }

@fx_args
struct BarChartArgs {
	List<float> data = {};
	// List<float> data2;
}

@fx_fn
void bar_chart(FxArgs& args, using BarChartArgs& margs) {
	if (margs.data.size == 0) {
		return;
	}

	int bar_count = margs.data.size;

	float max_bar_value = 0.0;
    float spacing = 5.0;
    float total_spacing = spacing * (bar_count - 1);
    float bar_width = (args.scale.x - total_spacing) / bar_count;
    float bar_height = args.scale.y;

	// Find max bar value
	for (int i in 0..bar_count) {
		float bar_value = margs.data.get(i);
		if (bar_value > max_bar_value) {
			max_bar_value = bar_value;
		}
	}

	// Draw bars
    for (int i in 0..bar_count) {

		float bar_x = spacing + args.pos.x as float + i as float * (bar_width + spacing);
		float bar_value = margs.data.get(i);
		float current_bar_height = bar_value / max_bar_value * bar_height;
        d.Rect(.(bar_x, args.pos.y + args.scale.y - current_bar_height), .(bar_width - 10, current_bar_height), args.color);
    }

    // Draw x-axis
    d.Line(v2(args.pos.x, args.pos.y + args.scale.y), .(args.pos.x + args.scale.x, args.pos.y + args.scale.y), 2, Colors.White);
    
	// Draw y-axis
    d.Line(args.pos, .(args.pos.x, args.pos.y + args.scale.y), 2, Colors.White);

	// Draw x-axis ticks and labels
	for (int i in 0..bar_count) {
		char^ bar_label = t"bar {i+1}";
		int text_width = c:MeasureText(bar_label, 20);
		
		// Draw tick and text label
		float tick_x = args.pos.x as float + i as float * (bar_width + spacing) + bar_width / 2;
		d.Line(.(tick_x, args.pos.y + args.scale.y), .(tick_x, args.pos.y + 10 + args.scale.y), 2, Colors.White);
		d.Text(bar_label, tick_x as int - (text_width / 2) as int, args.pos.y as int + 15 + args.scale.y as int, 20, Colors.White);
	}

	// Draw y-axis ticks and labels
	float curr_y_label = 0.0;
	for (int i in 0..bar_count) {
		float curr_y_label = max_bar_value / bar_count * (i + 1);
		char^ curr_y_label_str = c:malloc(6);
		c:gcvt(curr_y_label, 3, curr_y_label_str);
		int text_width = c:MeasureText(curr_y_label_str, 20);
		defer c:free(curr_y_label_str);

		// Draw tick and text label

		int tick_y = args.pos.y as int + args.scale.y as int - (i + 1) * (bar_height as int / bar_count as int);
		d.Line(.(args.pos.x - 10, tick_y), .(args.pos.x, tick_y), 2, Colors.White);
		d.Text(curr_y_label_str, args.pos.x as int - text_width as int - 15, tick_y as int - 5, 20, Colors.White);
	}

	// Draw chart title
	char^ title = t"Bar Chart";
	int title_width = c:MeasureText(title, 30);
	d.Text(title, (args.pos.x + args.scale.x / 2 - title_width / 2) as int, (args.pos.y - 40) as int, 30, Colors.White);
}

@fx_fn
void pie_chart(FxArgs& args, using BarChartArgs& margs) {
	if (margs.data.size == 0) {
		return;
	}

	List<Color> default_colors = .();
	default_colors.add(Colors.Lightgray);
	default_colors.add(Colors.Gray);
	default_colors.add(Colors.DarkGray);
	default_colors.add(Colors.Yellow);
	default_colors.add(Colors.Gold);
	default_colors.add(Colors.Orange);
	default_colors.add(Colors.Pink);
	default_colors.add(Colors.Red);
	default_colors.add(Colors.Maroon);
	default_colors.add(Colors.Green);
	default_colors.add(Colors.Lime);
	default_colors.add(Colors.DarkGreen);
	default_colors.add(Colors.SkyBlue);
	default_colors.add(Colors.Blue);
	default_colors.add(Colors.DarkBlue);
	default_colors.add(Colors.Purple);
	default_colors.add(Colors.Violet);
	default_colors.add(Colors.DarkPurple);
	default_colors.add(Colors.Beige);
	default_colors.add(Colors.Brown);

	float total = 0.0;
	for (int i in 0..margs.data.size) {
		total = total + margs.data.get(i);
	}
	
	float angle = 0.0;
	Vec2 center = args.pos + args.scale.divide(2);
	float radius = args.scale.x / 2;
	
	for (int i in 0..margs.data.size) {
		float value = margs.data.get(i);
		float slice_angle = value / total * 360.0;
		float end_angle = angle + slice_angle;

		// Draw the slice
		DrawCustomTriangleFan(center, radius, angle, end_angle, default_colors.get(i % 20));

		// Draw the label
		float label_angle = angle + slice_angle / 2;
		Vec2 label_pos = center + Vec2{.x = c:cos(label_angle * c:DEG2RAD) * (radius + 20) - 10, .y = c:sin(label_angle * c:DEG2RAD) * (radius + 20)};
		char^ label = c:malloc(6);
		c:gcvt(value, 3, label);
		d.Text(label, label_pos.x as int, label_pos.y as int, 20, Colors.White);
		defer c:free(label);

		angle = end_angle;
	}

	// Draw legend
	Vec2 legend_pos = center + Vec2{.x = radius + 50, .y = -radius};
	for (int i in 0..margs.data.size) {
		Color color = default_colors.get(i % 20);
		Vec2 rect_pos = legend_pos + Vec2{.x = 0, .y = i * 30};
		d.Rect(rect_pos, .(20, 20), color);

		char^ legend_label = t"Label {i+1}";
		d.Text(legend_label, rect_pos.x as int + 30, rect_pos.y as int + 5, 20, Colors.White);
	}

	// Draw chart title
	char^ title = t"Pie Chart";
	int title_width = c:MeasureText(title, 30);
	d.Text(title, (args.pos.x + args.scale.x / 2 - title_width / 2) as int, (args.pos.y - 60) as int, 30, Colors.White);
}

// TODO: Make part of rl?
void DrawCustomTriangleFan(Vec2 center, float radius, float startAngle, float endAngle, Color color) {
	int segments = 100; // Number of segments to approximate the circle
	float angleStep = (endAngle - startAngle) / segments;

	List<Vec2> points = .();
	points.add(center);

	for (int i = 0; i <= segments; i++;) {
		float angle = startAngle + (i as float) * angleStep;
		points.add(Vec2{
			.x = center.x + radius * c:cos(angle * c:DEG2RAD),
			.y = center.y + radius * c:sin(angle * c:DEG2RAD)
		});
	}

	// Draw the triangle fan with anti-aliasing
	for (int i = 1; i < segments + 1; i++;) {
		// for (int j = 4; j > 0; j = j - 2;) {
		// 	d.Triangle(points.get(0), points.get(i + 1), points.get(i), ColorAlpha(color, 0.2 * (8 - j) / 8.0)); // Outer triangles for anti-aliasing
		// }
		d.Triangle(points.get(0), points.get(i + 1), points.get(i), color); // Main triangle
	}
}
//
// // // helper for `cool_effect` effect
// // List<Vec2> GenPoints(int pixels_per) {
// // 	pixels_per = std.maxi(1, pixels_per);
// // 	List<Vec2> points = .();
// //
// // 	for (int i in 0..=(CANVAS_WIDTH/pixels_per)) {
// // 		points.add(.(i*pixels_per, 0));
// // 		points.add(.(i*pixels_per, CANVAS_HEIGHT));
// // 	}
// // 	for (int i in 0..=(CANVAS_HEIGHT/pixels_per)) {
// // 		points.add(.(0, i*pixels_per));
// // 		points.add(.(CANVAS_WIDTH, i*pixels_per));
// // 	}
// //
// // 	return points;
// // }
// //
// // // EFFECTS --------
// // helper for `cool_effect` effect
// List<Vec2> GenPoints(int pixels_per) {
// 	pixels_per = std.maxi(1, pixels_per);
// 	List<Vec2> points = .();
//
// 	for (int i in 0..=(CANVAS_WIDTH/pixels_per)) {
// 		points.add(.(i*pixels_per, 0));
// 		points.add(.(i*pixels_per, CANVAS_HEIGHT));
// 	}
// 	for (int i in 0..=(CANVAS_HEIGHT/pixels_per)) {
// 		points.add(.(0, i*pixels_per));
// 		points.add(.(CANVAS_WIDTH, i*pixels_per));
// 	}
//
// 	return points;
// }
//
// // EFFECTS --------
// // @fx_args
// // struct CoolArgs {
// // 	float pixels_per;
// // }
// //
// // @fx_fn
// // void cool_effect(FxArgs& args, CoolArgs& margs) {
// // 	Vec2 center = args.pos + args.scale.divide(2);
// //
// // 	let points = GenPoints(margs.pixels_per as int);
// // 	defer points.delete();
// // 	for (let p in points) {
// // 		d.Line(p, center, 3, Colors.Orange);
// // 	}
// //
// // 	d.Circle(center, 11, Colors.Black);
// // 	d.Circle(center, 10, args.color);
// // }
// //
// // @fx_args
// // struct StringWheelArgs {
// // 	List<char^> strs = .(); // list of string
// //
// // 	char^ what = "nope";
// //
// // 	float font_size = 32;
// // 	float rot = 30;
// // }
// //
// // @fx_fn
// // void StringWheel(using FxArgs& args, using StringWheelArgs& margs) {
// // 	Vec2 screen_center = v2(CANVAS_WIDTH, CANVAS_HEIGHT).scale(0.5);
// // 	for (int i in 0..strs.size) {
// // 		float str_rot = rot + (360.0 / strs.size) * i;
// // 		d.TextAngle(strs.get(i), screen_center, .MiddleLeft, str_rot, font_size, Colors.White);
// // 	}
// // }
// //
// // // struct PointSwarmArgs {
// // // 	List<float> fs = {};
// // // }
// // //
// // // @fx_fn
// // // void PointSwarm(FxArgs& args, using PointSwarmArgs& margs) {
// // // 	for (int i in 0..(fs.size/2)) {
// // // 		Vec2 p = v2(fs.get(i*2), fs.get(i*2 + 1));
// // // 		d.Circle(p, dot_size, Colors.Green);
// // //
// // // 		for (int j in 0..(fs.size/2)) {
// // // 			if (i != j) {
// // // 				Vec2 other_p = v2(fs.get(j*2), fs.get(j*2 + 1));
// // // 				d.Line(p, other_p, 3, Colors.Yellow);
// // // 			}
// // // 		}
// // // 	}
// // // }
// // //
// // // // helper for `cool_effect` effect
// // // List<Vec2> GenPoints(int pixels_per) {
// // // 	pixels_per = std.maxi(1, pixels_per);
// // // 	List<Vec2> points = .();
// // //
// // // 	for (int i in 0..=(CANVAS_WIDTH/pixels_per)) {
// // // 		points.add(.(i*pixels_per, 0));
// // // 		points.add(.(i*pixels_per, CANVAS_HEIGHT));
// // // 	}
// // // 	for (int i in 0..=(CANVAS_HEIGHT/pixels_per)) {
// // // 		points.add(.(0, i*pixels_per));
// // // 		points.add(.(CANVAS_WIDTH, i*pixels_per));
// // // 	}
// // //
// // // 	return points;
// // // }
// // //
// // // // EFFECTS --------
// // // // @fx_args
// // // // struct CoolArgs {
// // // // 	float pixels_per;
// // // // }
// // // //
// // // // @fx_fn
// // // // void cool_effect(FxArgs& args, CoolArgs& margs) {
// // // // 	Vec2 center = args.pos + args.scale.divide(2);
// // // //
// // // // 	let points = GenPoints(margs.pixels_per as int);
// // // // 	defer points.delete();
// // // // 	for (let p in points) {
// // // // 		d.Line(p, center, 3, Colors.Orange);
// // // // 	}
// // // //
// // // // 	d.Circle(center, 11, Colors.Black);
// // // // 	d.Circle(center, 10, args.color);
// // // // }
// // // //
// // // // @fx_args
// // // // struct PerlinArgs {
// // // // 	float dot_size;
// // // // }
// // // //
// // // // @fx_fn
// // // // void perlin_field(FxArgs& args, PerlinArgs& margs) {
// // // // 	float factor = 0.1;
// // // // 	float pos_factor = 0.01;
// // // // 	int dot_size = std.maxi(margs.dot_size as int, 1);
// // // //
// // // // 	Vec2 stride = .(CANVAS_WIDTH / dot_size, CANVAS_HEIGHT / dot_size);
// // // //
// // // // 	for (int col in 0..dot_size) {
// // // // 		for (int row in 0..dot_size) {
// // // // 			float x = args.pos.x * pos_factor + factor * col;
// // // // 			float y = args.pos.y * pos_factor + factor * row;
// // // // 			float z = args.pos.x * pos_factor - args.pos.y * pos_factor / 2;
// // // //
// // // // 			float noise = stb.perlin.turbulence_noise3(x, y, z, 2, 0.5, 6);
// // // // 			d.Circle(stride * v2(col, row), noise * 2 + 1, ColorLerp(Colors.Red, args.color, noise));
// // // // 		}
// // // // 	}
// // // // }
// // // //
// // // //
// // // // @fx_fn
// // // // void MyFx2(FxArgs& args) {
// // // // 	// println(t"no margs, just args");
// // // // }
// // // //
// // // // @fx_args
// // // // struct MyArgs {
// // // // 	float bar1;
// // // // 	float bar2;
// // // // 	float bar3;
// // // //
// // // // 	Vec2 my_scalar;
// // // // }
// // // //
// // // // void Bar(float h, int col, Color color, Vec2 scalar) {
// // // // 	Vec2 p = v2(col as float * (150.0 + scalar.x), 800.0 - h);
// // // // 	Vec2 dims = v2(140, h);
// // // // 	d.Rect(p, dims * (scalar.divide(300) + v2(1, 1)), color);
// // // // }
// // // //
// // // // @fx_fn
// // // // void MyFx(FxArgs& args, using MyArgs& margs) {
// // // // 	Bar(margs.bar1, 1, Colors.Red, margs.my_scalar);
// // // // 	Bar(margs.bar2, 2, Colors.Orange, margs.my_scalar);
// // // // 	Bar(margs.bar3, 3, Colors.Yellow, margs.my_scalar);
// // // // }
// // // //
// // // // @fx_args
// // // // struct BarChartArgs {
// // // // 	List<float> data;
// // // // }
// // // //
// // // // @fx_fn
// // // // void bar_chart(FxArgs& args, using BarChartArgs& margs) {
// // // // 	int bar_count = margs.data.size;
// // // //
// // // // 	float max_bar_value = 0.0;
// // // //     float spacing = 5.0;
// // // //     float total_spacing = spacing * (bar_count - 1);
// // // //     float bar_width = (args.scale.x - total_spacing) / bar_count;
// // // //     float bar_height = args.scale.y;
// // // //
// // // // 	// Find max bar value
// // // // 	for (int i in 0..bar_count) {
// // // // 		float bar_value = margs.data.get(i);
// // // // 		if (bar_value > max_bar_value) {
// // // // 			max_bar_value = bar_value;
// // // // 		}
// // // // 	}
// // // //
// // // // 	// Draw bars
// // // //     for (int i in 0..bar_count) {
// // // //
// // // // 		float bar_x = spacing + args.pos.x as float + i as float * (bar_width + spacing);
// // // // 		float bar_value = margs.data.get(i);
// // // // 		float current_bar_height = bar_value / max_bar_value * bar_height;
// // // //         d.Rect(.(bar_x, args.pos.y + args.scale.y - current_bar_height), .(bar_width - 10, current_bar_height), args.color);
// // // //     }
// // // //
// // // //     // Draw x-axis
// // // //     d.Line(v2(args.pos.x, args.pos.y + args.scale.y), .(args.pos.x + args.scale.x, args.pos.y + args.scale.y), 2, Colors.White);
// // // //     
// // // // 	// Draw y-axis
// // // //     d.Line(args.pos, .(args.pos.x, args.pos.y + args.scale.y), 2, Colors.White);
// // // //
// // // // 	// Draw x-axis ticks and labels
// // // // 	for (int i in 0..bar_count) {
// // // // 		char^ bar_label = t"bar {i+1}";
// // // // 		int text_width = c:MeasureText(bar_label, 20);
// // // // 		
// // // // 		// Draw tick and text label
// // // // 		float tick_x = args.pos.x as float + i as float * (bar_width + spacing) + bar_width / 2;
// // // // 		d.Line(.(tick_x, args.pos.y + args.scale.y), .(tick_x, args.pos.y + 10 + args.scale.y), 2, Colors.White);
// // // // 		d.Text(bar_label, tick_x as int - (text_width / 2) as int, args.pos.y as int + 15 + args.scale.y as int, 20, Colors.White);
// // // // 	}
// // // //
// // // // 	// Draw y-axis ticks and labels
// // // // 	float curr_y_label = 0.0;
// // // // 	for (int i in 0..bar_count) {
// // // // 		float curr_y_label = max_bar_value / bar_count * (i + 1);
// // // // 		char^ curr_y_label_str = c:malloc(6);
// // // // 		c:gcvt(curr_y_label, 3, curr_y_label_str);
// // // // 		int text_width = c:MeasureText(curr_y_label_str, 20);
// // // // 		defer c:free(curr_y_label_str);
// // // //
// // // // 		// Draw tick and text label
// // // //
// // // // 		int tick_y = args.pos.y as int + args.scale.y as int - (i + 1) * (bar_height as int / bar_count as int);
// // // // 		d.Line(.(args.pos.x - 10, tick_y), .(args.pos.x, tick_y), 2, Colors.White);
// // // // 		d.Text(curr_y_label_str, args.pos.x as int - text_width as int - 15, tick_y as int - 5, 20, Colors.White);
// // // // 	}
// // // // }

@fx_fn
void scatterplot(FxArgs& args, using BarChartArgs& margs) {
	if (margs.data.size == 0) {
		return;
	}
	
	int num_ticks = 10; // Make modifiable
	float max_x = 0.0;
	float max_y = 0.0;
	int data_count = margs.data.size / 2;
	if (data_count < 1) {
		return;
	}
	for (int i in 0..data_count) {
		float x = margs.data.get(i * 2);
		float y = margs.data.get(i * 2 + 1);
		if (x > max_x) {
			max_x = x;
		}
		if (y > max_y) {
			max_y = y;
		}
	}

	for (int i in 0..data_count) {
		float x = margs.data.get(i * 2);
		float y = margs.data.get(i * 2 + 1);
		Vec2 p = v2(x / max_x * args.scale.x, y / max_y * args.scale.y);
		d.Circle(args.pos + p, 5, args.color);
	}

	// Draw x-axis
	d.Line(args.pos + v2(0, args.scale.y), args.pos + v2(args.scale.x, args.scale.y), 2, Colors.White);

	// Draw y-axis
	d.Line(args.pos, .(args.pos.x, args.pos.y + args.scale.y), 2, Colors.White);

	// Draw x-axis ticks and labels
	for (int i in 0..num_ticks) {
		float tick_value = max_x / num_ticks * i;
		char^ tick_label = c:malloc(6);
		c:gcvt(tick_value, 3, tick_label);
		int text_width = c:MeasureText(tick_label, 20);
		defer c:free(tick_label);

		float tick_x = args.pos.x + (i as float) * (args.scale.x / num_ticks);
		d.Line(.(tick_x, args.pos.y + args.scale.y), .(tick_x, args.pos.y + args.scale.y + 10), 2, Colors.White);
		d.Text(tick_label, (tick_x - text_width / 2) as int, (args.pos.y + args.scale.y) as int + 15, 20, Colors.White);
	}

	// Draw y-axis ticks and labels
	for (int i in 0..num_ticks) {
		float tick_value = max_y / num_ticks * i;
		char^ tick_label = c:malloc(6);
		c:gcvt(tick_value, 3, tick_label);
		int text_width = c:MeasureText(tick_label, 20);
		defer c:free(tick_label);

		float tick_y = args.pos.y + args.scale.y - (i as float) * (args.scale.y / num_ticks);
		d.Line(.(args.pos.x - 10, tick_y), .(args.pos.x, tick_y), 2, Colors.White);
		d.Text(tick_label, (args.pos.x as int) - (text_width as int) - 15, (tick_y as int) - 10, 20, Colors.White);
	}
	// Draw chart title
	char^ title = t"Scatter Plot";
	int title_width = c:MeasureText(title, 30);
	d.Text(title, (args.pos.x + args.scale.x / 2 - title_width / 2) as int, (args.pos.y - 40) as int, 30, Colors.White);

	// Draw x-axis label
	char^ x_axis_label = t"X-Axis";
	int x_axis_label_width = c:MeasureText(x_axis_label, 20);
	d.Text(x_axis_label, (args.pos.x + args.scale.x / 2 - x_axis_label_width / 2) as int, (args.pos.y + args.scale.y + 40) as int, 20, Colors.White);

	// Draw y-axis label
	char^ y_axis_label = t"Y-Axis";
	int y_axis_label_width = c:MeasureText(y_axis_label, 20);
	d.Text(y_axis_label, (args.pos.x - y_axis_label_width - 50) as int, (args.pos.y + args.scale.y / 2 - 10) as int, 20, Colors.White);
}

@fx_fn
void line_graph(FxArgs& args, using BarChartArgs& margs) {
	int data_count = margs.data.size;
	if (data_count < 2) {
		return;
	}

	float max_value = 0.0;
	for (int i in 0..data_count) {
		float value = margs.data.get(i);
		if (value > max_value) {
			max_value = value;
		}
	}

	float padding_top = 20.0; // Add padding at the top
	float padding_bottom = 20.0; // Add padding at the bottom
	float padding_left = 20.0; // Add padding on the left
	float padding_right = 20.0; // Add padding on the right

	int half_data_count = data_count / 2;

	// Draw first half of the data in the original color
	Vec2 prev_point = .(args.pos.x + padding_left, args.pos.y + args.scale.y - padding_bottom - (margs.data.get(0) / max_value * (args.scale.y - padding_top - padding_bottom)));
	for (int i in 1..half_data_count) {
		float value = margs.data.get(i);
		Vec2 curr_point = .(args.pos.x + padding_left + (i as float / (half_data_count - 1) as float) * (args.scale.x - padding_left - padding_right), args.pos.y + args.scale.y - padding_bottom - (value / max_value * (args.scale.y - padding_top - padding_bottom)));

		// Draw antialiased line
		for (int j = 4; j > 0; j = j - 2;) {
			d.Line(prev_point, curr_point, j * 2, ColorAlpha(args.color, 0.2 * (8 - j) / 8.0)); // Outer lines for antialiasing
		}
		d.Line(prev_point, curr_point, 2, ColorAlpha(args.color, 0.5)); // Main line

		prev_point = curr_point;
	}

	// Draw second half of the data in blue using the same x values as the first half
	prev_point = .(args.pos.x + padding_left, args.pos.y + args.scale.y - padding_bottom - (margs.data.get(half_data_count) / max_value * (args.scale.y - padding_top - padding_bottom)));
	for (int i in 1..half_data_count) {
		float value = margs.data.get(half_data_count + i);
		Vec2 curr_point = .(args.pos.x + padding_left + (i as float / (half_data_count - 1) as float) * (args.scale.x - padding_left - padding_right), args.pos.y + args.scale.y - padding_bottom - (value / max_value * (args.scale.y - padding_top - padding_bottom)));

		// Draw antialiased line
		for (int j = 4; j > 0; j = j - 2;) {
			d.Line(prev_point, curr_point, j * 2, ColorAlpha(Colors.Blue, 0.2 * (8 - j) / 8.0)); // Outer lines for antialiasing
		}
		d.Line(prev_point, curr_point, 2, ColorAlpha(Colors.Blue, 0.5)); // Main line

		prev_point = curr_point;
	}

	// Draw circles for first half
	for (int i in 0..half_data_count) {
		float value = margs.data.get(i);
		Vec2 curr_point = .(args.pos.x + padding_left + (i as float / (half_data_count - 1) as float) * (args.scale.x - padding_left - padding_right), args.pos.y + args.scale.y - padding_bottom - (value / max_value * (args.scale.y - padding_top - padding_bottom)));
		d.Circle(curr_point, 5, args.color);
	}

	// Draw circles for second half
	for (int i in 0..half_data_count) {
		float value = margs.data.get(half_data_count + i);
		Vec2 curr_point = .(args.pos.x + padding_left + (i as float / (half_data_count - 1) as float) * (args.scale.x - padding_left - padding_right), args.pos.y + args.scale.y - padding_bottom - (value / max_value * (args.scale.y - padding_top - padding_bottom)));
		d.Circle(curr_point, 5, Colors.Blue);
	}

	// Draw x-axis
	d.Line(v2(args.pos.x, args.pos.y + args.scale.y), .(args.pos.x + args.scale.x, args.pos.y + args.scale.y), 2, Colors.White);

	// Draw y-axis
	d.Line(.(args.pos.x, args.pos.y), .(args.pos.x, args.pos.y + args.scale.y), 2, Colors.White);

	// Draw x-axis ticks and labels
	int num_ticks = 9;
	for (int i in 0..(num_ticks + 1)) {
		float tick_value = (half_data_count - 1) as float / num_ticks * i;
		char^ tick_label = c:malloc(6);
		c:gcvt(tick_value, 3, tick_label);
		int text_width = c:MeasureText(tick_label, 20);
		defer c:free(tick_label);

		float tick_x = args.pos.x + padding_left + (i as float) * ((args.scale.x - padding_left - padding_right) / num_ticks);
		d.Line(.(tick_x, args.pos.y + args.scale.y), .(tick_x, args.pos.y + args.scale.y + 10), 2, Colors.White);
		d.Text(tick_label, (tick_x - text_width / 2) as int, (args.pos.y + args.scale.y) as int + 15, 20, Colors.White);
	}

	// Draw y-axis ticks and labels
	num_ticks = 10;
	for (int i in 0..(num_ticks + 1)) {
		float tick_value = max_value / num_ticks * i;
		char^ tick_label = c:malloc(6);
		c:gcvt(tick_value, 3, tick_label);
		int text_width = c:MeasureText(tick_label, 20);
		defer c:free(tick_label);

		float tick_y = args.pos.y + args.scale.y - padding_bottom - (i as float) * ((args.scale.y - padding_top - padding_bottom) / num_ticks);
		d.Line(.(args.pos.x - 10, tick_y), .(args.pos.x, tick_y), 2, Colors.White);
		d.Text(tick_label, (args.pos.x as int) - (text_width as int) - 15, (tick_y as int) - 10, 20, Colors.White);
	}

	// Draw chart title
	char^ title = t"Line Graph";
	int title_width = c:MeasureText(title, 30);
	d.Text(title, (args.pos.x + args.scale.x / 2 - title_width / 2) as int, (args.pos.y - 40) as int, 30, Colors.White);

	// Draw x-axis label
	char^ x_axis_label = t"X-Axis";
	int x_axis_label_width = c:MeasureText(x_axis_label, 20);
	d.Text(x_axis_label, (args.pos.x + args.scale.x / 2 - x_axis_label_width / 2) as int, (args.pos.y + args.scale.y + 40) as int, 20, Colors.White);

	// Draw y-axis label
	char^ y_axis_label = t"Y-Axis";
	int y_axis_label_width = c:MeasureText(y_axis_label, 20);
	d.Text(y_axis_label, (args.pos.x - y_axis_label_width - 50) as int, (args.pos.y + args.scale.y / 2 - 10) as int, 20, Colors.White);
}

Color ColorAlpha(Color color, float alpha) {
	color.a = (alpha * 255.0) as int;
	return color;
}
