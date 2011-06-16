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
	    private Slice   _active_slice;
	    private Center  _center;

	    public bool   fade_in  {get; private set; default = true;}
	    public double fading   {get; private set; default = 0.0;}
	    public double activity {get; private set; default = 0.0;}
	    
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
	    
	    public Color active_color{get; private set; default = new Color();}
	    
	    public int slice_count() {
	        return _slices.length;
	    }
	    
	    protected override void mouseReleased(int button, int x, int y) {
        	if (button == 1 && _fading == 1.0) {
        	    if(_active_slice != null)
        	        _active_slice.activate();
	        	_fade_in = false;
	        }
        }
        
        protected override bool draw(Gtk.Widget da, Gdk.EventExpose event) {
            // fading
            if (_fade_in) {
                _fading += 1.0/(Settings.refresh_rate*Settings.theme.fade_in_time);
                if (_fading > 1.0)
                    _fading = 1.0;
            } else {
                _fading -= 1.0/(Settings.refresh_rate*Settings.theme.fade_out_time);
                if (_fading < 0.0) {
                    _fading = 0.0;
                    _fade_in = true;
                    hide();
                }     
            }
        
            double mouse_x = 0;
		    double mouse_y = 0;
		    get_pointer(out mouse_x, out mouse_y);
		    
		    mouse_x -= width_request/2;
		    mouse_y -= height_request/2;
		    double distance = sqrt(mouse_x*mouse_x + mouse_y*mouse_y);
		    
		    if (distance > Settings.theme.active_radius) { 
		        if ((activity += 1.0/(Settings.theme.transition_time*Settings.refresh_rate)) > 1.0)
                    activity = 1.0;
		    } else {
		        if ((activity -= 1.0/(Settings.theme.transition_time*Settings.refresh_rate)) < 0.0)
                    activity = 0.0;
		    }
		    
		    double angle = -1;
		
		    if (distance > 0) {
		        angle = acos(mouse_x/distance);
			    if (mouse_y < 0) angle = 2*PI - angle;
		    }
		    
            var ctx = Gdk.cairo_create(da.window);
            ctx.set_operator(Cairo.Operator.OVER);

            // clear the window
            ctx.save();
            ctx.set_operator (Cairo.Operator.CLEAR);
            ctx.paint();
            ctx.restore();

            ctx.translate(width_request*0.5, height_request*0.5);
            
            _center.draw(ctx, angle, distance);
            
            _active_slice = null;
		    
		    for (int s=0; s<_slices.length; ++s) {
			    _slices[s].draw(ctx, angle, distance);
			    
			    if(_slices[s].active) {
			        _active_slice   = _slices[s];
			        _active_color = _active_slice.color();
			    }
		    }
 
            return true;
        }
        
        private void add_slice(string command, string icon) {
            _slices += new Slice(command, icon, this);
        }
  
    }
}
