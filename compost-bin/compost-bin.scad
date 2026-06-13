// Compost Bin using BOSL2
// Requirements:
// - Inner basket: circular bottom, 150mm diameter, 200mm high, 200mm circumference at top, 2mm thick
// - Outer basket: fits inner basket with 1mm gap, hexagonal cutouts except top 20mm, 2mm thick
// - Inner lid: fits inner basket, holds 175mm filter, hex cutouts above filter, 25mm high, 37.5mm across hex handle
// - Outer lid: fits over inner lid, hex cutouts matching inner lid

include <bosl2/std.scad>
//use <bosl2/hex.scad>

/** Core parameters **/
od_bot = 150;
od_top = 200;
h = 200;
wall = 2;

/** Outer parameters **/
gap = 1;
solid_top = 40;
/** Hex parameters **/
hex_r = 3.71;      // hex radius (flat-to-flat / 2)
spacing = 1;       // gap between hexes
/** Lid parameters **/
lid_h = 25;
filter_d = 175;
filter_h = 10;
grip_h = 25;
grip_d = 37.5;


/** Calculated: Honeycomb pitch **/
R = hex_r * 2 / sqrt(3);   // point-to-point radius
pitch_x = 2*R + 4;   // horizontal spacing for upright hexes
//pitch_y = 1.5*hex_r + spacing;  // vertical spacing
pitch_y = 1.5*hex_r-1.75;  // vertical spacing
// Convert linear pitch to angular pitch
pitch_angle = pitch_x / (od_bot/2 + wall/2) * 180 / PI;
// Filter
filter_r = filter_d/2;


// Inner basket
module inner_basket() {
    difference() {
        cylinder(h=h,r1=od_bot/2, r2=od_top/2, $fn=96);
        translate([0,0,wall])
            cylinder(h=h-wall, r1=od_bot/2-wall, r2=od_top/2-wall, $fn=96);
    }
}

// Make a single hexagon
module hexagon(hex_radius) {
    rotate([90,0,90])   // stand it up vertically
        linear_extrude(height = 55)
            circle(r = hex_radius, $fn = 6);
}

// Place hexes directly on cylinder surface
module hex_pattern() {
    orig_hex_r = hex_r;
    for (row = [0 : pitch_y : h-solid_top]) {
        pct_up = row/(h-solid_top);
        new_hex_r = hex_r+(pct_up*1);
        for (col = [0 : pitch_angle : 354]) {
            ang = col + (row/pitch_y % 2) * (pitch_angle/2);
            x = (od_bot/2 + wall/2) * cos(ang);
            y = (od_bot/2 + wall/2) * sin(ang);
            translate([x, y, row+(pct_up*pct_up*20)])
                rotate([0,0,ang])
                    hexagon(new_hex_r);
        }
    }
}
/*
module hex_pattern() {
    for (row = [0 : pitch_y : h-solid_top]) {

        // Compute local radius at this height
        r_row = (od_bot/2 + wall/2) +
                (row / (h - solid_top)) * ((od_top/2 + wall/2) - (od_bot/2 + wall/2));

        // Convert linear pitch to angular pitch for this radius
        pitch_angle_row = pitch_x / r_row * 180 / PI;

        for (col = [0 : pitch_angle_row : 360]) {

            ang = col + (row/pitch_y % 2) * (pitch_angle_row/2);

            x = r_row * cos(ang);
            y = r_row * sin(ang);

            translate([x, y, row])
                rotate([0,0,ang])
                    hexagon();
        }
    }
}
*/

// Outer basket
module outer_basket() {
    od_bot = od_bot+wall*2+gap*2;
    od_top = od_top+wall*2+gap*2;
    difference() {
        cylinder(h=h+wall, r1=od_bot/2, r2=od_top/2, $fn=96);
        translate([0,0,wall])
            cylinder(h=h, r1=od_bot/2-wall, r2=od_top/2-wall, $fn=96);
        // Hex cutouts
        difference() {
            hex_pattern();
            cylinder(wall,d=od_bot+10);
        }
    }
}

// Inner lid
module inner_lid() {
    lid_r = od_top / 2;                          // 100mm - rests on basket lip
    insert_r = od_top / 2 - wall;                // 98mm - fits inside basket
    filter_cyl_r = (filter_d - filter_h) / 2;    // 82.5mm - straight cylinder portion
    torus_minor_r = filter_h / 2;                // 5mm - rounded edge radius

    // Straight cylinder section from lip before dome curves
    straight_h = filter_h / 2;                   // 5mm straight wall above lip

    // Dome sphere: cap from lid_r at z=wall+straight_h up to z=wall+straight_h+lid_h
    dome_base_z = wall + straight_h;
    R_sphere = (lid_r * lid_r + lid_h * lid_h) / (2 * lid_h);
    sphere_z = dome_base_z + lid_h - R_sphere;

    // Hex grid spacing (flat-topped hexes, rotate 30)
    hex_ftf = sqrt(3) * hex_r;                   // flat-to-flat width
    dx = hex_ftf + wall;                         // horizontal center-to-center
    dy = 1.5 * hex_r + wall;                    // vertical center-to-center

    // Max center distance for vent hex to be entirely within filter_cyl_r
    vent_max_dist = filter_cyl_r - hex_r;

    // Grid search range
    N = ceil(filter_cyl_r / min(dx, dy)) + 1;

    difference() {
        union() {
            // 1. Insert ring - goes wall deep into basket
            cylinder(h = wall, r = insert_r, $fn = 96);

            // 2. Straight cylinder from lip up straight_h before dome curves
            translate([0, 0, wall])
                cylinder(h = straight_h, r = lid_r, $fn = 96);

            // 3. Dome - sphere cap from dome_base_z curving up to dome_base_z+lid_h
            intersection() {
                translate([0, 0, sphere_z])
                    sphere(r = R_sphere, $fn = 96);
                translate([0, 0, dome_base_z])
                    cylinder(h = lid_h + 1, r = lid_r + 1, $fn = 96);
            }

            // 4. Grip - honeycomb walls rising grip_h above dome
            difference() {
                // Solid boundary: hull of 3-ring hex positions
                linear_extrude(height = dome_base_z + lid_h + grip_h)
                    hull()
                        for (q = [-2:2])
                            for (r = [-2:2])
                                if (max(abs(q), abs(r), abs(-q - r)) <= 2)
                                    translate([dx * (q + r * 0.5), dy * r])
                                        rotate(30)
                                            circle(r = hex_r + wall / 2, $fn = 6);

                // Remove hex cell interiors (creates honeycomb walls)
                for (q = [-2:2])
                    for (r = [-2:2])
                        if (max(abs(q), abs(r), abs(-q - r)) <= 2)
                            translate([dx * (q + r * 0.5), dy * r, 0])
                                linear_extrude(height = dome_base_z + lid_h + grip_h)
                                    rotate(30)
                                        circle(r = hex_r, $fn = 6);

                // Remove everything below dome surface
                translate([0, 0, sphere_z])
                    sphere(r = R_sphere, $fn = 96);
            }
        }

        // 5. Filter pocket + gas access from below
        //    Cylinder: straight walls from bottom through to filter_h into dome
        cylinder(h = wall + filter_h, r = filter_cyl_r, $fn = 96);
        //    Torus: rounded bulge matching filter barrel shape
        translate([0, 0, wall + torus_minor_r])
            rotate_extrude($fn = 96)
                translate([filter_cyl_r, 0])
                    circle(r = torus_minor_r, $fn = 48);

        // 6. Hollow above filter - empty within filter_cyl_r, wall thickness at dome top
        intersection() {
            translate([0, 0, sphere_z])
                sphere(r = R_sphere - wall, $fn = 96);
            translate([0, 0, wall + filter_h])
                cylinder(h = lid_h, r = filter_cyl_r, $fn = 96);
        }

        // 7. Hex vent cutouts - through dome, outside grip, within filter area
        for (q = [-N:N])
            for (r = [-N:N]) {
                cx = dx * (q + r * 0.5);
                cy = dy * r;
                dist = sqrt(cx * cx + cy * cy);
                ring = max(abs(q), abs(r), abs(-q - r));

                if (dist <= vent_max_dist && ring > 2)
                    translate([cx, cy, 0])
                        linear_extrude(height = dome_base_z + lid_h + 1)
                            rotate(30)
                                circle(r = hex_r, $fn = 6);
            }
    }
}

/*
// Outer lid
module outer_lid() {
    od = 200/PI+2+1*2;
    wall = 2;
    lid_h = 25;
    handle_across = 37.5;
    difference() {
        cylinder(h=lid_h, d=od, $fn=96);
        translate([0,0,wall])
            cylinder(h=lid_h-wall, d=od-wall*2, $fn=96);
        // Hex cutouts matching inner lid
        translate([0,0,wall])
            hex_shell(
                h=lid_h-wall,
                d=od-wall*2,
                wall=wall,
                cell_d=8,
                solid_top=0,
                solid_bottom=0
            );
        // Cutout for handle
        translate([0,0,lid_h-wall])
            hex_prism(h=lid_h, across=handle_across+2);
    }
}
*/
// Assembly
module compost_bin() {
    inner_basket();
    translate([0,0,-1*wall-.1]) outer_basket();
    translate([0,0,200]) inner_lid();
    //translate([0,0,225]) outer_lid();
}

compost_bin();
