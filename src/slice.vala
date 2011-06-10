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
    	    
		    double direction = 2.0*PI*_position/_parent.slice_count();
    	    double max_scale = 1.0;
		
		    // if mouse is outside of inner ring
		    if (distance >= Settings.center_diameter) {
		        double diff = fabs(angle-direction);
		        if (diff > PI)
			        diff = 2*PI - diff;
		
		        if (diff < 2*PI*Settings.zoom_range) {
		            max_scale = Settings.max_icon_zoom/(diff*(Settings.max_icon_zoom-1)/(2*PI*Settings.zoom_range)+1);
    			    
			    }
			
		        if (diff < PI/_parent.slice_count()) _active = true;
		        else				                 _active = false;
		        
		    } else {
		        _active = false;
		    }
		    
		    // FIXME This code is not framerate-independant
		    _scale = _scale*(1.0 - Settings.icon_zoom_speed) + max_scale*Settings.icon_zoom_speed;
		    
		    ctx.save();
		    ctx.scale(_scale, _scale);
		    ctx.translate(cos(direction)*Settings.ring_diameter, sin(direction)*Settings.ring_diameter);
            ctx.set_source_surface(_action.icon, -0.5*_action.icon.get_width(), -0.5*_action.icon.get_height());
		    ctx.paint();
		    ctx.restore();
	    }
	    
	    public Color color() {
	        return _action.color;
	    }
    }

}
