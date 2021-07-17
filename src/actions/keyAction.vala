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

    public override void activate(uint32 time_stamp) {
        key.press();
    }
}

}
