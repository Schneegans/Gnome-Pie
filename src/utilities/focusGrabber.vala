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

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////    
/// Some helper methods which focus the input on a given Gtk.Window.
/////////////////////////////////////////////////////////////////////////

public class FocusGrabber : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Utilities for grabbing focus.
    /// Code from Gnome-Do/Synapse.
    /////////////////////////////////////////////////////////////////////
    
    public static void grab(Gtk.Window window) {
        window.present_with_time(Gdk.CURRENT_TIME);
        window.get_window().raise();
        window.get_window().focus(Gdk.CURRENT_TIME);

        int i = 0;
        Timeout.add(100, () => {
            if (++i >= 100) return false;
            return !try_grab_window(window);
        });
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Code from Gnome-Do/Synapse.
    /////////////////////////////////////////////////////////////////////
    
    public static void ungrab(Gtk.Window window) {
        Gdk.pointer_ungrab(Gdk.CURRENT_TIME);
        Gdk.keyboard_ungrab(Gdk.CURRENT_TIME);
        Gtk.grab_remove(window);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Code from Gnome-Do/Synapse.
    /////////////////////////////////////////////////////////////////////
    
    private static bool try_grab_window(Gtk.Window window) {
        if (Gdk.pointer_grab(window.get_window(), true, Gdk.EventMask.BUTTON_PRESS_MASK | 
                             Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK,
                             null, null, Gdk.CURRENT_TIME) == Gdk.GrabStatus.SUCCESS) {
            
            if (Gdk.keyboard_grab(window.get_window(), true, Gdk.CURRENT_TIME) == Gdk.GrabStatus.SUCCESS) {
                Gtk.grab_add(window);
                return true;
            } else {
                Gdk.pointer_ungrab(Gdk.CURRENT_TIME);
                return false;
            }
        }
        return false;
    }  
}

}
