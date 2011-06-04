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

	    private Cairo.ImageSurface _img;	
	    private string _command;
	    
	    public Color color {get; private set;}
	    public bool active {get; private set; default=false;}

	    public Slice(string command, string icon) {
	        _command = command;
	
            var icon_theme = Gtk.IconTheme.get_default();
            var file = icon_theme.lookup_icon(icon, 48, Gtk.IconLookupFlags.NO_SVG);
                
            debug(file.get_filename());
            
	        _img = new Cairo.ImageSurface.from_png(file.get_filename());
	        //img_active = _img;
		
		    Utils.get_icon_color(_img, out _color);
	    }
	
	    public void mousePressed() {
	        if (_active) {
	            try{
	                GLib.DesktopAppInfo item = new GLib.DesktopAppInfo(_command);
                	item.launch (null, new AppLaunchContext());
                	debug("launched " + _command);
            	} catch (Error e) {
			        warning (e.message);
		        }
		    }
        }

	    public void draw(Cairo.Context ctx, double mouse_dir, int position, int total) {
		    double maxZoom = 1.3;
		    double affected = 0.3;
		    double distance = 110;
		    double direction = 2.0*PI*position/total;
		    double scale = 1;
		
		    // if mouse is not inside ring
		    if (mouse_dir > 0) {
		        double diff = fabs(mouse_dir-direction);
		        if (diff > PI)
			        diff = 2*PI - diff;
		
		        if (diff < 2*PI*affected)
			        scale = maxZoom/(diff*(maxZoom-1)/(2*PI*affected)+1);
			
		        if (diff < PI/total) _active = true;
		        else				 _active = false;
		        
		    } else {
		        _active = false;
		    }
		
		    ctx.scale(scale, scale);
		    ctx.translate(cos(direction)*distance, sin(direction)*distance);
		
		    //if (_active) ctx.set_source_surface(img_active, -0.5*_img.get_width(), -0.5*_img.get_height());
		    /*else*/         ctx.set_source_surface(_img,       -0.5*_img.get_width(), -0.5*_img.get_height());
		
		    ctx.paint();
	    }
    }

}
