/*
 * Teardrop (Pear-Cut) Gemstone
 *
 * A faceted teardrop/pear-shaped gemstone with crown, girdle, and pavilion.
 * Built as a polyhedron with proper triangular facets.
 *
 * Default: 10mm wide, 5mm tall (table to base)
 * Teardrop length auto-calculated from width using length_ratio.
 */

/* [Dimensions] */

// Width across the widest point (mm)
gem_width = 10;

// Total height from table to base (mm)
gem_height = 5;

// Length-to-width ratio (typical pear cut: 1.4-1.7)
length_ratio = 1.5;

/* [Proportions] */

// Crown height as fraction of total height
crown_fraction = 0.50;

// Table/base size as fraction of girdle (0.5 = 50%)
table_ratio = 0.55;

// Number of facets around the girdle
facets = 16;

/* [Orientation] */

// Rotate for printing: 0=upright, 1=table down
orientation = 0; // [0:Base down, 1:Table down]

/* [Hidden] */

gem_length = gem_width * length_ratio;
crown_height = gem_height * crown_fraction;
pavilion_height = gem_height * (1 - crown_fraction);

/*
 * Generate teardrop outline as a list of [x,y] points.
 * Round end at -Y, pointed end at +Y.
 * Points go clockwise when viewed from above.
 */
function teardrop_pts(w, l, n) =
    let(
        r = w / 2,
        cy = -(l / 2 - r),
        tip_y = l / 2,
        d = tip_y - cy,
        tangent_angle = asin(r / d),
        arc_cw_span = 180 + 2 * tangent_angle,
        arc_n = max(3, floor(n * 0.7)),
        taper_n = max(1, floor((n - arc_n) / 2))
    )
    concat(
        [[0, tip_y]],
        [for (i = [1:taper_n])
            let(t = i / (taper_n + 1),
                rt = [r * cos(tangent_angle), cy + r * sin(tangent_angle)])
            [t * rt.x, (1 - t) * tip_y + t * rt.y]
        ],
        [[r * cos(tangent_angle), cy + r * sin(tangent_angle)]],
        [for (i = [1:arc_n - 1])
            let(angle = tangent_angle - i * arc_cw_span / arc_n)
            [r * cos(angle), cy + r * sin(angle)]
        ],
        [[r * cos(180 - tangent_angle), cy + r * sin(180 - tangent_angle)]],
        [for (i = [1:taper_n])
            let(t = i / (taper_n + 1),
                lt = [r * cos(180 - tangent_angle), cy + r * sin(180 - tangent_angle)])
            [(1 - t) * lt.x, (1 - t) * lt.y + t * tip_y]
        ]
    );

/*
 * Midpoints of adjacent vertex pairs, scaled about the origin.
 * This offsets the inner ring by half a facet step, creating
 * the zigzag pattern that gives a brilliant cut its facets.
 */
function midpoints_scaled(pts, s) =
    [for (i = [0:len(pts) - 1])
        let(j = (i + 1) % len(pts))
        [(pts[i].x + pts[j].x) / 2 * s,
         (pts[i].y + pts[j].y) / 2 * s]
    ];

/*
 * Faceted teardrop gemstone as a polyhedron.
 *
 * Three vertex rings:
 *   - Girdle (widest, z=0)
 *   - Table  (smaller, offset half-step, z=crown_height)
 *   - Base   (smaller, offset half-step, z=-pavilion_height)
 *
 * Crown and pavilion each have two rows of triangular facets:
 *   - "Bezel" facets: girdle edge → table/base vertex
 *   - "Star"  facets: table/base edge → girdle vertex
 */
module teardrop_gem() {
    girdle = teardrop_pts(gem_width, gem_length, facets);
    inner = midpoints_scaled(girdle, table_ratio);
    n = len(girdle);

    // Vertex list: girdle, table, base
    vertices = concat(
        [for (p = girdle) [p.x, p.y, 0]],               // 0..n-1
        [for (p = inner)  [p.x, p.y, crown_height]],     // n..2n-1
        [for (p = inner)  [p.x, p.y, -pavilion_height]]  // 2n..3n-1
    );

    faces = concat(
        // Table face (top, clockwise from above = outward normal up)
        [[for (i = [0:n - 1]) n + i]],

        // Crown bezel: girdle[i], table[i], girdle[i+1]
        [for (i = [0:n - 1]) [i, n + i, (i + 1) % n]],

        // Crown star: table[i], table[i+1], girdle[i+1]
        [for (i = [0:n - 1]) [n + i, n + (i + 1) % n, (i + 1) % n]],

        // Pavilion bezel: girdle[i], girdle[i+1], base[i]
        [for (i = [0:n - 1]) [i, (i + 1) % n, 2*n + i]],

        // Pavilion star: base[i], girdle[i+1], base[i+1]
        [for (i = [0:n - 1]) [2*n + i, (i + 1) % n, 2*n + (i + 1) % n]],

        // Base face (bottom, clockwise from below = outward normal down)
        [[for (i = [n - 1:-1:0]) 2*n + i]]
    );

    polyhedron(points = vertices, faces = faces, convexity = 2);
}

// Final placement based on orientation
if (orientation == 0) {
    translate([0, 0, pavilion_height])
        teardrop_gem();
} else {
    translate([0, 0, crown_height])
        mirror([0, 0, 1])
            teardrop_gem();
}
