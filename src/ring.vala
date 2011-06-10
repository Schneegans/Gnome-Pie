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

    public class Ring : CompositedWindow {
	    
	    private Slice[] _slices;
	    private Slice   _activeSlice;
	    private Center  _center;
	    
	    public Ring() {
            base();
            
            _center = new Center(this); 
		    _slices = new Slice[0];
		    
		    add_slice("firefox.desktop", "firefox");
		    add_slice("eog.desktop", "eog");
		    add_slice("gnome-terminal.desktop", "terminal");
		    add_slice("thunderbird.desktop", "thunderbird");
		    add_slice("blender.desktop", "blender");
        }
	    
	    public Color active_color () {
    	    if (_activeSlice != null) return _activeSlice.color();
    	    else return new Color();
	    }
	    
	    public int slice_count () {
	        return _slices.length;
	    }
	    
	    protected override void mouseReleased(int button, int x, int y) {
        	if (button == 1) {
        	    if(_activeSlice != null)
        	        _activeSlice.activate();
	        	hide();
	        }
        }
        
        protected override bool draw(Gtk.Widget da, Gdk.EventExpose event) {
            double mouse_x = 0;
		    double mouse_y = 0;
		    get_pointer(out mouse_x, out mouse_y);
		    
		    mouse_x -= _size/2;
		    mouse_y -= _size/2;
		    double distance = sqrt(mouse_x*mouse_x + mouse_y*mouse_y);
		    double angle = -1;
		
		    if (distance > 0) {
		        angle = acos(mouse_x/distance);
			    if (mouse_y < 0) angle = 2*PI - angle;
		    }
		    
            var back_ctx = new Cairo.Context(_backbuffer);
            back_ctx.set_operator(Cairo.Operator.DEST_OVER);

            // clear the window
            back_ctx.save();
            back_ctx.set_operator (Cairo.Operator.CLEAR);
            back_ctx.paint();
            back_ctx.restore();

            _center.draw(back_ctx, angle, distance);
            
            _activeSlice = null;
		    back_ctx.translate(_size*0.5, _size*0.5);
		    for (int s=0; s<_slices.length; ++s) {
			    _slices[s].draw(back_ctx, angle, distance);
			    
			    if(_slices[s].active)
			        _activeSlice = _slices[s];
		    }
		    
		    var front_ctx = Gdk.cairo_create(da.window);
		    // clear the window
            front_ctx.set_operator (Cairo.Operator.CLEAR);
            front_ctx.paint();
            
            front_ctx.set_operator(Cairo.Operator.DEST_OVER);
            front_ctx.set_source_surface(_backbuffer, 0, 0);
            front_ctx.paint();
            
            return true;
        }
        
        private void add_slice(string command, string icon) {
            _slices += new Slice(command, icon, this);
        }
  
    }
}
