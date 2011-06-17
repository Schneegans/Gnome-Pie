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

using GnomePie.Settings;
using GLib.Math;

namespace GnomePie {

    public abstract class CompositedWindow : Gtk.Window {
    
        public CompositedWindow() {
            int size = (int)(fmax(2*setting().theme.radius + 4*setting().theme.slice_radius, 2*setting().theme.center_radius));

            set_title("Gnome-Pie");
            set_size_request (size, size);
            set_skip_taskbar_hint(true);
            set_skip_pager_hint(true);
            set_keep_above(true);
            set_type_hint(Gdk.WindowTypeHint.SPLASHSCREEN);
            set_colormap(screen.get_rgba_colormap());
            set_decorated(false);
            set_app_paintable(true);
            set_resizable(false);
            
            setting().notify["open-at-mouse"].connect((s, p) => {
                if(setting().open_at_mouse) position = Gtk.WindowPosition.MOUSE;
                else                        position = Gtk.WindowPosition.CENTER;
            }); 
            
            if(setting().open_at_mouse) position = Gtk.WindowPosition.MOUSE;
            else                        position = Gtk.WindowPosition.CENTER;
                
            add_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
            
            this.button_release_event.connect ((e) => {
                mouseReleased((int) e.button, (int) e.x, (int) e.y);
                return true;
            });

            expose_event.connect(draw);
            destroy.connect(Gtk.main_quit);
        }
        
        public override void show() {
            base.show();
            grab_total_focus();
            
            Timeout.add ((uint)(1000.0/setting().refresh_rate), () => {
	            queue_draw();
	            return visible;
	        });
        }
        
        public override void hide() {
            base.hide();
            ungrab_total_focus();
        }
        
        protected abstract bool draw(Gtk.Widget da, Gdk.EventExpose event);
        protected abstract void mouseReleased(int button, int x, int y);
    
        // Code from Gnome-Do/Synapse 
        private void grab_total_focus() {
            uint32 timestamp = Gtk.get_current_event_time();
            present_with_time(timestamp);
            get_window().raise();
            get_window().focus(timestamp);

            int i = 0;
            Timeout.add (100, ()=>{
                if (i >= 100) return false;
                ++i;
                return !try_grab_window();
            });
        }
        
        // Code from Gnome-Do/Synapse 
        private void ungrab_total_focus() {
            uint32 time = Gtk.get_current_event_time();
            Gdk.pointer_ungrab(time);
            Gdk.keyboard_ungrab(time);
            Gtk.grab_remove (this);
        }
        
        // Code from Gnome-Do/Synapse 
        private bool try_grab_window() {
            uint time = Gtk.get_current_event_time();
            if (Gdk.pointer_grab (get_window(), true,
                Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK,
                null, null, time) == Gdk.GrabStatus.SUCCESS) {
                
                if (Gdk.keyboard_grab(get_window(), true, time) == Gdk.GrabStatus.SUCCESS) {
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
