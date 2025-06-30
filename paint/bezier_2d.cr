import rl;
import std;

// namespace
struct Bezier {
	Vec2 p1;
	Vec2 p2;
	Vec2 p3;
	Vec2 p4;

	List<Vec2> points(int n) {
		List<Vec2> ps = List<Vec2>();

		float fn = n;
		for (int i = 0; i < n; i++) {
			float fi = i;
			float t = fi / (fn - 1);

			float w1 = (1.0 - t) * (1.0 - t) * (1.0 - t);
			float w2 = 3.0 * t * (1.0 - t) * (1.0 - t);
			float w3 = 3.0 * t * t * (1.0 - t);
			float w4 = t * t * t;

			ps.add(
				  p1.scale(w1)
				+ p2.scale(w2)
				+ p3.scale(w3)
				+ p4.scale(w4)
			);
		}

		return ps;
	}
}
