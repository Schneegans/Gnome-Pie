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

    class WindowUtils {

        // Code from Gnome-Do/Synapse 
        public static void fix_focus_on(Gtk.Window window) {
            uint32 timestamp = Gtk.get_current_event_time();
            window.present_with_time(timestamp);
            window.get_window().raise();
            window.get_window().focus(timestamp);

            int i = 0;
            Timeout.add (100, ()=>{
                if (i >= 100) return false;
                ++i;
                return !try_grab_window(window);
            });
        }
        
        // Code from Gnome-Do/Synapse 
        public static void unfix_focus_on(Gtk.Window window) {
            uint32 time = Gtk.get_current_event_time();
            Gdk.pointer_ungrab(time);
            Gdk.keyboard_ungrab(time);
            Gtk.grab_remove (window);
        }
        
        // Code from Gnome-Do/Synapse 
        private static bool try_grab_window(Gtk.Window window) {
            uint time = Gtk.get_current_event_time();
            if (Gdk.pointer_grab (window.get_window(), true,
                Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK,
                null, null, time) == Gdk.GrabStatus.SUCCESS) {
                
                if (Gdk.keyboard_grab(window.get_window(), true, time) == Gdk.GrabStatus.SUCCESS) {
                    Gtk.grab_add(window);
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
