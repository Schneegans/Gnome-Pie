/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2021 Simon Schneegans
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
    /// Used to track changes in the bookmarks file.
    /////////////////////////////////////////////////////////////////////

    private GLib.FileMonitor monitor = null;

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
                this.monitor = bookmarks_file.monitor(GLib.FileMonitorFlags.NONE);
                this.monitor.set_rate_limit(500);
                this.monitor.changed.connect((file, other, type) => {
                    if(type == GLib.FileMonitorEvent.CHANGES_DONE_HINT) {
                        this.delete_all();
                        this.load();
                    }
                });
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

                string uri = line;
                string name = null;

                int first_space = line.index_of(" ");
                if (first_space > 0) {
                    uri = line.slice(0, first_space);
                    name = line.slice(first_space+1, line.length);
                }

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
}

}
