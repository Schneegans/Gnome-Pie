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

// An ActionGroup which displays the user's main menu.
        
public class MenuGroup : ActionGroup {
    
    private GMenu.Tree menu = null;
    private Gee.ArrayList<MenuGroup?> childs;
    private bool is_toplevel = false;
    
    public void load(string parent_name, GMenu.TreeDirectory? dir = null) {
    
        this.childs = new Gee.ArrayList<MenuGroup?>();
    
        if (dir == null) {
            is_toplevel = true;
        
            this.menu = GMenu.Tree.lookup ("applications.menu", GMenu.TreeFlags.INCLUDE_EXCLUDED);
            
            this.menu.add_monitor(this.on_change);
            
            dir = this.menu.get_root_directory();
        } else {
            this.add_action(new PieAction(_("BACK"), "back", parent_name));
        }

        foreach (var item in dir.get_contents()) {
            switch(item.get_type()) {
            
                case GMenu.TreeItemType.DIRECTORY:
                    var sub_menu_name = pie_name + (GMenu.TreeDirectory)item.get_name();
                
                    var sub_menu = PieManager.add_pie(sub_menu_name,
                                                      (GMenu.TreeDirectory)item.get_icon());
                    var group = new MenuGroup();
                    group.load(sub_menu_name, (GMenu.TreeDirectory)item);
                    childs.add(group);
                                                      
                    sub_menu.add_group(group);
                    
                    this.add_action(new PieAction(sub_menu_name));  
                    break;
                    
                case GMenu.TreeItemType.ENTRY:
                    this.add_action(new AppAction((GMenu.TreeEntry)(entry).get_name(), 
                                                  (GMenu.TreeEntry)(entry).get_icon(), 
                                                  (GMenu.TreeEntry)(entry).get_exec()));  
                    break;
            }
        }
        
        private void on_change() {
            this.menu.remove_monitor(this.on_change);
            this.clear();
            this.load(this.pie_name);
        }
        
        private void clear() {
            foreach (child in childs)
                child.clear();

            if (!this.is_toplevel)
                PieManager.remove_pie(this.pie_name);
            
            this.childs.clear();
            this.menu = null;
        }
    }
    
}

}
