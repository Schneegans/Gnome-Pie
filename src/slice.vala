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

	    private Action _action;
	    private Ring   _parent;
	    private int    _position;
	    private double _fade = 0.0;
	    
	    public bool active{get; private set; default=false;}

	    public Slice(string command, string icon, Ring parent) {
	        _parent = parent;
	        _position = _parent.slice_count();
	        _action = new Action(command, icon);
	    }
	
	    public void activate() {
	        _action.execute();
        }

	    public void draw(Cairo.Context ctx, double angle, double distance) {
    	    
		    double direction = 2.0*PI*_position/_parent.slice_count() + 0.5*(_parent.fade_in ? -1.0 : 1.0)*(1.0-_parent.fading);
    	    double max_scale = 1.0/Settings.theme.max_zoom;
	        double diff = fabs(angle-direction);
	        
	        if (diff > PI)
		        diff = 2*PI - diff;
	
	        if (diff < 2*PI*Settings.theme.zoom_range) {
	            max_scale = (Settings.theme.max_zoom/(diff*(Settings.theme.max_zoom-1)/(2*PI*Settings.theme.zoom_range)+1))/Settings.theme.max_zoom; 
		    }
		    
			if (distance >= Settings.theme.active_radius) {
		        if (diff < PI/_parent.slice_count()) active = true;
		        else				                 active = false; 
		    } else {
		        active = false;
		    }
		    
		    if (active == true) {
		        if ((_fade += 1.0/(Settings.theme.transition_time*Settings.refresh_rate)) > 1.0)
                    _fade = 1.0;
		    } else {
    		    if ((_fade -= 1.0/(Settings.theme.transition_time*Settings.refresh_rate)) < 0.0)
                    _fade = 0.0;
		    }
		    
		    double scale = max_scale*_parent.activity + (1.0-_parent.activity)/Settings.theme.max_zoom - 0.1*(1.0 - _parent.fading*_parent.fading);

	        ctx.save();
	        
	        ctx.scale(scale, scale);
	        ctx.translate(cos(direction)*Settings.theme.radius, sin(direction)*Settings.theme.radius);
	        
	        ctx.push_group();
	        
	            ctx.set_operator(Cairo.Operator.ADD);
	        
	            if (_fade > 0.0) {
                    ctx.set_source_surface(_action.active_icon, -0.5*_action.active_icon.get_width()-1, -0.5*_action.active_icon.get_height()-1);
                    ctx.paint_with_alpha(_parent.fading*_parent.fading*_fade);
                }
                
                if (_fade < 1.0) {
                    ctx.set_source_surface(_action.inactive_icon, -0.5*_action.inactive_icon.get_width()-1, -0.5*_action.inactive_icon.get_height()-1);  
                    ctx.paint_with_alpha(_parent.fading*_parent.fading*(1.0 - _fade));
                }
                
                ctx.set_operator(Cairo.Operator.OVER);
            
            ctx.pop_group_to_source();
            ctx.paint();
	            
	        ctx.restore();
		    
		    // draw caption
		    if (Settings.theme.caption == true && active) {
    		    ctx.save();
    		    
		        Cairo.TextExtents extents;
		        ctx.set_font_size(Settings.theme.font_size);
		        ctx.text_extents(_action.name, out extents);		    
		        ctx.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
		        ctx.move_to(-extents.width/2, Settings.theme.caption_position+extents.height/2); 
                ctx.set_source_rgba(1, 1, 1, _parent.fading*_parent.fading*_parent.activity);
                ctx.show_text(_action.name);
                
		        ctx.restore();
		    }
	    }
	    
	    public Color color() {
	        return _action.color;
	    }
    }

}
