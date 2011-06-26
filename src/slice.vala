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
    
        public bool active      {get; private set; default = false;}

	    private Action action   {private get; private set;}
	    private Ring   parent   {private get; private set;}
	    private int    position {private get; private set;}
	    private double fade     {private get; private set; default = 0.0;}
	    private double scale    {private get; private set; default = 1.0;}

	    public Slice(Action action, Ring parent) {
	        _parent = parent;
	        _position = parent.slice_count();
	        _action = action;
	    }
	
	    public void activate() {
	        action.execute();
        }

	    public void draw(Cairo.Context ctx, double angle, double distance) {
    	    
		    double direction = 2.0 * PI * position/parent.slice_count() + 0.9 * (parent.fade_in ? -1.0 : 1.0) * pow(1.0 - parent.fading, 2);
    	    double max_scale = 1.0/Settings.get.theme.max_zoom;
	        double diff = fabs(angle-direction);
	        
	        if (diff > PI)
		        diff = 2 * PI - diff;
	
	        if (diff < 2 * PI * Settings.get.theme.zoom_range)
	            max_scale = (Settings.get.theme.max_zoom/(diff * (Settings.get.theme.max_zoom - 1)/(2 * PI * Settings.get.theme.zoom_range) + 1))/Settings.get.theme.max_zoom;
	        
		    
		    active = (distance >= Settings.get.theme.active_radius || parent.has_quick_action()) && (diff < PI/parent.slice_count());
		    
		    if (active) {
		        if ((fade += 1.0/(Settings.get.theme.transition_time*Settings.get.refresh_rate)) > 1.0)
                    fade = 1.0;
		    } else {
    		    if ((fade -= 1.0/(Settings.get.theme.transition_time*Settings.get.refresh_rate)) < 0.0)
                    fade = 0.0;
		    }
		    
		    max_scale = (parent.has_active_slice ? max_scale : 1.0/Settings.get.theme.max_zoom);
            double scale_step = max_scale/(Settings.get.theme.transition_time*Settings.get.refresh_rate)*0.2;
            if (fabs(scale - max_scale) > scale_step) {
                if (scale < max_scale) {
                    scale += scale_step;
                } else {
                    scale -= scale_step;
                }
                
            } else scale = max_scale;

	        ctx.save();
	        
	        ctx.scale(scale - 0.5*pow(1.0 - parent.fading, 2), scale - 0.5*pow(1.0 - parent.fading, 2));
	        ctx.translate(cos(direction)*Settings.get.theme.radius, sin(direction)*Settings.get.theme.radius);
	        
	        ctx.push_group();
	        
            ctx.set_operator(Cairo.Operator.ADD);
        
            if (fade > 0.0) {
                ctx.set_source_surface(action.active_icon, -0.5 * action.active_icon.get_width() - 1, -0.5 * action.active_icon.get_height() - 1);
                ctx.paint_with_alpha(parent.fading*parent.fading*fade);
            }
            
            if (fade < 1.0) {
                ctx.set_source_surface(action.inactive_icon, -0.5 * action.inactive_icon.get_width() - 1, -0.5 * action.inactive_icon.get_height() - 1);  
                ctx.paint_with_alpha(parent.fading*parent.fading*(1.0 - fade));
            }
            
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
    }

}
