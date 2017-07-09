/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2017 by Simon Schneegans
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// Some helper methods which focus the input on a given Gtk.Window.
/////////////////////////////////////////////////////////////////////////

public class FocusGrabber : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Utilities for grabbing focus.
    /// Code roughly from Gnome-Do/Synapse.
    /////////////////////////////////////////////////////////////////////

    public static void grab(Gdk.Window window) {
        window.raise();
        window.focus(Gdk.CURRENT_TIME);

        if (!try_grab_window(window)) {
            int i = 0;
            Timeout.add(100, () => {
                if (++i >= 100) return false;
                return !try_grab_window(window);
            });
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Code roughly from Gnome-Do/Synapse.
    /////////////////////////////////////////////////////////////////////

    public static void ungrab() {
        #if HAVE_GTK_3_20
            var seat = Gdk.Display.get_default().get_default_seat();
            seat.ungrab();
        #else
            var display = Gdk.Display.get_default();
            var manager = display.get_device_manager();

            GLib.List<weak Gdk.Device?> list = manager.list_devices(Gdk.DeviceType.MASTER);

            foreach(var device in list) {
                device.ungrab(Gdk.CURRENT_TIME);
            }
        #endif
    }

    /////////////////////////////////////////////////////////////////////
    /// Code roughly from Gnome-Do/Synapse.
    /////////////////////////////////////////////////////////////////////

    private static bool try_grab_window(Gdk.Window window) {
        #if HAVE_GTK_3_20
            // try again if window is not yet viewable
            if (!window.is_viewable()) return false;

            var seat = Gdk.Display.get_default().get_default_seat();
            var caps = Gdk.SeatCapabilities.POINTER | Gdk.SeatCapabilities.KEYBOARD;
            var result = seat.grab(window, caps, true, null, null, null);

            // for some reason GDK hides the window if the grab fails...
            if (result != Gdk.GrabStatus.SUCCESS) {
                window.show();
            }

            // continue trying to grab if it failed!
            return result == Gdk.GrabStatus.SUCCESS;
        #else
            var display = Gdk.Display.get_default();
            var manager = display.get_device_manager();

            bool grabbed_all = true;

            GLib.List<weak Gdk.Device?> list = manager.list_devices(Gdk.DeviceType.MASTER);

            foreach(var device in list) {
                var status = device.grab(window, Gdk.GrabOwnership.APPLICATION, true,
                                         Gdk.EventMask.ALL_EVENTS_MASK, null, Gdk.CURRENT_TIME);

                if (status != Gdk.GrabStatus.SUCCESS)
                    grabbed_all = false;
            }

            if (grabbed_all)
                return true;

            ungrab();

            return false;
        #endif
    }
}

}
