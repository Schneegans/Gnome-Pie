/* 
Copyright (c) 2011 by Simon Schneegans

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>. 
*/

namespace GnomePie {

    public class Settings : GLib.Object {
    
        // general settings
        public static double refresh_rate    {get; private set; default = 60.0;}
        public static double fade_in_time    {get; private set; default =  0.3;}
        public static double fade_out_time   {get; private set; default =  0.15;}
        
        // ring settings
        public static bool   open_centered   {get; private set; default = true;}
        public static double ring_diameter   {get; private set; default = 110.0;}
        
        // center settings
        public static double arrow_speed     {get; private set; default = 10.0;}
        public static double max_speed       {get; private set; default =  3.0;}
        public static double min_speed       {get; private set;}
        public static double rot_accel       {get; private set; default =  4.0;}
        public static double center_diameter {get; private set; default = 30.0;}
        public static Color  inactive_color  {get; private set;}

        // slice settings
        public static double max_icon_zoom   {get; private set; default = 1.2;}
	    public static double zoom_range      {get; private set; default = 0.2;}
	    public static double icon_zoom_speed {get; private set; default = 0.7;}
        
        public static void load() {
            _inactive_color = new Color.from_rgb(0.5f, 0.5f, 0.5f);
            _min_speed      = -0.5;
        }
    }
    
}
