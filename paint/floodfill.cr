import std;
import rl;
import theming;

List<Point> make_cardinal_direction_points() {
	List<Point> l = List<Point>();
	l.add({ .x =  1, .y = 0 });
	l.add({ .x = -1, .y = 0 });
	l.add({ .x = 0, .y =  1 });
	l.add({ .x = 0, .y = -1 });
	return l;
}
List<Point> cardinal_direction_points = make_cardinal_direction_points();

Image FloodFill(Image guide, Point start, Color color) {
	start.y = guide.height - start.y - 1;

	Image fill_img = c:GenImageColor(guide.width, guide.height, transparent);
	// TODO: bitmap visited set?
	// TODO: set format rgba8

	if (color.a == 0) { // NOTE: alpha of fill is transparent, so there will be no difference (unless we implement transparent fills?)
		return fill_img; // doing this rn, to use fill_img as visited set (visited when non-zero alpha, basically!)
	}

	if (start.x < 0 || start.x >= guide.width || start.y < 0 || start.y >= guide.height) {
		return fill_img;
	}

	Color over = guide.get(start);
	
	List<Point> queue = List<Point>();
	defer queue.delete();

	queue.add(start);

	while (!queue.is_empty()) {
		Point p = queue.pop_back();
		fill_img.set(p, color);

		for (int i = 0; i != 4; i++) {
			Point np = p + cardinal_direction_points.get(i);

			if (np.x >= 0 && np.x < guide.width && np.y >= 0 && np.y < guide.height
				&& fill_img.get(np).a == 0
				&& guide.get(np).VisualEquals(over)
			) {
				queue.add(np);
			}
		}
	}
	
	c:ImageFlipVertical(^fill_img); // idk why, but it's upside down :)

	return fill_img;
}
