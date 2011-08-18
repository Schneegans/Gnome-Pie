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

public class SliceRenderer : GLib.Object {

    public bool active {get; private set; default = false;}
    public Image caption {get; private set;}
    public Color color {get; private set;}
    
    private Image active_icon;
    private Image inactive_icon;
    
    private Action action;

    private unowned PieRenderer parent;    
    private int position;
    
    private AnimatedValue fade;
    private AnimatedValue scale;
    private AnimatedValue alpha;
    private AnimatedValue fade_rotation;
    private AnimatedValue fade_scale;

    public SliceRenderer(PieRenderer parent) {
        this.parent = parent;
       
        this.fade =  new AnimatedValue.linear(0.0, 0.0, Config.global.theme.transition_time);
        this.alpha = new AnimatedValue.linear(0.0, 1.0, Config.global.theme.fade_in_time);
        this.scale = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 
                                                 1.0/Config.global.theme.max_zoom, 
                                                 1.0/Config.global.theme.max_zoom, 
                                                 Config.global.theme.transition_time, 
                                                 Config.global.theme.springiness);
        this.fade_scale = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 
                                                 Config.global.theme.fade_in_zoom, 1.0, 
                                                 Config.global.theme.fade_in_time, 
                                                 Config.global.theme.springiness);
        this.fade_rotation = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 
                                                 Config.global.theme.fade_in_rotation, 0.0, 
                                                 Config.global.theme.fade_in_time);
    }
    
    public void load(Action action, int position) {
        this.position = position;
        this.action = action;
        
    
        if (Config.global.theme.caption)
            this.caption = new Image.from_string(action.name, 
                                                (int)Config.global.theme.caption_size,
                                                (int)Config.global.theme.font_size);
            
        this.active_icon = new Image.themed_icon(action.icon_name, true);
        this.inactive_icon = new Image.themed_icon(action.icon_name, false);
        
        this.color = new Color.from_icon(this.active_icon);
    }
    
    public void activate() {
        action.activate();
    }
    
    public void fade_out() {
        this.alpha.reset_target(0.0, Config.global.theme.fade_out_time);
        this.fade_scale = new AnimatedValue.cubic(AnimatedValue.Direction.IN, 
                                             this.fade_scale.val, 
                                             Config.global.theme.fade_out_zoom, 
                                             Config.global.theme.fade_out_time, 
                                             Config.global.theme.springiness);
        this.fade_rotation = new AnimatedValue.cubic(AnimatedValue.Direction.IN, 
                                             this.fade_rotation.val, 
                                             Config.global.theme.fade_out_rotation, 
                                             Config.global.theme.fade_out_time);
    }
    
    public void set_active_slice(SliceRenderer? active_slice) {
       if (active_slice == this) {
            this.fade.reset_target(1.0, Config.global.theme.transition_time);
        } else {
            this.fade.reset_target(0.0, Config.global.theme.transition_time);
        }
    }

    public void draw(double frame_time, Cairo.Context ctx, double angle, double distance) {
	    
	    double direction = 2.0 * PI * position/parent.slice_count() + this.fade_rotation.val;
	    double max_scale = 1.0/Config.global.theme.max_zoom;
        double diff = fabs(angle-direction);
        
        if (diff > PI)
	        diff = 2 * PI - diff;

        if (diff < 2 * PI * Config.global.theme.zoom_range)
            max_scale = (Config.global.theme.max_zoom/(diff * (Config.global.theme.max_zoom - 1)
                        /(2 * PI * Config.global.theme.zoom_range) + 1))
                        /Config.global.theme.max_zoom;
	    
	    active = ((parent.active_slice >= 0) && (diff < PI/parent.slice_count()));
        
        max_scale = (parent.active_slice >= 0 ? max_scale : 1.0/Config.global.theme.max_zoom);
        
        if (fabs(this.scale.end - max_scale) > Config.global.theme.max_zoom*0.005)
            this.scale.reset_target(max_scale, Config.global.theme.transition_time);
        
        this.scale.update(frame_time);
        this.alpha.update(frame_time);
        this.fade.update(frame_time);
        this.fade_scale.update(frame_time);
        this.fade_rotation.update(frame_time);
	    
        ctx.save();
        
        double radius = Config.global.theme.radius;
        
        if (atan((Config.global.theme.slice_radius+Config.global.theme.slice_gap)
          /(radius/Config.global.theme.max_zoom)) > PI/parent.slice_count()) {
            radius = (Config.global.theme.slice_radius+Config.global.theme.slice_gap)
                     /tan(PI/parent.slice_count())*Config.global.theme.max_zoom;
        }
        
        ctx.scale(scale.val*fade_scale.val, scale.val*fade_scale.val);
        ctx.translate(cos(direction)*radius, sin(direction)*radius);
        
        ctx.push_group();
        
        ctx.set_operator(Cairo.Operator.ADD);
    
        if (fade.val > 0.0) active_icon.paint_on(ctx, this.alpha.val*this.fade.val);
        if (fade.val < 1.0) inactive_icon.paint_on(ctx, this.alpha.val*(1.0 - fade.val));
        
        ctx.set_operator(Cairo.Operator.OVER);
        
        ctx.pop_group_to_source();
        ctx.paint();
            
        ctx.restore();
    }
}

}
