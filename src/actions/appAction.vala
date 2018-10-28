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

/////////////////////////////////////////////////////////////////////////
/// This type of Action launches an application or a custom command.
/////////////////////////////////////////////////////////////////////////

public class AppAction : Action {

    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of Action. It sets the display name
    /// for this Action, whether it has a custom Icon/Name and the string
    /// used in the pies.conf file for this kind of Actions.
    /////////////////////////////////////////////////////////////////////

    public static ActionRegistry.TypeDescription register() {
        var description = new ActionRegistry.TypeDescription();
        description.name = _("Launch application");
        description.icon = "application-x-executable";
        description.description = _("Executes the given command.");
        description.icon_name_editable = true;
        description.id = "app";
        return description;
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

    public AppAction(string name, string icon, string command, bool is_quickaction = false) {
        GLib.Object(name : name, icon : icon, real_command : command, is_quickaction : is_quickaction);
    }

    /////////////////////////////////////////////////////////////////////
    /// Launches the desired command.
    /////////////////////////////////////////////////////////////////////

    public override void activate(uint32 time_stamp) {
        try{
            var item = GLib.AppInfo.create_from_commandline(this.real_command, null, GLib.AppInfoCreateFlags.NONE);
            item.launch(null, null);
        } catch (Error e) {
            warning(e.message);
        }
    }
}

}
