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

    public abstract class Window : Gtk.Window {
    
        // stores all key bindings associated with this window
        private BindingManager keys {private get; private set;}
    
        // c'tor
        public Window(string stroke) {
            base.set_title("Gnome-Pie");
            base.set_skip_taskbar_hint(true);
            base.set_skip_pager_hint(true);
            base.set_keep_above(true);
            base.set_type_hint(Gdk.WindowTypeHint.SPLASHSCREEN);
            base.set_colormap(screen.get_rgba_colormap());
            base.set_decorated(false);
            base.set_app_paintable(true);
            base.set_resizable(false);
            base.set_accept_focus(false);
            base.add_events(Gdk.EventMask.BUTTON_RELEASE_MASK |
                            Gdk.EventMask.KEY_RELEASE_MASK |
                            Gdk.EventMask.KEY_PRESS_MASK);
            
            this.set_size();
            this.reposition();
            
            this.keys = new BindingManager();
            
            Settings.global.notify["open-at-mouse"].connect((s, p) => {
                this.reposition();
            }); 
 
            base.button_release_event.connect ((e) => {
                this.mouse_released((int) e.button, (int) e.x, (int) e.y);
                return true;
            });
            
            base.key_release_event.connect ((e) => {
                keys.on_key_release(e.keyval, e.state);
                return true;
            });
            
            base.key_press_event.connect ((e) => {
                keys.on_key_press(e.keyval, e.state);
                return true;
            });

            base.expose_event.connect(this.draw);
            base.destroy.connect(Gtk.main_quit);
            
            if (stroke != "") {
                keys.bind_global_press(stroke, () => {
                    this.fade_in();
                });
		        
		        keys.bind_local_release(stroke, () => {
		            if (!Settings.global.click_to_activate)
		                this.activate_pie();
		        });
		        
		        keys.bind_local_press(stroke, () => {
		            if (Settings.global.click_to_activate) 
		                this.fade_out();
		        });
		    }
		    
		    keys.bind_local_press("Escape", () => { 
		        this.fade_out();
		    });
		    
		    keys.bind_local_press("Return", () => { 
		        this.activate_pie();
		    });
		    
		    keys.bind_local_press("space", () => { 
		        this.activate_pie();
		    });
        }
        
        // virtual and abstract stuff
        protected abstract bool draw(Gtk.Widget da, Gdk.EventExpose event);

        public virtual void activate_pie() {
            this.unfix_focus();
	        base.has_focus = 0;
        }
        
        public virtual void fade_out() {
            this.unfix_focus();
	        base.has_focus = 0;
        }

        public virtual void fade_in() {
            base.show();
            this.fix_focus();

            int frame_count = 0;
            double time_count = 0.0;

            var timer = new GLib.Timer();
            timer.start();

            Timeout.add ((uint)(1000.0/Settings.global.refresh_rate), () => {
            
                this.queue_draw();
            
                Settings.global.frame_time = timer.elapsed();
                timer.reset();
                
                time_count += Settings.global.frame_time;
                frame_count++;
                
                if(frame_count == (int)Settings.global.refresh_rate) {
                    //Logger.debug("FPS: %f", (double)frame_count/time_count);
                    frame_count = 0;
                    time_count = 0.0;
                }
            
               // TODO: reduce wait time if drawing takes to much time
	           // int time_diff = (int)(1000.0/Settings.global.refresh_rate) - (int)(1000.0*Settings.global.frame_time);
	           // wait =  (time_diff < 1) ? 1 : (uint) time_diff;

	            return base.visible;
	        }); 
        }
        
        public void set_size(int min_size = 0) {
            int size = (int)(fmax(2*Settings.global.theme.radius 
                        + 2*Settings.global.theme.slice_radius*Settings.global.theme.max_zoom, 
                          2*Settings.global.theme.center_radius));
            size = (int)fmax(size, min_size);
            base.set_size_request (size, size);
        }
        
        // private methods
        private void mouse_released(int button, int x, int y) {
            if (button == 1) activate_pie();
        }
        
        private void reposition() {
            if(Settings.global.open_at_mouse) base.set_position(Gtk.WindowPosition.MOUSE);
            else                              base.set_position(Gtk.WindowPosition.CENTER);
        }
        
        // utilities for grabbing focus
        // Code from Gnome-Do/Synapse 
        private void fix_focus() {
            uint32 timestamp = Gtk.get_current_event_time();
            base.present_with_time(timestamp);
            base.get_window().raise();
            base.get_window().focus(timestamp);

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
            Gtk.grab_remove(base);
        }
        
        // Code from Gnome-Do/Synapse 
        private bool try_grab_window() {
            uint time = Gtk.get_current_event_time();
            if (Gdk.pointer_grab (base.get_window(), true,
                Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK,
                null, null, time) == Gdk.GrabStatus.SUCCESS) {
                
                if (Gdk.keyboard_grab(base.get_window(), true, time) == Gdk.GrabStatus.SUCCESS) {
                    Gtk.grab_add(base);
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
