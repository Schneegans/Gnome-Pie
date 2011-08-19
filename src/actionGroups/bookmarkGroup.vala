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
        this.add_uri("file://" + GLib.Environment.get_home_dir());
        
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

                this.add_uri(uri, name);
            }
        } catch (Error e) {
            error ("%s", e.message);
        }
        
        // add desktop
        this.add_uri("trash:///");
        
        // add trash
        this.add_uri("file://" + GLib.Environment.get_user_special_dir(GLib.UserDirectory.DESKTOP));
    }
    
    private void add_uri(string uri, string? name = null, string? icon = null) {
        string? final_name = name;
        string? final_icon = icon;
    
        // if no name is specified, use basename
        if (final_name == null) {
            if (uri.has_prefix("trash")) {
                final_name = _("Trash");
            } else {
                final_name = GLib.Path.get_basename(uri);
            } 
        }
        
        // if no icon is specified, try to find a good one   
        if (final_icon == null) {
            if (uri.has_prefix("ftp") || uri.has_prefix("sftp")) {
                final_icon = "folder-remote";
            } else if (uri.has_prefix("trash")) {
                final_icon = "user-trash";
            } else if (final_name == GLib.Path.get_basename(GLib.Environment.get_user_special_dir(GLib.UserDirectory.DESKTOP))) {
                final_icon = "user-desktop";
            } else if (final_name == GLib.Path.get_basename(GLib.Environment.get_user_special_dir(GLib.UserDirectory.DOCUMENTS))) {
                final_icon = "folder-documents";
            } else if (final_name == GLib.Path.get_basename(GLib.Environment.get_user_special_dir(GLib.UserDirectory.DOWNLOAD))) {
                final_icon = "folder-download";
            } else if (final_name == GLib.Path.get_basename(GLib.Environment.get_user_special_dir(GLib.UserDirectory.MUSIC))) {
                final_icon = "folder-music";
            } else if (final_name == GLib.Path.get_basename(GLib.Environment.get_user_special_dir(GLib.UserDirectory.PICTURES))) {
                final_icon = "folder-pictures";
            } else if (final_name == GLib.Path.get_basename(GLib.Environment.get_user_special_dir(GLib.UserDirectory.PUBLIC_SHARE))) {
                final_icon = "folder-publicshare";
            } else if (final_name == GLib.Path.get_basename(GLib.Environment.get_user_special_dir(GLib.UserDirectory.TEMPLATES))) {
                final_icon = "folder-templates";
            } else if (final_name == GLib.Path.get_basename(GLib.Environment.get_user_special_dir(GLib.UserDirectory.VIDEOS))) {
                final_icon = "folder-videos";
            } else {
                final_icon = "folder";
            }
            
            if (!Gtk.IconTheme.get_default().has_icon(final_icon))
                final_icon = "folder";
        }
        
        this.add_action(new UriAction(final_name, final_icon, uri));
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
