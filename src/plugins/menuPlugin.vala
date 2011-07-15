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
	
    namespace Plugins {
        
        namespace Menu {
            
            public void create(string name, string hotkey) {
                var main = new Pie(hotkey);

                var tree = GMenu.Tree.lookup ("applications.menu", GMenu.TreeFlags.INCLUDE_EXCLUDED);
                var root = tree.get_root_directory();

                parse_directory(root, main, name);

                var manager = new PieManager();
	            manager.add_pie(name, main);
            }
            
            private void parse_directory(GMenu.TreeDirectory dir, Pie pie, string parent_name) {
                foreach (var item in dir.get_contents()) {
                    switch(item.get_type()) {
                        case GMenu.TreeItemType.DIRECTORY:
                            pie.add_slice(get_submenu((GMenu.TreeDirectory)item, pie, parent_name));
                            break;
                        case GMenu.TreeItemType.ENTRY:
                            pie.add_slice(get_action((GMenu.TreeEntry)item));
                            break;
                    }
                }
            }
            
            public PieAction get_submenu(GMenu.TreeDirectory dir, Pie parent, string parent_name) {
                var sub_menu = new Pie("");
                sub_menu.add_slice(new PieAction("BACK", "back", parent_name));
                parse_directory(dir, sub_menu, parent_name+dir.get_name());
                
                var manager = new PieManager();
	            manager.add_pie(parent_name+dir.get_name(), sub_menu);

                return new PieAction(dir.get_name().up(), dir.get_icon(), parent_name+dir.get_name()); 
            }

            public AppAction get_action(GMenu.TreeEntry entry) {
                return new AppAction(entry.get_name(), entry.get_icon(), entry.get_exec()); 
            }
        }
    }
}
