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

public class BookmarkGroup : ActionGroup {

    public override bool is_custom { get {return false;} }
    public override string group_type { get {return _("Bookmarks");} }
    public override string icon_name { get {return "user-bookmarks";} }

    private bool changing = false;
    private bool changed_again = false;
    
    public BookmarkGroup(string parent_id) {
        base(parent_id);
        this.load();
        
        // add monitor
        var bookmark_file = GLib.File.new_for_path(
            GLib.Environment.get_home_dir()).get_child(".gtk-bookmarks");
            
        if (bookmark_file.query_exists()) {
            try {
                var monitor = bookmark_file.monitor(GLib.FileMonitorFlags.NONE);
                monitor.changed.connect(this.reload);
            } catch (GLib.Error e) {
                warning(e.message);
            }
        }
    }
    
    private void load() {
        // add home folder
        this.add_action(Action.new_for_uri("file://" + GLib.Environment.get_home_dir()));
        
        // add .gtk-bookmarks
        var bookmark_file = GLib.File.new_for_path(
            GLib.Environment.get_home_dir()).get_child(".gtk-bookmarks");
            
        if (!bookmark_file.query_exists()) {
            warning("Failed to find file \".gtk-bookmarks\"!");
            return;
        }
        
        try {
            var dis = new DataInputStream(bookmark_file.read ());
            string line;
            while ((line = dis.read_line(null)) != null) {
                var parts = line.split(" ");
                
                string uri = parts[0];
                string name = parts[1];

                this.add_action(Action.new_for_uri(uri, name));
            }
        } catch (Error e) {
            error ("%s", e.message);
        }
        
        // add trash
        this.add_action(Action.new_for_uri("trash:///"));
        
        // add desktop
        this.add_action(Action.new_for_uri("file://" + GLib.Environment.get_user_special_dir(GLib.UserDirectory.DESKTOP)));
    }
    
    private void reload() {
        // avoid too frequent changes...
        if (!this.changing) {
            this.changing = true;
            Timeout.add(200, () => {
                if (this.changed_again) {
                    this.changed_again = false;
                    return true;
                }

                message("Bookmarks changed...");
                this.delete_all();
                this.load();
                
                this.changing = false;
                return false;
            });
        } else {
            this.changed_again = true;
        }    
    }
}

}
