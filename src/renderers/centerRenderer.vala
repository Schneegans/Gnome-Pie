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

// Renders the center of a Pie.

public class CenterRenderer {

    private unowned PieRenderer parent;
    private Image? caption;
    private Color color;
    
    private AnimatedValue activity;
    private AnimatedValue alpha;

    public CenterRenderer(PieRenderer parent) {
        this.parent = parent;
        this.activity = new AnimatedValue.linear(0.0, 0.0, Config.global.theme.transition_time);
        this.alpha = new AnimatedValue.linear(0.0, 1.0, Config.global.theme.fade_in_time);
        this.color = new Color();
        this.caption = null;
    }
    
    public void fade_out() {
        this.activity.reset_target(0.0, Config.global.theme.fade_out_time);
        this.alpha.reset_target(0.0, Config.global.theme.fade_out_time);
    }
    
    public void set_active_slice(SliceRenderer? active_slice) {
        if (active_slice == null) {
            this.activity.reset_target(0.0, Config.global.theme.transition_time);
        } else {
            this.activity.reset_target(1.0, Config.global.theme.transition_time);
            this.caption = active_slice.caption;
            this.color   = active_slice.color;
        }
    }
    
    public void draw(double frame_time, Cairo.Context ctx, double angle, double distance) {

	    var layers = Config.global.theme.center_layers;
        
        this.activity.update(frame_time);
        this.alpha.update(frame_time);
	
	    foreach (var layer in layers) {
	    
	        ctx.save();

            double active_speed = (layer.active_rotation_mode == CenterLayer.RotationMode.AUTO) ? 
                layer.active_rotation_speed : 0.0;
            double inactive_speed = (layer.inactive_rotation_mode == CenterLayer.RotationMode.AUTO) ? 
                layer.inactive_rotation_speed : 0.0;
	        double max_scale = layer.active_scale*this.activity.val 
	            + layer.inactive_scale*(1.0-this.activity.val);
            double max_alpha = layer.active_alpha*this.activity.val 
                + layer.inactive_alpha*(1.0-this.activity.val);
            double colorize = ((layer.active_colorize == true) ? this.activity.val : 0.0) 
                + ((layer.inactive_colorize == true) ? 1.0 - this.activity.val : 0.0);
            double max_rotation_speed = active_speed*this.activity.val 
                + inactive_speed*(1.0-this.activity.val);
            CenterLayer.RotationMode rotation_mode = ((this.activity.val > 0.5) ? 
                layer.active_rotation_mode : layer.inactive_rotation_mode);
	        
	        if (rotation_mode == CenterLayer.RotationMode.TO_MOUSE) {
	            double diff = angle-layer.rotation;
	            max_rotation_speed = layer.active_rotation_speed*this.activity.val 
	                + layer.inactive_rotation_speed*(1.0-this.activity.val);
	            double smoothy = fabs(diff) < 0.9 ? fabs(diff) + 0.1 : 1.0; 
	            double step = max_rotation_speed*frame_time*smoothy;
	            
                if (fabs(diff) <= step || fabs(diff) >= 2.0*PI - step)
		            layer.rotation = angle;
	            else {
	                if ((diff > 0 && diff < PI) || diff < -PI) layer.rotation += step;
		            else            		                   layer.rotation -= step;
                }
                
	        } else if (rotation_mode == CenterLayer.RotationMode.TO_ACTIVE) {
	            max_rotation_speed *= this.activity.val;
	            
	            double slice_angle = 2*PI/parent.slice_count();
	            double direction = (int)((angle+0.5*slice_angle) / (slice_angle))*slice_angle;
	            double diff = direction-layer.rotation;
	            double step = max_rotation_speed*frame_time;
	            
                if (fabs(diff) <= step || fabs(diff) >= 2.0*PI - step)
		            layer.rotation = direction;
	            else {
	                if ((diff > 0 && diff < PI) || diff < -PI) layer.rotation += step;
		            else            		                   layer.rotation -= step;
                }
	            
	        } else layer.rotation += max_rotation_speed*frame_time;
	        
	        layer.rotation = fmod(layer.rotation+2*PI, 2*PI);
	        
	        if (colorize > 0.0) ctx.push_group();
	        
	        ctx.rotate(layer.rotation);
	        ctx.scale(max_scale, max_scale);
	        layer.image.paint_on(ctx, this.alpha.val*max_alpha);
            
            if (colorize > 0.0) {
                ctx.set_operator(Cairo.Operator.ATOP);
                ctx.set_source_rgb(this.color.r, this.color.g, this.color.b);
                ctx.paint_with_alpha(colorize);
                
                ctx.set_operator(Cairo.Operator.OVER);
                ctx.pop_group_to_source();
	            ctx.paint();
	        }
            
            ctx.restore();
        }
        
        // draw caption
        if (Config.global.theme.caption && caption != null && this.activity.val > 0) {
		    ctx.save();
            ctx.identity_matrix();
            int pos = this.parent.get_size()/2;
            ctx.translate(pos, (int)(Config.global.theme.caption_position) + pos);
            caption.paint_on(ctx, this.activity.val);
            ctx.restore();
        }
    }
}

}
