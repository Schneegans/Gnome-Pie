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
/// This Action opens another pie.
/////////////////////////////////////////////////////////////////////////

public class PieAction : Action {

    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of Action. It sets the display name
    /// for this Action, whether it has a custom Icon/Name and the string
    /// used in the pies.conf file for this kind of Actions.
    /////////////////////////////////////////////////////////////////////

    public static void register(out string name, out bool icon_name_editable, out string settings_name) {
        name = _("Open Pie");
        icon_name_editable = false;
        settings_name = "pie";
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Stores the ID of the referenced Pie.
    /////////////////////////////////////////////////////////////////////

    public override string real_command { get; construct set;}
    
    
    /////////////////////////////////////////////////////////////////////
    /// Returns the name of the referenced Pie.
    /////////////////////////////////////////////////////////////////////
    
    public override string display_command { get {return name;} }
    
    
    /////////////////////////////////////////////////////////////////////
    /// Returns the name of the referenced Pie.
    /////////////////////////////////////////////////////////////////////
    
    public override string name {
        get {
            var referee = PieManager.all_pies[real_command];
            if (referee != null)
                return referee.name;
            return "";
        }
        protected set {}
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Returns the icon of the referenced Pie.
    /////////////////////////////////////////////////////////////////////
    
    public override string icon {
        get {
            var referee = PieManager.all_pies[real_command];
            if (referee != null)
                return referee.icon;
            return "";
        }
        protected set {}
    }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public PieAction(string id, bool is_quick_action = false) {
        GLib.Object(name : "", icon : "", real_command : id, is_quick_action : is_quick_action);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Opens the desired Pie.
    /////////////////////////////////////////////////////////////////////

    public override void activate() {
        PieManager.open_pie(real_command);
    } 
}

}
