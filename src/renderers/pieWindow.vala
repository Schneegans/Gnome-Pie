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

// An invisible window.

public class PieWindow : Gtk.Window {

    private PieRenderer renderer;
    private bool closing = false;
    private int frame_count = 0;
    private double time_count = 0.0;
    private GLib.Timer timer;

    public PieWindow() {
        this.renderer = new PieRenderer();
    
        this.set_title("Gnome-Pie");
        this.set_skip_taskbar_hint(true);
        this.set_skip_pager_hint(true);
        this.set_keep_above(true);
        this.set_type_hint(Gdk.WindowTypeHint.SPLASHSCREEN);
        this.set_colormap(screen.get_rgba_colormap());
        this.set_decorated(false);
        this.set_app_paintable(true);
        this.set_resizable(false);
        this.icon_name = "gnome-pie";
        this.set_accept_focus(false);
        this.add_events(Gdk.EventMask.BUTTON_RELEASE_MASK |
                        Gdk.EventMask.KEY_RELEASE_MASK |
                        Gdk.EventMask.KEY_PRESS_MASK);

        this.button_release_event.connect ((e) => {
            if (e.button == 1) this.activate_slice();
            else               this.cancel();
            return true;
        });
        
        this.key_release_event.connect ((e) => {
            if (!Config.global.click_to_activate)
                this.activate_slice();
            return true;
        });
        
        this.key_press_event.connect ((e) => {
            if (Gdk.keyval_name(e.keyval) == "Escape") this.cancel();
            return true;
        });

        this.expose_event.connect(this.draw);
    }
    
    public void load_pie(Pie pie) {
        renderer.load_pie(pie);
        
        this.set_window_position();
        this.set_size_request(renderer.get_size(), renderer.get_size());
    }
    
    public void open() {
        this.show();
        this.fix_focus();

        this.frame_count = 0;
        this.time_count = 0.0;

        this.timer = new GLib.Timer();
        this.timer.start();
        
        this.draw_loop(0);

        
    }
    
    private void draw_loop(uint wait) {
        Timeout.add (wait, () => {
        
            this.queue_draw();
        
            Config.global.frame_time = this.timer.elapsed();
            this.timer.reset();
            
            this.time_count += Config.global.frame_time;
            this.frame_count++;
            
            if(this.frame_count == (int)Config.global.refresh_rate) {
                debug("FPS: %f", (double)this.frame_count/this.time_count);
                this.frame_count = 0;
                this.time_count = 0.0;
            }
        
           // TODO: reduce wait time if drawing takes to much time
            int time_diff = (int)(1000.0/Config.global.refresh_rate) - (int)(1000.0*Config.global.frame_time);
            uint next_wait =  (time_diff < 1) ? 1 : (uint) time_diff;
            
            if (this.visible)
                this.draw_loop(next_wait);

            return false;
        }); 
    }
    
    private bool draw(Gtk.Widget da, Gdk.EventExpose event) {
        Posix.usleep(30*1000);
        double mouse_x = 0.0;
        double mouse_y = 0.0;
        this.get_pointer(out mouse_x, out mouse_y);
        mouse_x -= this.width_request*0.5;
        mouse_y -= this.height_request*0.5;
        
        var ctx = Gdk.cairo_create(this.window);
        ctx.set_operator(Cairo.Operator.OVER);
        ctx.translate(this.width_request*0.5, this.height_request*0.5);
        
        // clear the window
        ctx.set_operator (Cairo.Operator.CLEAR);
        ctx.paint();
        ctx.set_operator (Cairo.Operator.OVER);
        
        renderer.draw(ctx, (int)mouse_x, (int)mouse_y);
        
        return true;
    }
    
    private void activate_slice() {
        if (!this.closing) {
            this.closing = true;
            this.unfix_focus();
            renderer.activate();
            
            Timeout.add((uint)(Config.global.theme.fade_out_time*1000), () => {
                this.destroy();
                return false;
            });
        }
    }
    
    private void cancel() {
        if (!this.closing) {
            this.closing = true;
            this.unfix_focus();
            renderer.cancel();
            
            Timeout.add((uint)(Config.global.theme.fade_out_time*1000), () => {
                this.destroy();
                return false;
            });
        }
    }
    
    private void set_window_position() {
        if(Config.global.open_at_mouse) this.set_position(Gtk.WindowPosition.MOUSE);
        else                            this.set_position(Gtk.WindowPosition.CENTER);
    }
    
    // utilities for grabbing focus
    // Code from Gnome-Do/Synapse 
    private void fix_focus() {
        uint32 timestamp = Gtk.get_current_event_time();
        this.present_with_time(timestamp);
        this.get_window().raise();
        this.get_window().focus(timestamp);

        int i = 0;
        Timeout.add (100, ()=>{
            if (++i >= 100) return false;
            return !try_grab_window();
        });
    }
    
    // Code from Gnome-Do/Synapse 
    private void unfix_focus() {
        uint32 time = Gtk.get_current_event_time();
        Gdk.pointer_ungrab(time);
        Gdk.keyboard_ungrab(time);
        Gtk.grab_remove(this);
    }
    
    // Code from Gnome-Do/Synapse 
    private bool try_grab_window() {
        uint time = Gtk.get_current_event_time();
        if (Gdk.pointer_grab (this.get_window(), true,
            Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK,
            null, null, time) == Gdk.GrabStatus.SUCCESS) {
            
            if (Gdk.keyboard_grab(this.get_window(), true, time) == Gdk.GrabStatus.SUCCESS) {
                Gtk.grab_add(this);
                return true;
            } else {
                Gdk.pointer_ungrab(time);
                return false;
            }
        }
        return false;
    }  
}

}
