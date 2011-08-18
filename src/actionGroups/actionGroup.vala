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
	
// A base class storing a set of Actions. Derived classes may define
// how these Actions are created.

public class ActionGroup {
    
    public Gee.ArrayList<Action?> actions {get; private set;}
    
    public string parent_id {get; private set;}
    
    public ActionGroup(string parent_id) {
        this.parent_id = parent_id;
        this.actions = new Gee.ArrayList<Action?>();
    }
    
    public virtual void on_display() {
        foreach (var action in actions)
            action.on_display();
    }
    
    public void add_action(Action new_action) {
       this.actions.add(new_action);
    }
    
    public void delete_by_name(string name) {
        this.delete_by_position(get_position(name));
    }
    
    public void delete_by_position(int pos) {
        if (pos >= 0 && pos < this.actions.size) this.actions.remove_at(pos);
        else warning("Failed to delete an Action: Index out of bounds!");
    }
    
    public void swap_by_name(string name1, string name2) {
        this.swap_by_position(this.get_position(name1), this.get_position(name2));
    }
    
    public void swap_by_position(int pos1, int pos2) {
        if ((pos1 >= 0 && pos1 < this.actions.size) || (pos2 >= 0 && pos2 < this.actions.size)) {
            warning("Failed to swap Actions: Index out of bounds!");
            return;
        }
    
        var tmp = this.actions[pos1];
        this.actions[pos1] = this.actions[pos2];
        this.actions[pos2] = tmp;
    }
    
    public int get_position(string name) {
        for (int i=0; i<this.actions.size; ++i) 
            if (this.actions[i].name == name) 
                return i;
        
        return -1;
    }
    
    public void delete_all() {
        actions.clear();
    }
    
}

}
