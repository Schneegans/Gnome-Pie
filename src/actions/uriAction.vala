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
