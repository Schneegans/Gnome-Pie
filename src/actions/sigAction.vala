/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2019 Simon Schneegans
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
/// This type of Action can't be selected by the user, therefore there is
/// no register() method for this class. But it may be useful for
/// ActionGroups: It emits a signal on activation.
/////////////////////////////////////////////////////////////////////////

public class SigAction : Action {

    /////////////////////////////////////////////////////////////////////
    /// This signal is emitted on activation.
    /////////////////////////////////////////////////////////////////////

    public signal void activated(uint32 time_stamp);

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

    public SigAction(string name, string icon, string command, bool is_quickaction = false) {
        GLib.Object(name : name, icon : icon, real_command : command, is_quickaction : is_quickaction);
    }

    /////////////////////////////////////////////////////////////////////
    /// Emits the signal on activation.
    /////////////////////////////////////////////////////////////////////

    public override void activate(uint32 time_stamp) {
        this.activated(time_stamp);
    }
}

}
