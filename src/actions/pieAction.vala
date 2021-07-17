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
/// This Action opens another pie.
/////////////////////////////////////////////////////////////////////////

public class PieAction : Action {

    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of Action. It sets the display name
    /// for this Action, whether it has a custom Icon/Name and the string
    /// used in the pies.conf file for this kind of Actions.
    /////////////////////////////////////////////////////////////////////

    public static ActionRegistry.TypeDescription register() {
        var description = new ActionRegistry.TypeDescription();
        description.name = _("Open Pie");
        description.icon = "gnome-pie";
        description.description = _("Opens another Pie of Gnome-Pie. You may create sub menus this way.");
        description.icon_name_editable = false;
        description.id = "pie";
        return description;
    }

    /////////////////////////////////////////////////////////////////////
    /// Stores the ID of the referenced Pie.
    /////////////////////////////////////////////////////////////////////

    public override string real_command { get; construct set; }

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
            if (referee != null) {
                owned_name = "↪" + referee.name;
                return owned_name;
            }
            return "";
        }
        protected set {}
    }

    private string owned_name;

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

    public PieAction(string id, bool is_quickaction = false) {
        GLib.Object(name : "", icon : "", real_command : id, is_quickaction : is_quickaction);
    }

    /////////////////////////////////////////////////////////////////////
    /// Opens the desired Pie.
    /////////////////////////////////////////////////////////////////////

    public override void activate(uint32 time_stamp) {
        PieManager.open_pie(real_command);
    }
}

}
