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
/// This type of Action launches an application or a custom command.
/////////////////////////////////////////////////////////////////////////

public class AppAction : Action {

    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of Action. It sets the display name
    /// for this Action, whether it has a custom Icon/Name and the string
    /// used in the pies.conf file for this kind of Actions.
    /////////////////////////////////////////////////////////////////////

    public static void register(out string name, out bool icon_name_editable, out string settings_name) {
        name = _("Launch application");
        icon_name_editable = true;
        settings_name = "app";
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Stores the command line.
    /////////////////////////////////////////////////////////////////////

    public override string real_command { get; construct set; }
    
    
    /////////////////////////////////////////////////////////////////////
    /// Simply returns the real_command. No beautification.
    /////////////////////////////////////////////////////////////////////
    
    public override string display_command { get {return real_command;} }

    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public AppAction(string name, string icon, string command, bool is_quick_action = false) {
        GLib.Object(name : name, icon : icon, real_command : command, is_quick_action : is_quick_action);
    }

    /////////////////////////////////////////////////////////////////////
    /// Launches the desired command.
    /////////////////////////////////////////////////////////////////////

    public override void activate() {
        try{
            var item = GLib.AppInfo.create_from_commandline(this.real_command, null, GLib.AppInfoCreateFlags.NONE);
            item.launch(null, null);
    	} catch (Error e) {
	        warning(e.message);
        }
    } 
}

}
