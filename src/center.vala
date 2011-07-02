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

	    private Pie                parent  {private get; private set;}
	    public double             activity {get; private set; default = 0.0;}

        public Center(Pie parent) {
            _parent = parent;
        }
        
        public void draw(Cairo.Context ctx, double angle, double distance) {

    	    var layers = Settings.global.theme.center_layers;
    	    
    	    if (parent.has_active_slice) { 
	            if ((activity += 1.0/(Settings.global.theme.transition_time*Settings.global.refresh_rate)) > 1.0)
                    activity = 1.0;
	        } else {
	            if ((activity -= 1.0/(Settings.global.theme.transition_time*Settings.global.refresh_rate)) < 0.0)
                    activity = 0.0;
	        }
    	
		    foreach (var layer in layers) {
		    
		        ctx.save();


                double active_speed       = (layer.active_rotation_mode == CenterLayer.RotationMode.AUTO) ? layer.active_rotation_speed : 0.0;
                double inactive_speed     = (layer.inactive_rotation_mode == CenterLayer.RotationMode.AUTO) ? layer.inactive_rotation_speed : 0.0;
		        double max_scale          = layer.active_scale*activity + layer.inactive_scale*(1.0-activity);
                double max_alpha          = layer.active_alpha*activity + layer.inactive_alpha*(1.0-activity);
                double colorize           = ((layer.active_colorize == true) ? activity : 0.0) + ((layer.inactive_colorize == true) ? 1.0 - activity : 0.0);
                double max_rotation_speed = active_speed*activity + inactive_speed*(1.0-activity);
                CenterLayer.RotationMode rotation_mode = ((activity > 0.5) ? layer.active_rotation_mode : layer.inactive_rotation_mode);

		        
		        if (rotation_mode == CenterLayer.RotationMode.TO_MOUSE) {
		            double diff = angle-layer.rotation;
		            max_rotation_speed = layer.active_rotation_speed*activity + layer.inactive_rotation_speed*(1.0-activity);
		            double smoothy = fabs(diff) < 0.9 ? fabs(diff) + 0.1 : 1.0; 
		            double step = max_rotation_speed/Settings.global.refresh_rate*smoothy;
		            
	                if (fabs(diff) <= step || fabs(diff) >= 2.0*PI - step)
			            layer.rotation = angle;
		            else {
		                if ((diff > 0 && diff < PI) || diff < -PI) layer.rotation += step;
			            else            		                   layer.rotation -= step;
                    }
                    
		        } else if (rotation_mode == CenterLayer.RotationMode.TO_ACTIVE) {
		            max_rotation_speed *= activity;
		            
		            double slice_angle = 2*PI/parent.slice_count();
		            double direction = (int)((angle+0.5*slice_angle) / (slice_angle))*slice_angle;
		            double diff = direction-layer.rotation;
		            double step = max_rotation_speed/Settings.global.refresh_rate;
		            
	                if (fabs(diff) <= step || fabs(diff) >= 2.0*PI - step)
			            layer.rotation = direction;
		            else {
		                if ((diff > 0 && diff < PI) || diff < -PI) layer.rotation += step;
			            else            		                   layer.rotation -= step;
                    }
		            
		        } else layer.rotation += max_rotation_speed/Settings.global.refresh_rate;
		        
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
                
                 // draw caption
		        if (Settings.global.theme.caption && parent.active_caption != null && activity > 0) {
        		    ctx.save();
        		    ctx.identity_matrix();
        		    int pos = (int)((fmax(2*Settings.global.theme.radius + 4*Settings.global.theme.slice_radius, 2*Settings.global.theme.center_radius))/2);
		            ctx.translate(pos, (int)Settings.global.theme.caption_position + pos); 
		            ctx.set_source_surface(parent.active_caption, (int)(-parent.active_caption.get_width()*0.5), (int)(-parent.active_caption.get_height()*0.5));
		            ctx.paint_with_alpha(parent.fading*parent.fading*activity);
		            ctx.restore();
		        }
            }

        }
        
    }

}
