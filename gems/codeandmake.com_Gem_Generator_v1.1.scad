/*
 * Copyright 2022 Code and Make (codeandmake.com)
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * Gem Generator by Code and Make (https://codeandmake.com/)
 *
 * https://codeandmake.com/post/gem-generator
 *
 * Gem Generator v1.1 (29 January 2022)
 */

/* [General] */

// Length of each side
Side_Length = 12.5;

// Width point to point (narrow dimension)
Width = 10;

// Number of sides
Sides = 4; // [3:1:12]

// Computed: long diagonal from side length and width
Diameter = 2 * sqrt(pow(Side_Length, 2) - pow(Width / 2, 2));

// Scale factor to narrow the shape
_scale_x = Width / Diameter;

/* [Bottom] */

// Uncut height of bottom section
Bottom_Height = 5; // [1:1:100]

// Percentage to cut from bottom section
Bottom_Cutoff_Percent = 50; // [0:1:100]

/* [Middle] */

// Height of middle section
Middle_Height = 0; // [0:1:100]

/* [Top] */

// Uncut height of top section
Top_Height = 5; // [1:1:100]

// Percentage to cut from top section
Top_Cutoff_Percent = 0; // [0:1:100]

/* [Printing] */

// Rotate onto face for easier printing
Orientation = 0; // [0:Upright, 1:Bottom Side, 2:Side, 3:Top Side, 4:Upsidedown]

/* [Preview] */

// Show uncut ends in preview mode
Show_Uncut_Ends = 0; // [0:No, 1:Yes]

module GemGenerator() {
  radius = Diameter / 2;
  apothem = radius * cos(180 / Sides);

  if(Orientation == 0) {
    translate([0, 0, (Bottom_Height * ((100 - Bottom_Cutoff_Percent) / 100)) + Middle_Height]) {
      mirror([0, 0, 1]) {
        gem();
      }
    }
  } else if(Orientation == 1) {
    mirror([1, 0, 0]) {
      // rotate flat
      rotate([0, 180 - atan(Bottom_Height / apothem), 0]) {
        // shift
        translate([-apothem * ((Bottom_Cutoff_Percent) / 100), 0, -((Bottom_Height * ((100 - Bottom_Cutoff_Percent) / 100)) + Middle_Height)]) {
          // rotate onto flat side
          rotate([0, 0, 180 / Sides]) {
            gem();
          }
        }
      }
    }
  } else if(Orientation == 2) {
    mirror([1, 0, 0]) {
      // shift
      translate([Bottom_Height * ((Bottom_Cutoff_Percent) / 100), 0, apothem]) {
        // rotate flat
        rotate([0, 90, 0]) {
          // shift down
          translate([0, 0, -(Bottom_Height + Middle_Height)]) {
            // rotate onto flat side
            rotate([0, 0, 180 / Sides]) {
              gem();
            }
          }
        }
      }
    }
  } else if(Orientation == 3) {
    // rotate flat
    rotate([0, atan(Top_Height / apothem), 0]) {
      // shift
      translate([-apothem * ((Top_Cutoff_Percent) / 100), 0, Top_Height * ((100 - Top_Cutoff_Percent) / 100)]) {
        // rotate onto flat side
        rotate([0, 0, 180 / Sides]) {
          gem();
        }
      }
    }
  } else if(Orientation == 4) {
    translate([0, 0, Top_Height * ((100 - Top_Cutoff_Percent) / 100)]) {
      gem();
    }
  }

  module gem() {
    // bottom
    translate([0, 0, Middle_Height]) {
      if (Show_Uncut_Ends) {
        %translate([0, 0, Bottom_Height * ((100 - Bottom_Cutoff_Percent) / 100)]) {
          cylinder(d1=Diameter * ((Bottom_Cutoff_Percent) / 100), d2=0, h=Bottom_Height * ((Bottom_Cutoff_Percent) / 100), $fn=Sides);
        }
      }
      intersection() {
        cylinder(d1=Diameter, d2=0, h=Bottom_Height, $fn=Sides);
        cylinder(d=Diameter, h=Bottom_Height * ((100 - Bottom_Cutoff_Percent) / 100), $fn=Sides);
      }
    }

    // middle
    cylinder(d=Diameter, h=Middle_Height, $fn=Sides);

    // top
    rotate([0, 180, 0]) {
      mirror([1, 0, 0]) {
        if (Show_Uncut_Ends) {
          %translate([0, 0, Top_Height * ((100 - Top_Cutoff_Percent) / 100)]) {
            cylinder(d1=Diameter * ((Top_Cutoff_Percent) / 100), d2=0, h=Top_Height * ((Top_Cutoff_Percent) / 100), $fn=Sides);
          }
        }

        intersection() {
          cylinder(d1=Diameter, d2=0, h=Top_Height, $fn=Sides);
          cylinder(d=Diameter, h=Top_Height * ((100 - Top_Cutoff_Percent) / 100), $fn=Sides);
        }
      }
    }
  }
}

scale([_scale_x, 1, 1]) GemGenerator();

echo("\r\tThis design is completely free and shared under a permissive license.\r\tYour support is hugely appreciated: codeandmake.com/support\r");
