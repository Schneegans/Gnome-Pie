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
	    private Slice   active_slice {private get; private set;}
	    private Center  center       {private get; private set;} 

	    public bool   fade_in      {get; private set; default = true;}
	    public double fading       {get; private set; default = 0.0;}
	    public double activity     {get; private set; default = 0.0;}
	    public Color  active_color {get; private set; default = new Color();}
	    
	    public Ring() {
	    
            base();
            
            center = new Center(this); 
		    _slices = new Slice[0];
		    
		    add_slice(new AppAction("Firefox", "firefox", "firefox"));
		    add_slice(new AppAction("Image Viewer", "eog", "eog"));
		    add_slice(new AppAction("Terminal", "terminal", "gnome-terminal"));
		    add_slice(new AppAction("Thunderbird", "thunderbird", "thunderbird"));
		    add_slice(new AppAction("Blender", "blender", "blender"));
		    
		    add_slice(new KeyAction("Play/Pause", "media-playback-start", "XF86AudioPlay"));

        }
	    
	    public int slice_count() {
	        return _slices.length;
	    }
	    
	    protected override void mouseReleased(int button, int x, int y) {
        	if (button == 1) {
        	    if(active_slice != null) {
        	        this.ungrab_total_focus();
        	        this.has_focus = 0;
        	        active_slice.activate();
        	    }
	        	fade_in = false;
	        }
        }
        
        protected override bool draw(Gtk.Widget da, Gdk.EventExpose event) {
            if (fade_in) {
                fading += 1.0/(Settings.get.refresh_rate*Settings.get.theme.fade_in_time);
                if (fading > 1.0) 
                    fading = 1.0;
                
            } else {
                fading -= 1.0/(Settings.get.refresh_rate*Settings.get.theme.fade_out_time);
                if (fading < 0.0) {
                    fading = 0.0;
                    fade_in = true;
                    hide();
                }     
            }
        
            double mouse_x = 0.0;
		    double mouse_y = 0.0;
		    get_pointer(out mouse_x, out mouse_y);
		    
		    mouse_x -= width_request/2;
		    mouse_y -= height_request/2;
		    double distance = sqrt(mouse_x*mouse_x + mouse_y*mouse_y);
		    
		    double angle = 0.0;
		
		    if (distance > 0) {
		        angle = acos(mouse_x/distance);
			    if (mouse_y < 0) 
			        angle = 2*PI - angle;
		    }
		    
		    if (distance > Settings.get.theme.active_radius) { 
		        if ((activity += 1.0/(Settings.get.theme.transition_time*Settings.get.refresh_rate)) > 1.0)
                    activity = 1.0;
		    } else {
		        if ((activity -= 1.0/(Settings.get.theme.transition_time*Settings.get.refresh_rate)) < 0.0)
                    activity = 0.0;
		    }

            var ctx = Gdk.cairo_create(da.window);
            ctx.set_operator(Cairo.Operator.OVER);
            ctx.translate(width_request*0.5, height_request*0.5);

            // clear the window
            ctx.save();
            ctx.set_operator (Cairo.Operator.CLEAR);
            ctx.paint();
            ctx.restore();

            center.draw(ctx, angle, distance);
            
            active_slice = null;
		    
		    for (int s=0; s<_slices.length; ++s) {
			    _slices[s].draw(ctx, angle, distance);
			    
			    if(_slices[s].active) {
			        active_slice = _slices[s];
			        active_color = active_slice.color();
			    }
		    }
 
            return true;
        }
        
        public void add_slice(Action action) {
            _slices += new Slice(action, this);
        } 
    }
}
