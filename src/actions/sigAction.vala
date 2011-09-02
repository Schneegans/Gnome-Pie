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
/// This type of Action can't be selected by the user, therefore there is
/// no register() method for this class. But it may be useful for
/// ActionGroups: It emits a signal on activation.
/////////////////////////////////////////////////////////////////////////

public class SigAction : Action {

    /////////////////////////////////////////////////////////////////////
    /// This signal is emitted on activation.
    /////////////////////////////////////////////////////////////////////

    public signal void activated();

    
    /////////////////////////////////////////////////////////////////////
    /// This may store something useful.
    /////////////////////////////////////////////////////////////////////

    public override string real_command { get; construct set; }
    
    
    /////////////////////////////////////////////////////////////////////
    /// Only for inheritance... Greetings to Liskov.
    /////////////////////////////////////////////////////////////////////
    
    public override string display_command { get {return real_command;} }

    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public SigAction(string name, string icon, string command, bool is_quick_action = false) {
        GLib.Object(name : name, icon : icon, real_command : command, is_quick_action : is_quick_action);
    }

    /////////////////////////////////////////////////////////////////////
    /// Emits the signal on activation.
    /////////////////////////////////////////////////////////////////////

    public override void activate() {
        this.activated();
    } 
}

}
