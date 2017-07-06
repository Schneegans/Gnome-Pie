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
/// This type of Action opens the default application for an URI.
/////////////////////////////////////////////////////////////////////////

public class UriAction : Action {

    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of Action. It sets the display name
    /// for this Action, whether it has a custom Icon/Name and the string
    /// used in the pies.conf file for this kind of Actions.
    /////////////////////////////////////////////////////////////////////

    public static ActionRegistry.TypeDescription register() {
        var description = new ActionRegistry.TypeDescription();
        description.name = _("Open URI");
        description.icon = "web-browser";
        description.description = _("Opens a given location. You may use URL's or files paths.");
        description.icon_name_editable = true;
        description.id = "uri";
        return description;
    }

    /////////////////////////////////////////////////////////////////////
    /// The URI of this Action.
    /////////////////////////////////////////////////////////////////////

    public override string real_command { get; construct set; }

    /////////////////////////////////////////////////////////////////////
    /// Returns only the real URI. An URI can't be beautified.
    /////////////////////////////////////////////////////////////////////

    public override string display_command { get {return real_command;} }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public UriAction(string name, string icon, string command, bool is_quickaction = false) {
        GLib.Object(name : name, icon : icon,
                    real_command : command.has_prefix("www") ? "http://" + command : command,
                    is_quickaction : is_quickaction);
    }

    /////////////////////////////////////////////////////////////////////
    /// Opens the default application for the URI.
    /////////////////////////////////////////////////////////////////////

    public override void activate(uint32 time_stamp) {
        try{
            GLib.AppInfo.launch_default_for_uri(real_command, null);
        } catch (Error e) {
            warning(e.message);
        }
    }
}

}
