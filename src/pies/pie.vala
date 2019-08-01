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
/// This class stores information on a pie. A pie consists of a name, an
/// icon name and an unique ID. Furthermore it has an arbitrary amount
/// of ActionGroups storing Actions.
/////////////////////////////////////////////////////////////////////////

public class Pie : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// The name of this Pie. It has not to be unique.
    /////////////////////////////////////////////////////////////////////

    public string name { get; set; }

    /////////////////////////////////////////////////////////////////////
    /// The name of the icon to be used for this Pie. It should exist in
    /// the users current icon theme, else a standard icon will be used.
    /////////////////////////////////////////////////////////////////////

    public string icon { get; set; }

    /////////////////////////////////////////////////////////////////////
    /// The ID of this Pie. It has to be unique among all Pies. This ID
    /// consists of three digits when the Pie was created by the user,
    /// of four digits when it was created dynamically by another class,
    /// for example by an ActionGroup.
    /////////////////////////////////////////////////////////////////////

    public string id { get; construct; }

    /////////////////////////////////////////////////////////////////////
    /// Stores all ActionGroups of this Pie.
    /////////////////////////////////////////////////////////////////////

    public Gee.ArrayList<ActionGroup?> action_groups { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all given members.
    /////////////////////////////////////////////////////////////////////

    public Pie(string id, string name, string icon) {
        GLib.Object(id: id, name: name, icon:icon);

        this.action_groups = new Gee.ArrayList<ActionGroup?>();
    }

    /////////////////////////////////////////////////////////////////////
    /// Should be called when this Pie is deleted, in order to clean up
    /// stuff created by contained ActionGroups.
    /////////////////////////////////////////////////////////////////////

    public virtual void on_remove() {
        foreach (var action_group in action_groups)
            action_group.on_remove();
    }

    /////////////////////////////////////////////////////////////////////
    /// Adds an Action to this Pie.
    /////////////////////////////////////////////////////////////////////

    public void add_action(Action action, int at_position = -1) {
        var group = new ActionGroup(this.id);
            group.add_action(action);
        this.add_group(group, at_position);
    }

    /////////////////////////////////////////////////////////////////////
    /// Adds an ActionGroup to this Pie.
    /////////////////////////////////////////////////////////////////////

    public void add_group(ActionGroup group, int at_position = -1) {
        if (group.has_quickaction()) {
            foreach (var action_group in action_groups)
                action_group.disable_quickactions();
        }

        if (at_position < 0 || at_position >= this.action_groups.size)
            this.action_groups.add(group);
        else
            this.action_groups.insert(at_position, group);
    }

    public void remove_group(int index) {
        if (this.action_groups.size > index)
            this.action_groups.remove_at(index);
    }

    public void move_group(int from, int to) {
        if (this.action_groups.size > from && this.action_groups.size > to) {
            var tmp = this.action_groups[from];
            this.remove_group(from);
            this.add_group(tmp, to);
        }
    }

    public void update_group(ActionGroup group, int index) {
        if (this.action_groups.size > index)
            this.action_groups.set(index, group);
    }
}

}

