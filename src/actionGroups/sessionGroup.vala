/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2018 Simon Schneegans
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

/////////////////////////////////////////////////////////////////////
/// An ActionGroup which has three Actions: Logout, Shutdown and
/// Reboot.
/////////////////////////////////////////////////////////////////////

public class SessionGroup : ActionGroup {

    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of ActionGroup. It sets the display
    /// name for this ActionGroup, it's icon name and the string used in
    /// the pies.conf file for this kind of ActionGroups.
    /////////////////////////////////////////////////////////////////////

    public static GroupRegistry.TypeDescription register() {
        var description = new GroupRegistry.TypeDescription();
        description.name = _("Group: Session Control");
        description.icon = "system-log-out";
        description.description = _("Shows a Slice for Shutdown, Reboot, and Hibernate.");
        description.id = "session";
        return description;
    }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public SessionGroup(string parent_id) {
        GLib.Object(parent_id : parent_id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Construct block adds the three Actions.
    /////////////////////////////////////////////////////////////////////

    construct {
//        string iface = GLib.Bus.get_proxy_sync(GLib.BusType.SESSION, "org.gnome.SessionManager", "/org/gnome/SessionManager");
//        iface = GLib.Bus.get_proxy_sync(GLib.BusType.SESSION, "org.freedesktop.Hal", "/org/freedesktop/Hal/devices/computer");
//        iface = GLib.Bus.get_proxy_sync(GLib.BusType.SESSION, "org.kde.ksmserver", "/KSMServer");
//        iface = GLib.Bus.get_proxy_sync(GLib.BusType.SESSION, "org.freedesktop.ConsoleKit", "/org/freedesktop/ConsoleKit/Manager");

        this.add_action(new AppAction(_("Shutdown"), "system-shutdown",
            "dbus-send --print-reply --dest=org.gnome.SessionManager /org/gnome/SessionManager org.gnome.SessionManager.Shutdown"));

        this.add_action(new AppAction(_("Logout"), "system-log-out",
            "dbus-send --print-reply --dest=org.gnome.SessionManager /org/gnome/SessionManager org.gnome.SessionManager.Logout uint32:1"));

        this.add_action(new AppAction(_("Reboot"), "view-refresh",
            "dbus-send --print-reply --dest=org.gnome.SessionManager /org/gnome/SessionManager org.gnome.SessionManager.Reboot"));
    }

    // TODO: check for available interfaces --- these may work too:
    // dbus-send --print-reply --dest=org.freedesktop.Hal /org/freedesktop/Hal/devices/computer org.freedesktop.Hal.Device.SystemPowerManagement.Shutdown
    // dbus-send --print-reply --dest=org.kde.ksmserver /KSMServer org.kde.KSMServerInterface.logout 0 2 2
    // dbus-send --print-reply --dest="org.freedesktop.ConsoleKit" /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Stop
}

}
