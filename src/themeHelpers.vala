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

    public class SliceLayer : GLib.Object {
        
        public Cairo.ImageSurface image {get; set;}
        public bool colorize {get; private set; }
        public bool is_icon  {get; private set;}
        
        public SliceLayer(Cairo.ImageSurface image, bool colorize, bool is_icon) {
            _image = image;
            _colorize = colorize;
            _is_icon = is_icon;
        }
    
    }
    
    public class CenterLayer : GLib.Object {
        
        public Cairo.ImageSurface image {get; private set;}
        
        public double active_scale          {get; private set;}
        public double active_rotation_speed {get; private set;}
        public double active_alpha          {get; private set;}
        public bool   active_colorize       {get; private set;}
        public bool   active_turn_to_mouse  {get; private set;}
        
        public double inactive_scale          {get; private set;}
        public double inactive_rotation_speed {get; private set;}
        public double inactive_alpha          {get; private set;}
        public bool   inactive_colorize       {get; private set;}
        public bool   inactive_turn_to_mouse  {get; private set;}
        
        public double rotation {get; set;}
            
        public CenterLayer(Cairo.ImageSurface image, double active_scale,   double active_rotation_speed,   double active_alpha,   bool active_colorize,   bool active_turn_to_mouse,
                                                     double inactive_scale, double inactive_rotation_speed, double inactive_alpha, bool inactive_colorize, bool inactive_turn_to_mouse) {
            _image = image;
            
            _active_scale = active_scale;
            _active_rotation_speed = active_rotation_speed;
            _active_alpha = active_alpha;
            _active_colorize = active_colorize;
            _active_turn_to_mouse = active_turn_to_mouse;
            
            _inactive_scale = inactive_scale;
            _inactive_rotation_speed = inactive_rotation_speed;
            _inactive_alpha = inactive_alpha;
            _inactive_colorize = inactive_colorize;
            _inactive_turn_to_mouse = inactive_turn_to_mouse;
            
            _rotation = 0.0;
        }
    }
}
