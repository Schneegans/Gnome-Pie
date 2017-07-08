/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2017 by Simon Schneegans
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// A group of Actions, which represent the users gtk-bookmarks, his home
/// directory, desktop and trash. It stay up-to-date, even if the
/// bookmarks change.
/////////////////////////////////////////////////////////////////////////

public class BookmarkGroup : ActionGroup {

    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of ActionGroup. It sets the display
    /// name for this ActionGroup, it's icon name and the string used in
    /// the pies.conf file for this kind of ActionGroups.
    /////////////////////////////////////////////////////////////////////

    public static GroupRegistry.TypeDescription register() {
        var description = new GroupRegistry.TypeDescription();
        description.name = _("Group: Bookmarks");
        description.icon = "user-bookmarks";
        description.description = _("Shows a Slice for each of your directory Bookmarks.");
        description.id = "bookmarks";
        return description;
    }

    /////////////////////////////////////////////////////////////////////
    /// Two members needed to avoid useless, frequent changes of the
    /// stored Actions.
    /////////////////////////////////////////////////////////////////////

    private bool changing = false;
    private bool changed_again = false;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public BookmarkGroup(string parent_id) {
        GLib.Object(parent_id : parent_id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Construct block loads the bookmarks of the user and adds a file
    /// monitor in order to update the BookmarkGroup when the bookmarks
    /// of the user change.
    /////////////////////////////////////////////////////////////////////

    construct {
        this.load();

        var bookmarks_file = get_bookmarks_file();

        // add monitor
        if (bookmarks_file != null) {
            try {
                var monitor = bookmarks_file.monitor(GLib.FileMonitorFlags.NONE);
                monitor.changed.connect(this.reload);
            } catch (GLib.Error e) {
                warning(e.message);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns either ~/.gtk-bookmarks or ~/.config/gtk-3.0/bookmarks
    /////////////////////////////////////////////////////////////////////

    private GLib.File? get_bookmarks_file() {
        var bookmarks_file = GLib.File.new_for_path(
            GLib.Environment.get_home_dir()).get_child(".gtk-bookmarks");

        if (bookmarks_file.query_exists()) return bookmarks_file;
            
        bookmarks_file = GLib.File.new_for_path(
            GLib.Environment.get_home_dir()).get_child(".config/gtk-3.0/bookmarks");

        if (bookmarks_file.query_exists()) return bookmarks_file;

        return null;
    }

    /////////////////////////////////////////////////////////////////////
    /// Adds Actions for each gtk-bookmark of the user and for his home
    /// folder, desktop and trash.
    /////////////////////////////////////////////////////////////////////

    private void load() {
        // add home folder
        this.add_action(ActionRegistry.new_for_uri("file://" + GLib.Environment.get_home_dir()));

        // add bookmarks
        var bookmarks_file = get_bookmarks_file();

        if (bookmarks_file == null) {
            warning("Failed to find bookmarks file!");
            return;
        }

        try {
            var dis = new DataInputStream(bookmarks_file.read());
            string line;
            while ((line = dis.read_line(null)) != null) {
                var parts = line.split(" ");

                string uri = parts[0];
                string name = parts[1];

                this.add_action(ActionRegistry.new_for_uri(uri, name));
            }
        } catch (Error e) {
            error ("%s", e.message);
        }

        // add trash
        this.add_action(ActionRegistry.new_for_uri("trash://"));

        // add desktop
        this.add_action(ActionRegistry.new_for_uri("file://" + GLib.Environment.get_user_special_dir(GLib.UserDirectory.DESKTOP)));
    }

    /////////////////////////////////////////////////////////////////////
    /// Reloads all Bookmarks. Is called when the user's gtk-bookmarks
    /// file changes.
    /////////////////////////////////////////////////////////////////////

    private void reload() {
        // avoid too frequent changes...
        if (!this.changing) {
            this.changing = true;
            Timeout.add(200, () => {
                if (this.changed_again) {
                    this.changed_again = false;
                    return true;
                }

                // reload
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
