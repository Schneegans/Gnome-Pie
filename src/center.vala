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
    
        public Center(Ring parent) {
            _parent = parent;
        }
        
        public void draw(Cairo.Context ctx, double angle, double distance) {

    	    var layers = Settings.theme.center_layers;
    	
		    foreach (var layer in layers) {
		        ctx.save();
		        
		        double max_scale          = layer.active_scale*_parent.activity + layer.inactive_scale*(1.0-_parent.activity);
                double max_rotation_speed = layer.active_rotation_speed*_parent.activity + layer.inactive_rotation_speed*(1.0-_parent.activity);
                double max_alpha          = layer.active_alpha*_parent.activity + layer.inactive_alpha*(1.0-_parent.activity);
                double colorize           = ((layer.active_colorize == true) ? _parent.activity : 0.0) + ((layer.inactive_colorize == true) ? 1.0 - _parent.activity : 0.0);
                bool   turn_to_mouse      = ((_parent.activity > 0.5) ? layer.active_turn_to_mouse : layer.inactive_turn_to_mouse);
		        
		        if (turn_to_mouse) {
		            double diff  = angle-layer.rotation;
	                if (fabs(diff) > 0.15 && fabs(diff) < PI) {
			            if ((diff > 0 && diff < PI) || diff < -PI) 
			                layer.rotation += max_rotation_speed/Settings.refresh_rate;
			            else
			                layer.rotation -= max_rotation_speed/Settings.refresh_rate;
		            } else {
		                layer.rotation = angle;
                    }
		        } else {
		            layer.rotation += max_rotation_speed/Settings.refresh_rate;
		        }
		        
		        layer.rotation = fmod(layer.rotation+2*PI, 2*PI);
		        

		        if (colorize > 0.0)
		            ctx.push_group();
		        
		        ctx.rotate(layer.rotation);
		        ctx.scale(max_scale, max_scale);
		        ctx.set_source_surface(layer.image, -0.5*layer.image.get_width(), -0.5*layer.image.get_height());
		        ctx.paint_with_alpha(_parent.fading*_parent.fading*max_alpha);
                
                if (colorize > 0.0) {
                    ctx.set_operator(Cairo.Operator.ATOP);
                    ctx.set_source_rgb(_parent.active_color.r, _parent.active_color.g, _parent.active_color.b);
                    ctx.paint_with_alpha(colorize);
                    
                    ctx.set_operator(Cairo.Operator.OVER);
                    ctx.pop_group_to_source();
		            ctx.paint();
		        }
                
                ctx.restore();
            }
        }
    }

}
