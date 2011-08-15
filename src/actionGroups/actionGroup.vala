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
	
// A abstract base class storing a set of Actions. Derived classes may define
// how these Actions are created.

public abstract class ActionGroup {
    
    public Gee.ArrayList<Action?> actions {get; private set;}
    
    public ActionGroup() {
        this.actions = new Gee.ArrayList<Slice?>();
    }
    
    protected void add_action(Action new_action) {
       this. actions.add(new_action);
    }
    
    protected void delete_by_name(string name) {
        this.delete_by_position(get_position(name));
    }
    
    protected void delete_by_position(int pos) {
        if (pos >= 0 && pos < actions.size()) this.actions.remove_at(pos);
        else warning("Failed to delete an Action: Index out of bounds!");
    }
    
    protected void swap_by_name(string name1, string name2) {
        this.swap_by_position(this.get_position(name1), this.get_position(name2));
    }
    
    protected void swap_by_position(int pos1, int pos2) {
        if ((pos1 >= 0 && pos1 < actions.size()) || (pos2 >= 0 && pos2 < actions.size())) {
            warning("Failed to swap Actions: Index out of bounds!");
            return;
        }
    
        var tmp = this.actions[pos1];
        this.actions[pos1] = this.actions[pos2];
        this.actions[pos2] = tmp;
    }
    
    private int get_position(string name) {
        for (int i=0; i<this.actions.size(); ++i) 
            if (this.actions[i].name == name) 
                return i;
        
        return -1;
    }
    
}

}
