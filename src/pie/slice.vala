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
        
	    private Action action   {private get; private set;}
	    private Pie    parent   {private get; private set;}
	    private int    position {private get; private set;}
	    private double fade     {private get; private set; default = 0.0;}
	    private double scale    {private get; private set; default = 1.0;}
	    

	    public Slice(Action action, Pie parent) {
	        this.parent = parent;
	        this.position = parent.slice_count();
	        this.action = action;
	        
	        if (Settings.global.theme.caption)
                this.load_caption();
                
            Settings.global.notify["theme"].connect((s, p) => {
                this.load_caption();
            });
            
            Settings.global.notify["scale"].connect((s, p) => {
                this.load_caption();
            });
	    }
	
	    public void activate() {
	        this.action.execute();
        }

	    public void draw(Cairo.Context ctx, double angle, double distance) {
    	    
		    double direction = 2.0 * PI * position/parent.slice_count() + 0.9 * (parent.fading < 1.0 ? -1.0 : 1.0) * pow(1.0 - parent.fading, 2);
    	    double max_scale = 1.0/Settings.global.theme.max_zoom;
	        double diff = fabs(angle-direction);
	        
	        if (diff > PI)
		        diff = 2 * PI - diff;
	
	        if (diff < 2 * PI * Settings.global.theme.zoom_range)
	            max_scale = (Settings.global.theme.max_zoom/(diff * (Settings.global.theme.max_zoom - 1)/(2 * PI * Settings.global.theme.zoom_range) + 1))/Settings.global.theme.max_zoom;
		    
		    active = (distance >= Settings.global.theme.active_radius || parent.has_quick_action()) && (diff < PI/parent.slice_count());
		    
		    if (active) this.fade += Settings.global.frame_time/Settings.global.theme.transition_time;
            else        this.fade -= Settings.global.frame_time/Settings.global.theme.transition_time;
            this.fade = this.fade.clamp(0.0, 1.0);
		    
		    max_scale = (parent.active_slice != null ? max_scale : 1.0/Settings.global.theme.max_zoom);
            double scale_step = max_scale/Settings.global.theme.transition_time*0.2*Settings.global.frame_time;
            if (fabs(scale - max_scale) > scale_step) {
                if (scale < max_scale) {
                    scale += scale_step;
                } else {
                    scale -= scale_step;
                }
                
            } else scale = max_scale;

	        ctx.save();
	        
	        // TODO increase radius for very full pies (Problem: Window radius has to be increased as well...)
	        double radius = Settings.global.theme.radius;
	        
	        /*debug("max_rad: %f act_rad: %f", 2.0*PI/parent.slice_count(), 2.0*atan(Settings.global.theme.slice_radius/radius));
	        
	        if (atan(Settings.global.theme.slice_radius/radius) + 0.15 > PI/parent.slice_count()) {
	            radius = Settings.global.theme.slice_radius/tan(PI/parent.slice_count() - 0.15*0.5);
	        }*/
	        
	        ctx.scale(scale - 0.5*pow(1.0 - parent.fading, 2), scale - 0.5*pow(1.0 - parent.fading, 2));
	        ctx.translate(cos(direction)*radius, sin(direction)*radius);
	        
	        ctx.push_group();
	        
            ctx.set_operator(Cairo.Operator.ADD);
        
            if (fade > 0.0) action.active_icon.paint(ctx, parent.fading*parent.fading*fade);
            if (fade < 1.0) action.inactive_icon.paint(ctx, parent.fading*parent.fading*(1.0 - fade));
            
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
            var ctx = new Cairo.Context(caption.surface);
            
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
