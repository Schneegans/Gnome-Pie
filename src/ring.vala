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

    public class Ring : GLib.Object {
	    
	    private Slice[] _slices;
	    private int     quick_action {private get; private set;}
	    private Slice   active_slice {private get; private set;}
	    private Center  center       {private get; private set;} 

	    public bool   fade_in      {get; private set; default = true;}
	    public double fading       {get; private set; default = 0.0;}
	    public double activity     {get; private set; default = 0.0;}
	    public Color  active_color {get; private set; default = new Color();}
	    public string active_name  {get; private set; default = "";}
	    
	    public signal void hide();
	    public signal void show();
	    
	    public Ring(string keystroke, int quick_action) {
            base();
            center = new Center(this); 
		    _slices = new Slice[0];
		    _quick_action = quick_action;
		    
		    Key.bind(keystroke, () => {show();});
        }
	    
	    public int slice_count() {
	        return _slices.length;
	    }
	    
	    public void activate() {
    	    if(active_slice != null)
    	        active_slice.activate();
    	    else if (this.has_quick_action())
    	        _slices[quick_action].activate();
        	fade_in = false;
        }
        
        public bool draw(Cairo.Context ctx, double mouse_x, double mouse_y) {
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
        
		    double distance = sqrt(mouse_x*mouse_x + mouse_y*mouse_y);
		    double angle = 0.0;
		
		    if (distance > 0) {
		        angle = acos(mouse_x/distance);
			    if (mouse_y < 0) 
			        angle = 2*PI - angle;
		    }
		    if (distance < Settings.get.theme.active_radius && this.has_quick_action())
		        angle = 2.0*PI*quick_action/(double)slice_count();
		    
		    if (distance > Settings.get.theme.active_radius || this.has_quick_action()) { 
		        if ((activity += 1.0/(Settings.get.theme.transition_time*Settings.get.refresh_rate)) > 1.0)
                    activity = 1.0;
		    } else {
		        if ((activity -= 1.0/(Settings.get.theme.transition_time*Settings.get.refresh_rate)) < 0.0)
                    activity = 0.0;
		    }

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
			        active_name  = active_slice.name();
			    }
		    }
		    
		    if (active_slice == null && this.has_quick_action()) {
			    active_slice = _slices[quick_action];
			    active_color = active_slice.color();
			    active_name  = active_slice.name();
			}
 
            return true;
        }
        
        public void add_slice(Action action) {
            _slices += new Slice(action, this);
        } 
        
        private bool has_quick_action() {
            return 0 <= quick_action < _slices.length;
        }
    }
}
