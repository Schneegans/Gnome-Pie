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

using GLib.Math;

namespace GnomePie {

    public class Center {

	    private Ring _parent;
	
	    private double _arrow_rotation  = 0.0;
	    private double _center_activity = 0.0;
	    private double _center_rotation = 0.0;
    
        public Center(Ring parent) {
            _parent = parent;
        }
        
        public void draw(Cairo.Context ctx, double angle, double distance) {

		    if (distance > Settings.center_diameter) { 
		        if ((_center_activity += Settings.rot_accel/Settings.refresh_rate) > 1.0)
                    _center_activity = 1.0;
		    } else {
		        if ((_center_activity -= Settings.rot_accel/Settings.refresh_rate) < 0.0)
                    _center_activity = 0.0;
		    }
		    
		    ctx.save();
		    double diff  = angle-_arrow_rotation;
	        if (fabs(diff) > 0.15 && fabs(diff) < PI) {
			    if ((diff > 0 && diff < PI) || diff < -PI) 
			        _arrow_rotation += Settings.arrow_speed/Settings.refresh_rate;
			    else
			        _arrow_rotation -= Settings.arrow_speed/Settings.refresh_rate;
		    } else {
		        _arrow_rotation = angle;
            }	
		    _arrow_rotation = fmod(_arrow_rotation+2*PI, 2*PI);
		    
		    ctx.save();
		    ctx.rotate(_arrow_rotation);
		    ctx.set_source_surface(Theme.arrow, -75, -75);
		    ctx.paint_with_alpha(_center_activity);
		    ctx.restore();
		    
		    double center_speed = Settings.max_speed*_center_activity + Settings.min_speed*(1.0 - _center_activity);
		    _center_rotation += center_speed/Settings.refresh_rate;
		    _center_rotation = fmod(_center_rotation+2*PI, 2*PI);
		    
			ctx.rotate(_center_rotation);
		    ctx.set_source_surface(Theme.ring, -75, -75);
		    ctx.paint();
		    
		    float r = (float) (_parent.active_color.r*_center_activity + Settings.inactive_color.r*(1.0 - _center_activity));
		    float g = (float) (_parent.active_color.g*_center_activity + Settings.inactive_color.g*(1.0 - _center_activity));
		    float b = (float) (_parent.active_color.b*_center_activity + Settings.inactive_color.b*(1.0 - _center_activity));
		    
		    ctx.set_operator(Cairo.Operator.ATOP);
		    ctx.set_source_rgb(r, g, b);
            ctx.paint();
            
            ctx.restore();
        }
    }

}
