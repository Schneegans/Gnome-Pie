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
    
    public static void register(out string name, out string icon, out string settings_name) {
        name = _("Main menu");
        icon = "gnome-main-menu";
        settings_name = "menu";
    }
    
    public bool is_toplevel {get; construct set; default = true;}
    private GMenu.Tree menu = null;
    private Gee.ArrayList<MenuGroup?> childs;
    private bool changing = false;
    private bool changed_again = false;
    
    public MenuGroup(string parent_id) {
        GLib.Object(parent_id : parent_id, is_toplevel : true);
    }
    
    public MenuGroup.sub_menu(string parent_id) {
        GLib.Object(parent_id : parent_id, is_toplevel : false);
    }
    
    construct {
        this.childs = new Gee.ArrayList<MenuGroup?>();

        if (this.is_toplevel) {
            this.load_toplevel();
        } 
    }
    
    private void load_toplevel() {
        this.menu = GMenu.Tree.lookup ("applications.menu", GMenu.TreeFlags.INCLUDE_EXCLUDED);
        this.menu.add_monitor(this.reload);
        
        var dir = this.menu.get_root_directory();

        this.load_contents(dir, this.parent_id);
    }
    
    // parse the main menu recursively
    private void load_contents(GMenu.TreeDirectory dir, string parent_id) {
        foreach (var item in dir.get_contents()) {
            switch(item.get_type()) {
                case GMenu.TreeItemType.DIRECTORY:
                    if (!((GMenu.TreeDirectory)item).get_is_nodisplay()) {
                        var sub_menu = PieManager.add_dynamic_pie(
                                                          ((GMenu.TreeDirectory)item).get_name(),
                                                          ((GMenu.TreeDirectory)item).get_icon());
                        var group = new MenuGroup.sub_menu(sub_menu.id);
                        group.add_action(new PieAction(parent_id, true));
                        group.load_contents((GMenu.TreeDirectory)item, sub_menu.id);
                        childs.add(group);
                                                          
                        sub_menu.add_group(group);
                        
                        this.add_action(new PieAction(sub_menu.id)); 
                    } 
                    break;
                    
                case GMenu.TreeItemType.ENTRY:
                    if (!((GMenu.TreeEntry)item).get_is_nodisplay() && !((GMenu.TreeEntry)item).get_is_excluded()) {
                        this.add_action(new AppAction(((GMenu.TreeEntry)item).get_name(), 
                                                      ((GMenu.TreeEntry)item).get_icon(), 
                                                      ((GMenu.TreeEntry)item).get_exec())); 
                    } 
                    break;
            }
        }
    }
    
     private void reload() {
        // avoid too frequent changes...
        if (!this.changing) {
            this.changing = true;
            Timeout.add(500, () => {
                if (this.changed_again) {
                    this.changed_again = false;
                    return true;
                }

                message("Main menu changed...");
                this.menu.remove_monitor(this.reload);
                this.clear();
                this.load_toplevel();
                
                this.changing = false;
                return false;
            });
        } else {
            this.changed_again = true;
        }  
    }
    
    public override void on_remove() {
        if (this.is_toplevel)
            this.clear();
    }
    
    private void clear() {
        foreach (var child in childs)
            child.clear();

        if (!this.is_toplevel)
            PieManager.remove_pie(this.parent_id);
            
        this.delete_all();
        
        this.childs.clear();
        this.menu = null;
    }
}

}
