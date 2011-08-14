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
        
        namespace Bookmarks {
            
            public void create(Pie pie, string name) {
            
            }
            
            public void get_bookmarks() {
                var bookmark_file = GLib.File.new_for_path(
                    GLib.Environment.get_home_dir()).get_child(".gtk-bookmarks");
                    
                if (!bookmark_file.query_exists()) {
                    warning("Failed to find file \".gtk-bookmarks\"!");
                    return;
                }
                
                string content = "";
                try {
                    bookmark_file.load_contents(null, out content);
                } catch (GLib.Error e) {
                    warning(e.message);
                }
                
                
            
            }
        }
        
    }
}
