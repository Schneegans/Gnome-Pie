/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2021 Simon Schneegans
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
