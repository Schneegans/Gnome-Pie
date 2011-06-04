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

    public class Ring : Gtk.Window {

	    private Cairo.ImageSurface imgRing_;
	    private Cairo.ImageSurface imgGlow_;
	    private Cairo.ImageSurface imgArrow_;
	
	    private double rot_= 0.0;
	    private double baseRot_ = 0.0;
	    
	    private Slice[] slices_;
	    private int _activeSlice = -1;
	    
	    private int size_ = 400;
	    
	    private void mousePressed(int button, int x, int y) {
        	if (button == 1) {
        	    for (int s=0; s<slices_.length; ++s) {
			        slices_[s].mousePressed();
		        }
	        	hide();
	        }
        }
        
        private void addSlice(string command, string icon) {
            slices_ += new Slice(command, icon);
        }
        
        private bool draw(Gtk.Widget da, Gdk.EventExpose event) {
        
            double mouse_x = 0;
		    double mouse_y = 0;
		    get_pointer(out mouse_x, out mouse_y);
        
            var ctx = Gdk.cairo_create(da.window);

            // clear the window
            ctx.set_operator (Cairo.Operator.CLEAR);
            ctx.paint();

		    mouse_x -= size_*0.5;
		    mouse_y -= size_*0.5;
		    double distance = sqrt(mouse_x*mouse_x + mouse_y*mouse_y);

		    baseRot_ += 0.5/Utils.refresh_rate;
		
		    ctx.set_operator(Cairo.Operator.DEST_OVER);
		    ctx.set_source_rgb(1, 1, 1);
		    
		    double angle = -1;
		
		    if (distance > 45) {
		        
		        angle = acos(mouse_x/distance);
			    double test = mouse_x*sin(rot_) - mouse_y*cos(rot_);
			    
			    if (mouse_y < 0)
				    angle = 2*PI - angle;

			    if (fabs(angle - rot_) > 0.15) {
				    if (test < 0) rot_ += 8.0/Utils.refresh_rate;
				    else		  rot_ -= 8.0/Utils.refresh_rate;
			    }
			    else {
				    rot_ = angle;
			    }
		
			    rot_ = fmod(rot_+2*PI, 2*PI);
		    
			    ctx.translate(size_*0.5, size_*0.5);
			    ctx.rotate(rot_);
			    
			    double alpha = distance > 65 ? 1.0 : 1.0 - 0.05*(65-distance);
			
			    ctx.set_source_surface(imgArrow_, -75, -75);
			    ctx.paint_with_alpha(alpha);
			
			    ctx.identity_matrix();
		    }
		    
            ctx.translate(size_*0.5, size_*0.5);
			ctx.rotate(baseRot_);
			
		    ctx.set_source_surface(imgRing_, -75, -75);
		    ctx.paint();

		    ctx.set_source_surface(imgGlow_, -75, -75);
		    ctx.paint_with_alpha(0.7);
		    
		    ctx.set_operator(Cairo.Operator.ATOP);
		    if (_activeSlice >= 0)
		        ctx.set_source_rgb(slices_[_activeSlice].color.r, slices_[_activeSlice].color.g, slices_[_activeSlice].color.b);
		    else
		        ctx.set_source_rgb(0.5, 0.5, 0.5);
		        
            ctx.rectangle (-size_*0.5, -size_*0.5, size_, size_);
            ctx.fill ();
            ctx.stroke ();
            
            ctx.set_operator(Cairo.Operator.OVER);
		    
		    _activeSlice = -1;
		    
		    for (int s=0; s<slices_.length; ++s) {
			    ctx.identity_matrix();
			    ctx.translate(size_*0.5, size_*0.5);
			    slices_[s].draw(ctx, angle, s, slices_.length);
			    
			    if(slices_[s].active)
			        _activeSlice = s;
		    }
		    
		    return true;
        }
 
        public Ring() {
            title = "Gnome-Pie";
            set_default_size (size_, size_);
            set_skip_taskbar_hint(true);
            set_skip_pager_hint(true);
            set_keep_above(true);
            set_type_hint(Gdk.WindowTypeHint.NORMAL);
            set_colormap(this.screen.get_rgba_colormap());
            position = Gtk.WindowPosition.MOUSE;
            decorated = false;
            app_paintable = true;
            
            add_events(Gdk.EventMask.BUTTON_PRESS_MASK);

            this.button_press_event.connect ((e) => {
                mousePressed((int) e.button, (int) e.x, (int) e.y);
                return true;
            });

            expose_event.connect(draw);
            destroy.connect (Gtk.main_quit);
            
		    imgRing_ = new Cairo.ImageSurface.from_png("data/ring.png");
		    imgGlow_ = new Cairo.ImageSurface.from_png("data/glow.png");
		    imgArrow_ = new Cairo.ImageSurface.from_png("data/arrow.png");
		    
		    slices_ = new Slice[0];
		    
		    addSlice("firefox.desktop", "firefox");
		    addSlice("eog.desktop", "eog");
		    addSlice("gnome-terminal.desktop", "terminal");
		    addSlice("thunderbird.desktop", "thunderbird");
		    addSlice("blender.desktop", "blender");
        }
    }
}
