/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2015 by Simon Schneegans
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
/// A which has knowledge on all possible acion group types.
/////////////////////////////////////////////////////////////////////////

public class GroupRegistry : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// A list containing all available ActionGroup types.
    /////////////////////////////////////////////////////////////////////

    public static Gee.ArrayList<string> types { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// A map associating a displayable name for each ActionGroup,
    /// an icon name and a name for the pies.conf file with it's type.
    /////////////////////////////////////////////////////////////////////

    public static Gee.HashMap<string, TypeDescription?> descriptions { get; private set; }

    public class TypeDescription {
        public string name { get; set; default=""; }
        public string icon { get; set; default=""; }
        public string description { get; set; default=""; }
        public string id { get; set; default=""; }
    }

    /////////////////////////////////////////////////////////////////////
    /// Registers all ActionGroup types.
    /////////////////////////////////////////////////////////////////////

    public static void init() {
        types = new Gee.ArrayList<string>();
        descriptions = new Gee.HashMap<string, TypeDescription?>();

        TypeDescription type_description;

        type_description = BookmarkGroup.register();
        types.add(typeof(BookmarkGroup).name());
        descriptions.set(typeof(BookmarkGroup).name(), type_description);

        type_description = ClipboardGroup.register();
        types.add(typeof(ClipboardGroup).name());
        descriptions.set(typeof(ClipboardGroup).name(), type_description);

        type_description = DevicesGroup.register();
        types.add(typeof(DevicesGroup).name());
        descriptions.set(typeof(DevicesGroup).name(), type_description);

        type_description = MenuGroup.register();
        types.add(typeof(MenuGroup).name());
        descriptions.set(typeof(MenuGroup).name(), type_description);

        type_description = SessionGroup.register();
        types.add(typeof(SessionGroup).name());
        descriptions.set(typeof(SessionGroup).name(), type_description);

        type_description = WindowListGroup.register();
        types.add(typeof(WindowListGroup).name());
        descriptions.set(typeof(WindowListGroup).name(), type_description);

        type_description = WorkspaceWindowListGroup.register();
        types.add(typeof(WorkspaceWindowListGroup).name());
        descriptions.set(typeof(WorkspaceWindowListGroup).name(), type_description);
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a Group for a given type name.
    /////////////////////////////////////////////////////////////////////

    public static ActionGroup? create_group(string type_id, string parent_id) {
        switch (type_id) {
            case "bookmarks":
                return new BookmarkGroup(parent_id);
            case "clipboard":
                return new ClipboardGroup(parent_id);
            case "devices":
                return new DevicesGroup(parent_id);
            case "menu":
                return new MenuGroup(parent_id);
            case "session":
                return new SessionGroup(parent_id);
            case "window_list":
                return new WindowListGroup(parent_id);
            case "workspace_window_list":
                return new WorkspaceWindowListGroup(parent_id);
        }

        return null;
    }
}

}
