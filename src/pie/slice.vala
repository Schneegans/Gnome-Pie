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

    public class Slice : GLib.Object {
    
        public bool    active   {get; private set; default = false;}
        public Image   caption  {get; private set;}
        
	    private Action action       {private get; private set;}
	    private unowned Pie parent  {private get; private set;}
	    private int    position     {private get; private set;}
	    
	    private AnimatedValue fade          {private get; private set;}
	    private AnimatedValue scale         {private get; private set;}
	    private AnimatedValue alpha         {private get; private set;}
	    private AnimatedValue fade_rotation {private get; private set;}
	    private AnimatedValue fade_scale    {private get; private set;}

	    public Slice(Action action, Pie parent) {
	        this.parent = parent;
	        this.position = parent.slice_count();
	        this.action = action;
	        
	        if (Settings.global.theme.caption)
                this.load_caption();
                
            this.parent.on_fade_in.connect(() => {
                this.fade =  new AnimatedValue.linear(0.0, 0.0, Settings.global.theme.transition_time);
                this.alpha = new AnimatedValue.linear(0.0, 1.0, Settings.global.theme.fade_in_time);
                this.scale = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 1.0/Settings.global.theme.max_zoom, 1.0/Settings.global.theme.max_zoom, Settings.global.theme.transition_time, Settings.global.theme.springiness);
                this.fade_scale = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, Settings.global.theme.fade_in_zoom, 1.0, Settings.global.theme.fade_in_time, Settings.global.theme.springiness);
                this.fade_rotation = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, Settings.global.theme.fade_in_rotation, 0.0, Settings.global.theme.fade_in_time);
            });
            
            this.parent.on_fade_out.connect(() => {
                this.alpha.reset_target(0.0, Settings.global.theme.fade_out_time);
                this.fade_scale = new AnimatedValue.cubic(AnimatedValue.Direction.IN, this.fade_scale.val, Settings.global.theme.fade_out_zoom, Settings.global.theme.fade_out_time, Settings.global.theme.springiness);
                this.fade_rotation = new AnimatedValue.cubic(AnimatedValue.Direction.IN, this.fade_rotation.val, Settings.global.theme.fade_out_rotation, Settings.global.theme.fade_out_time);
            });
                
            Settings.global.notify["theme"].connect((s, p) => {
                this.load_caption();
            });
            
            Settings.global.notify["scale"].connect((s, p) => {
                this.load_caption();
            });
            
            this.parent.on_active_change.connect(() => {
                if (this.parent.active_slice == this) {
                    this.fade.reset_target(1.0, Settings.global.theme.transition_time);
                } else {
                    this.fade.reset_target(0.0, Settings.global.theme.transition_time);
                }
            });
	    }
	
	    public void activate() {
	        this.action.execute();
        }

	    public void draw(Cairo.Context ctx, double angle, double distance) {
    	    
		    double direction = 2.0 * PI * position/parent.slice_count() + this.fade_rotation.val;
    	    double max_scale = 1.0/Settings.global.theme.max_zoom;
	        double diff = fabs(angle-direction);
	        
	        if (diff > PI)
		        diff = 2 * PI - diff;
	
	        if (diff < 2 * PI * Settings.global.theme.zoom_range)
	            max_scale = (Settings.global.theme.max_zoom/(diff * (Settings.global.theme.max_zoom - 1)/(2 * PI * Settings.global.theme.zoom_range) + 1))/Settings.global.theme.max_zoom;
		    
		    active = (distance >= Settings.global.theme.active_radius || parent.has_quick_action()) && (diff < PI/parent.slice_count());
            
            max_scale = (parent.active_slice != null ? max_scale : 1.0/Settings.global.theme.max_zoom);
            
            if (fabs(this.scale.end - max_scale) > Settings.global.theme.max_zoom*0.005)
                this.scale.reset_target(max_scale, Settings.global.theme.transition_time);
            
            this.scale.update(Settings.global.frame_time);
            this.alpha.update(Settings.global.frame_time);
            this.fade.update(Settings.global.frame_time);
            this.fade_scale.update(Settings.global.frame_time);
            this.fade_rotation.update(Settings.global.frame_time);
		    
	        ctx.save();
	        
	        double radius = Settings.global.theme.radius;
	        
	        if (atan(Settings.global.theme.slice_radius*1.3/(radius/Settings.global.theme.max_zoom)) > PI/parent.slice_count()) {
	            radius = Settings.global.theme.slice_radius*1.3/tan(PI/parent.slice_count())*Settings.global.theme.max_zoom;
	        }
	        
	        ctx.scale(scale.val*fade_scale.val, scale.val*fade_scale.val);
	        ctx.translate(cos(direction)*radius, sin(direction)*radius);
	        
	        ctx.push_group();
	        
            ctx.set_operator(Cairo.Operator.ADD);
        
            if (fade.val > 0.0) action.active_icon.paint_on(ctx, this.alpha.val*this.fade.val);
            if (fade.val < 1.0) action.inactive_icon.paint_on(ctx, this.alpha.val*(1.0 - fade.val));
            
            ctx.set_operator(Cairo.Operator.OVER);
            
            ctx.pop_group_to_source();
            ctx.paint();
	            
	        ctx.restore();
	    }
	    
	    public Color color() {
	        return action.color;
	    }
	    
	    public string name() {
	        return action.name;
	    }
	    
	    private void load_caption() {
	        int size = (int)Settings.global.theme.caption_size;
	        caption = new Image.empty(size);
            var ctx = caption.get_context();
            
            ctx.set_font_size((int)Settings.global.theme.font_size);
	        Cairo.TextExtents extents;
	        string text = action.name;
	        ctx.text_extents(text, out extents);
	        
	        if (extents.width > size && text.length > 3) {
	            text = text.substring(0, text.length-1) + "...";
	            
	            while (extents.width > size && text.length > 3) {
	                text = text.substring(0, text.length-4) + "...";
                    ctx.text_extents(text, out extents);
	            }
	        }
	        
            ctx.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
	        ctx.move_to((int)(0.5*size - 0.5*extents.width), (int)(0.5*size+0.3*Settings.global.theme.font_size)); 
	        Color color = Settings.global.theme.caption_color;
            ctx.set_source_rgb(color.r, color.g, color.g);
            ctx.show_text(text);
        }
    }

}
