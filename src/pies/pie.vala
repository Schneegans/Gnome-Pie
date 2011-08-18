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

// This class stores information on a pie. A pie consists of a name, an icon_name
// and an unique ID. Furthermore it has a "quick_action", which describes the
// action to be executed when the user clicks on the center of a pie.

public class Pie {
    
    public string name {get; private set;}
    public string icon_name {get; private set;}
    public string id {get; private set;}
    public int quick_action {get; private set;}
    public Gee.ArrayList<ActionGroup?> action_groups {get; private set;}
    
    public Pie(string id, string name, string icon_name, int quick_action) {
        this.id = id;
        this.name = name;
        this.icon_name = icon_name;
        this.quick_action = quick_action;
        this.action_groups = new Gee.ArrayList<ActionGroup?>();
    }
    
    public virtual void on_display() {
        foreach (var action_group in action_groups)
            action_group.on_display();
    }
    
    public void add_group(ActionGroup group) {
        this.action_groups.add(group);
    }
    
    public int action_count() {
        int count = 0;
        foreach (var group in action_groups)
            count += group.actions.size;
        return count;
    }
}

}

