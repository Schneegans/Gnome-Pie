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

// This class representing a layer of the center of a pie. Each theme may
// have plenty of them.

public class CenterLayer : GLib.Object {

    public enum RotationMode {AUTO, TO_MOUSE, TO_ACTIVE}
    
    public Image image {get; private set;}

    public string image_file;
    private int center_radius;
    
    public double active_scale {get; private set;}
    public double active_rotation_speed {get; private set;}
    public double active_alpha {get; private set;}
    public bool active_colorize {get; private set;}
    public RotationMode active_rotation_mode {get; private set;}
    
    public double inactive_scale {get; private set;}
    public double inactive_rotation_speed {get; private set;}
    public double inactive_alpha {get; private set;}
    public bool inactive_colorize {get; private set;}
    public RotationMode inactive_rotation_mode {get; private set;}
    
    public double rotation {get; set;}
        
    public CenterLayer(string image_file, int center_radius, double active_scale, double active_rotation_speed,   
                                    double active_alpha,   bool active_colorize,   RotationMode active_rotation_mode,
                                    double inactive_scale, double inactive_rotation_speed, 
                                    double inactive_alpha, bool inactive_colorize, RotationMode inactive_rotation_mode) {
        
        this.image_file = image_file;
        this.center_radius = center_radius;
        
        this.active_scale = active_scale;
        this.active_rotation_speed = active_rotation_speed;
        this.active_alpha = active_alpha;
        this.active_colorize = active_colorize;
        this.active_rotation_mode = active_rotation_mode;
        
        this.inactive_scale = inactive_scale;
        this.inactive_rotation_speed = inactive_rotation_speed;
        this.inactive_alpha = inactive_alpha;
        this.inactive_colorize = inactive_colorize;
        this.inactive_rotation_mode = inactive_rotation_mode;
        
        this.rotation = 0.0;
    }
    
    public void load_image() {
        this.image = new Image.from_file_at_size(image_file, 2*center_radius, 2*center_radius);
    }
}

}
