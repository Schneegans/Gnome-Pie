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

// A base class for actions, which are executed when the user
// activates a pie's slice.

public abstract class Action : GLib.Object {

    public abstract string action_type { get; }
    public abstract string label { get; }
    public abstract string command { get; }

    public virtual string name {get; protected set;}
    public virtual string icon_name {get; protected set;}
    public virtual bool is_quick_action {get; protected set;}

    public Action(string name, string icon_name, bool is_quick_action) {
        this.name = name;
        this.icon_name = icon_name;
        this.is_quick_action = is_quick_action;
    }

    public abstract void activate();
    
    public virtual void on_display() {}
    public virtual void on_remove() {}
}

}
