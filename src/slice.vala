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
	    private double _scale = 1.0;
	    
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
    	    double max_scale = 1.0/Settings.max_zoom;
		
		    // if mouse is outside of inner ring
		    if (distance >= Settings.center_radius) {
		        double diff = fabs(angle-direction);
		        if (diff > PI)
			        diff = 2*PI - diff;
		
		        if (diff < 2*PI*Settings.zoom_range) {
		            max_scale = (Settings.max_zoom/(diff*(Settings.max_zoom-1)/(2*PI*Settings.zoom_range)+1))/Settings.max_zoom;
    			    
			    }
			
		        if (diff < PI/_parent.slice_count()) _active = true;
		        else				                 _active = false;
		        
		    } else {
		        _active = false;
		    }
		    
		    // FIXME This code is not frame-rate-independant
		    _scale = _scale*(1.0 - Settings.zoom_speed) + max_scale*Settings.zoom_speed - 0.1*(1.0 - _parent.fading*_parent.fading);
		    
		    ctx.save();
		    ctx.scale(_scale, _scale);
		    ctx.translate(cos(direction)*Settings.ring_radius, sin(direction)*Settings.ring_radius);
		    
		    if (Theme.icon_bg != null) {
		        ctx.set_source_surface(Theme.icon_bg, -0.5*Theme.icon_bg.get_width(), -0.5*Theme.icon_bg.get_height());
		        ctx.paint_with_alpha(_parent.fading*_parent.fading);
		    }
		    
		    ctx.push_group();
		    
		        if (Theme.icon_mask != null) {
		            ctx.set_source_surface(Theme.icon_mask, -0.5*Theme.icon_mask.get_width(), -0.5*Theme.icon_mask.get_height());
		            ctx.paint();
		            
		            ctx.set_operator (Cairo.Operator.IN);
		        }
		        
                ctx.set_source_surface(_action.icon, -0.5*_action.icon.get_width(), -0.5*_action.icon.get_height());
		        ctx.paint();
		        
		        ctx.set_operator (Cairo.Operator.OVER);
		        
		        if (Theme.icon_fg != null) {
		            ctx.set_source_surface(Theme.icon_fg, -0.5*Theme.icon_fg.get_width(), -0.5*Theme.icon_fg.get_height());
		            ctx.paint();
		        }
		    
		    ctx.pop_group_to_source();
		    
		    ctx.paint_with_alpha(_parent.fading*_parent.fading);
		    
		    ctx.restore();
		    
		    // draw caption
		    if (active) {
    		    ctx.save();
		        Cairo.TextExtents extents;
		        ctx.text_extents(_action.name, out extents);		    
		        ctx.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
		        ctx.set_font_size(12.0);
		        ctx.move_to( -extents.width/2 + 1, Settings.center_radius + extents.height + 30 + 1);
		        
		        ctx.set_source_rgb (0, 0, 0);
                ctx.show_text(_action.name);
                ctx.move_to( -extents.width/2, Settings.center_radius + extents.height + 30);
                ctx.set_source_rgb (1, 1, 1);
                ctx.show_text(_action.name);
                
                
		        ctx.restore();
		    }
	    }
	    
	    public Color color() {
	        return _action.color;
	    }
    }

}
