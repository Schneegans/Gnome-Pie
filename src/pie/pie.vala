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

    public class Pie : Window {

        public signal void on_fade_in();
        public signal void on_fade_out();
        public signal void on_active_change();

        public Slice    active_slice {get; private set;}
        public bool     fading_in    {get; private set;}
	    public bool     fading_out   {get; private set;}
	    
	    private Gee.ArrayList<Slice?> slices {private get; private set;}
	    private Center  center       {private get; private set;}
	    private int     quick_action {private get; private set;}

	    public Pie(string stroke, int quick_action = -1) {
	        base(stroke);
            this.center = new Center(this); 
		    this.slices = new Gee.ArrayList<Slice?>();
		    this.quick_action = quick_action;
        }
        
        public override void activate_pie() {
            if(!fading_out) {
                base.activate_pie();
            
        	    if(active_slice != null)          this.active_slice.activate();
        	    else if (this.has_quick_action()) this.slices[this.quick_action].activate();
        	        
            	this.fade_out();
        	}
        }
        
        public override void fade_in() {
            if (!this.fading_out) {
	            base.fade_in();
	            this.on_fade_in();
	            this.fading_out = false;
	            this.fading_in  = true;
	            
	            Timeout.add ((uint)(Settings.global.theme.fade_in_time * 1000), () => {
        	        return fading_in = false;
        	    });
        	 }
        }
	    
	    public override void fade_out() {
	        if (!this.fading_out) {
	            base.fade_out();
	            this.on_fade_out();
	            this.fading_out = true;
	            this.fading_in  = false;
	        
                Timeout.add ((uint)(Settings.global.theme.fade_out_time * 1000), () => {
                    base.hide();
                    return fading_out = false;
                });
            }
        }
        
        protected override bool draw(Gtk.Widget da, Gdk.EventExpose event) {
            
            double mouse_x = 0.0;
	        double mouse_y = 0.0;
	        base.get_pointer(out mouse_x, out mouse_y);
	        mouse_x -= base.width_request*0.5;
	        mouse_y -= base.height_request*0.5;
	        
	        var ctx = Gdk.cairo_create(base.window);
            ctx.set_operator(Cairo.Operator.OVER);
            ctx.translate(base.width_request*0.5, base.height_request*0.5);
        
		    double distance = sqrt(mouse_x*mouse_x + mouse_y*mouse_y);
		    double angle = 0.0;
		
		    if (distance > 0) {
		        angle = acos(mouse_x/distance);
			    if (mouse_y < 0) angle = 2*PI - angle;
		    }
		    if (distance < Settings.global.theme.active_radius && this.has_quick_action())
		        angle = 2.0*PI*quick_action/(double)slice_count();

            // clear the window
            ctx.set_operator (Cairo.Operator.CLEAR);
            ctx.paint();
            ctx.set_operator (Cairo.Operator.OVER);

            center.draw(ctx, angle, distance);
		    
		    foreach (var slice in this.slices)
			    slice.draw(ctx, angle, distance);
			    
			Slice new_active_slice = null;
		    foreach (var slice in this.slices)
			    if(slice.active) new_active_slice = slice;
		    
		    if (new_active_slice == null && this.has_quick_action())
			    new_active_slice = this.slices[quick_action];
		    
		    if (new_active_slice != active_slice && !fading_out) {
		        active_slice = new_active_slice;
		        on_active_change();
		    }
 
            return true;
        }
        
        public int slice_count() {
	        return this.slices.size;
	    }
        
        public void add_slice(Action action) {
            this.slices.add(new Slice(action, this));
        } 
        
        public bool has_quick_action() {
            return (0 <= this.quick_action) && (this.quick_action < this.slice_count());
        }
    }
}
