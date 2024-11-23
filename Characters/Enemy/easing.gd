class_name Easing
	
static var linear := Segment.linear(Vector3(0, 0, 0), Vector3(0, 1, 0))

static var in_sine := Segment.easing(0.12, 0, 0.39, 0)
static var out_sine := Segment.easing(0.61, 1, 0.88, 1)
static var in_out_sine := Segment.easing(0.37, 0, 0.63, 1)

static var in_quad := Segment.easing(0.11, 0, 0.5, 0)
static var out_quad := Segment.easing(0.5, 1, 0.89, 1)
static var in_out_quad := Segment.easing(0.45, 0, 0.55, 1)

static var in_cubic := Segment.easing(0.32, 0, 0.67, 0)
static var out_cubic := Segment.easing(0.33, 1, 0.68, 1)
static var in_out_cubic := Segment.easing(0.65, 0, 0.35, 1)

static var in_quart := Segment.easing(0.5, 0, 0.75, 0)
static var out_quart := Segment.easing(0.25, 1, 0.5, 1)
static var in_out_quart := Segment.easing(0.76, 0, 0.24, 1)

static var in_quint := Segment.easing(0.64, 0, 0.78, 0)
static var out_quint := Segment.easing(0.22, 1, 0.36, 1)
static var in_out_quint := Segment.easing(0.83, 0, 0.17, 1)

static var in_expo := Segment.easing(0.7, 0, 0.84, 0)
static var out_expo := Segment.easing(0.16, 1, 0.3, 1)
static var in_out_expo := Segment.easing(0.87, 0, 0.13, 1)

static var in_circ := Segment.easing(0.55, 0, 1, 0.45)
static var out_circ := Segment.easing(0, 0.55, 0.45, 1)
static var in_out_circ := Segment.easing(0.85, 0, 0.15, 1)

static var in_back := Segment.easing(0.36, 0, 0.66, -0.56)
static var out_back := Segment.easing(0.34, 1.56, 0.64, 1)
static var in_out_back := Segment.easing(0.68, -0.6, 0.32, 1.6)

static var falling := Segment.easing(0.33, 0, 0.66, 0.33)
static var rising := Segment.easing(0.33, 0.66, 0.66, 1)
