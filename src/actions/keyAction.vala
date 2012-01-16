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
/// This type of Action "presses" a key stroke.
/////////////////////////////////////////////////////////////////////////

public class KeyAction : Action {

    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of Action. It sets the display name
    /// for this Action, whether it has a custom Icon/Name and the string
    /// used in the pies.conf file for this kind of Actions.
    /////////////////////////////////////////////////////////////////////

    public static ActionRegistry.TypeDescription register() {
        var description = new ActionRegistry.TypeDescription();
        description.name = _("Press hotkey");
        description.icon = "preferences-desktop-keyboard-shortcuts";
        description.description = _("Simulates the activation of a hotkey.");
        description.icon_name_editable = true;
        description.id = "key";
        return description;
    }   
    
    /////////////////////////////////////////////////////////////////////
    /// Stores the accelerator of this action.
    /////////////////////////////////////////////////////////////////////
    
    public override string real_command { get; construct set; }
    
    /////////////////////////////////////////////////////////////////////
    /// Returns a human readable form of the accelerator.
    /////////////////////////////////////////////////////////////////////
    
    public override string display_command { get {return key.label;} }
    
    /////////////////////////////////////////////////////////////////////
    /// The simulated key which gets 'pressed' on execution.
    /////////////////////////////////////////////////////////////////////
    
    public Key key { get; set; }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public KeyAction(string name, string icon, string command, bool is_quickaction = false) {
        GLib.Object(name : name, icon : icon, real_command : command, is_quickaction : is_quickaction);
    }
    
    construct {
        this.key = new Key.from_string(real_command);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Presses the desired key.
    /////////////////////////////////////////////////////////////////////

    public override void activate() {
        key.press();
    }
}

}
