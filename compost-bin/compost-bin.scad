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

// flat‑topped hex, radius = hex_r (center to vertex)
module lid_hexagon() {
    linear_extrude(height = 55)
        rotate(30)                    // flat‑topped
            circle(r = hex_r, $fn = 6);
}

module lid_hex_pattern() {

    hex_width  = sqrt(3) * hex_r;         // flat‑to‑flat
    hex_height = 2 * hex_r;               // point‑to‑point

    dx = hex_width + wall;            // horizontal spacing
    dy = 1.5 * hex_r + wall;              // vertical spacing

    max_x = filter_r + dx;
    max_y = filter_r + dy;

    row = 0;
    for (y = [-max_y : dy : max_y]) {

        // stagger every other row horizontally
        x_offset = (row % 2 == 1) ? dx/2 : 0;

        for (x = [-max_x : dx : max_x]) {

            cx = x + x_offset;
            cy = y;

            if (cx*cx + cy*cy <= filter_r*filter_r)
                translate([cx, cy, 0])
                    lid_hexagon();
        }

        row = row + 1;
    }
}


//lid_hex_pattern();

// Inner lid
module inner_lid() {
    outer_r = (od_top+(wall*2))/2;
    filter_access_r = filter_r-5;
    difference() {
        // Outer portion, bottom up
        union() {
            translate([0,0,0])    cylinder(h=wall, d=od_top, $fn=96);
            translate([0,0,wall]) cylinder(h=wall, r=outer_r, $fn=96);
            translate([0,0,wall*2]) intersection() {
                scale([1, 1, lid_h/100]) sphere(r = outer_r, $fn=96);
                translate([0,0,200]) cube([400,400,400], center=true);
            }
        }
        // Hole for filter access
        translate([0,0,0]) cylinder(h=wall, r=filter_access_r);
        // Filter
        translate([0,0,wall]) cylinder(h=filter_h, r=filter_r);
        // Space under dome
        translate([0,0,wall]) intersection() {
            scale([1,1, lid_h/100]) sphere(r = outer_r, $fn=96);
            translate([0,0,200+filter_h]) cube([400,400,400], center=true);
        }
        // Hex pattern
    }
/*    difference() {
        cylinder(h=wall,d=filter_d-(2*5));
    difference() {
        cylinder(h=lid_h, d=od, $fn=96);
        translate([0,0,wall])
            cylinder(h=lid_h-wall, d=od-wall*2, $fn=96);
        // Filter holder
        translate([0,0,wall])
            cylinder(h=2, d=filter_d, $fn=96);
        // Hex cutouts above filter
        translate([0,0,wall+2])
            hex_shell(
                h=lid_h-wall-2,
                d=od-wall*2,
                wall=wall,
                cell_d=8,
                solid_top=0,
                solid_bottom=0
            );
    }
    // Handle
    translate([0,0,lid_h])
        hex_prism(h=handle_h, across=handle_across);*/
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
    //translate([0,0,200]) inner_lid();
    //translate([0,0,225]) outer_lid();
}

compost_bin();
