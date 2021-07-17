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
// A base class storing a set of Actions. Derived classes may define
// how these Actions are created. This base class serves for custom
// actions, defined by the user.
/////////////////////////////////////////////////////////////////////////

public class ActionGroup : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// A list of all stored actions.
    /////////////////////////////////////////////////////////////////////

    public Gee.ArrayList<Action?> actions { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// The ID of the pie to which this group is attached.
    /////////////////////////////////////////////////////////////////////

    public string parent_id { get; construct set; }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public ActionGroup(string parent_id) {
        GLib.Object(parent_id : parent_id);
    }

    construct {
        this.actions = new Gee.ArrayList<Action?>();
    }

    /////////////////////////////////////////////////////////////////////
    /// This one is called, when the ActionGroup is deleted.
    /////////////////////////////////////////////////////////////////////

    public virtual void on_remove() {}

    /////////////////////////////////////////////////////////////////////
    /// This one is called, when the ActionGroup is saved.
    /////////////////////////////////////////////////////////////////////

    public virtual void on_save(Xml.TextWriter writer) {
        writer.write_attribute("type", GroupRegistry.descriptions[this.get_type().name()].id);
    }

    /////////////////////////////////////////////////////////////////////
    /// This one is called, when the ActionGroup is loaded.
    /////////////////////////////////////////////////////////////////////

    public virtual void on_load(Xml.Node* data) {}

    /////////////////////////////////////////////////////////////////////
    /// Adds a new Action to the group.
    /////////////////////////////////////////////////////////////////////

    public void add_action(Action new_action) {
       this.actions.add(new_action);
    }

    /////////////////////////////////////////////////////////////////////
    /// Removes all Actions from the group.
    /////////////////////////////////////////////////////////////////////

    public void delete_all() {
        actions.clear();
    }

    /////////////////////////////////////////////////////////////////////
    /// Makes all contained Slices no Quick Actions.
    /////////////////////////////////////////////////////////////////////

    public void disable_quickactions() {
        foreach (var action in actions) {
            action.is_quickaction = false;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns true, if one o the contained Slices is a Quick Action
    /////////////////////////////////////////////////////////////////////

    public bool has_quickaction() {
        foreach (var action in actions) {
            if (action.is_quickaction) {
                return true;
            }
        }

        return false;
    }
}

}
