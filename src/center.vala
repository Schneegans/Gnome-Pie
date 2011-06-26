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

	    private Ring parent {private get; private set;}
	    private double activity {private get; private set; default = 0.0;}
    
        public Center(Ring parent) {
            _parent = parent;
        }
        
        public void draw(Cairo.Context ctx, double angle, double distance) {

    	    var layers = Settings.get.theme.center_layers;
    	    
    	    if (parent.has_active_slice) { 
	            if ((activity += 1.0/(Settings.get.theme.transition_time*Settings.get.refresh_rate)) > 1.0)
                    activity = 1.0;
	        } else {
	            if ((activity -= 1.0/(Settings.get.theme.transition_time*Settings.get.refresh_rate)) < 0.0)
                    activity = 0.0;
	        }
    	
		    foreach (var layer in layers) {
		    
		        ctx.save();

		        double max_scale          = layer.active_scale*activity + layer.inactive_scale*(1.0-activity);
                double max_rotation_speed = layer.active_rotation_speed*activity + layer.inactive_rotation_speed*(1.0-activity);
                double max_alpha          = layer.active_alpha*activity + layer.inactive_alpha*(1.0-activity);
                double colorize           = ((layer.active_colorize == true) ? activity : 0.0) + ((layer.inactive_colorize == true) ? 1.0 - activity : 0.0);
                bool   turn_to_mouse      = ((activity > 0.5) ? layer.active_turn_to_mouse : layer.inactive_turn_to_mouse);
		        
		        if (turn_to_mouse) {
		            double diff = angle-layer.rotation;
		            double step = max_rotation_speed/Settings.get.refresh_rate;
		            
	                if (fabs(diff) <= step || fabs(diff) >= 2.0*PI - step)
			            layer.rotation = angle;
		            else {
		                if ((diff > 0 && diff < PI) || diff < -PI) layer.rotation += step;
			            else            		                   layer.rotation -= step;
                    }
                    
		        } else layer.rotation += max_rotation_speed/Settings.get.refresh_rate;
		        
		        layer.rotation = fmod(layer.rotation+2*PI, 2*PI);
		        

		        if (colorize > 0.0) ctx.push_group();
		        
		        ctx.rotate(layer.rotation);
		        ctx.scale(max_scale, max_scale);
		        ctx.set_source_surface(layer.image, -0.5*layer.image.get_width()-1, -0.5*layer.image.get_height()-1);
		        ctx.paint_with_alpha(parent.fading*parent.fading*max_alpha);
                
                if (colorize > 0.0) {
                    ctx.set_operator(Cairo.Operator.ATOP);
                    ctx.set_source_rgb(parent.active_color.r, parent.active_color.g, parent.active_color.b);
                    ctx.paint_with_alpha(colorize);
                    
                    ctx.set_operator(Cairo.Operator.OVER);
                    ctx.pop_group_to_source();
		            ctx.paint();
		        }
                
                ctx.restore();
            }
            
             // draw caption
		    if (Settings.get.theme.caption && activity > 0.0) {
    		    ctx.save();
    		    
		        ctx.set_font_size(Settings.get.theme.font_size);
		        Cairo.TextExtents extents;
		        ctx.text_extents(parent.active_name, out extents);		    
		        ctx.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
		        ctx.move_to(-extents.width/2, Settings.get.theme.caption_position+Settings.get.theme.font_size*0.5); 
		        Color color = Settings.get.theme.caption_color;
                ctx.set_source_rgba(color.r, color.g, color.g, parent.fading*parent.fading*activity);
                ctx.show_text(parent.active_name);
                
		        ctx.restore();
		    }
        }
    }

}
