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
/// A base class for actions, which are executed when the user
/// activates a pie's slice.
/////////////////////////////////////////////////////////////////////////

public abstract class Action : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// The command which gets executed when user activates the Slice.
    /// It may be anything but has to be representable with a string.
    /////////////////////////////////////////////////////////////////////

    public abstract string real_command { get; construct set; }

    /////////////////////////////////////////////////////////////////////
    /// The command displayed to the user. It should be a bit more
    /// beautiful than the real_command.
    /////////////////////////////////////////////////////////////////////

    public abstract string display_command { get; }

    /////////////////////////////////////////////////////////////////////
    /// The name of the Action.
    /////////////////////////////////////////////////////////////////////

    public virtual string name { get; set; }

    /////////////////////////////////////////////////////////////////////
    /// The name of the icon of this Action. It should be in the users
    /// current icon theme.
    /////////////////////////////////////////////////////////////////////

    public virtual string icon { get; set; }

    /////////////////////////////////////////////////////////////////////
    /// True, if this Action is the quickAction of the associated Pie.
    /// The quickAction of a Pie gets executed when the users clicks on
    /// the center of a Pie.
    /////////////////////////////////////////////////////////////////////

    public virtual bool is_quickaction { get; set; }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public Action(string name, string icon, bool is_quickaction) {
        GLib.Object(name : name, icon : icon, is_quickaction : is_quickaction);
    }

    /////////////////////////////////////////////////////////////////////
    /// This one is called, when the user activates the Slice.
    /////////////////////////////////////////////////////////////////////

    public abstract void activate(uint32 time_stamp);
}

}
