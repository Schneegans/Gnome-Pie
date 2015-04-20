/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2015 by Simon Schneegans
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
