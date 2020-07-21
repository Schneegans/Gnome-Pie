/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2019 Simon Schneegans
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
        if (type_description != null) {
            types.add(typeof(BookmarkGroup).name());
            descriptions.set(typeof(BookmarkGroup).name(), type_description);
        }

        type_description = ClipboardGroup.register();
        if (type_description != null) {
            types.add(typeof(ClipboardGroup).name());
            descriptions.set(typeof(ClipboardGroup).name(), type_description);
        }

        type_description = DevicesGroup.register();
        if (type_description != null) {
            types.add(typeof(DevicesGroup).name());
            descriptions.set(typeof(DevicesGroup).name(), type_description);
        }

        type_description = MenuGroup.register();
        if (type_description != null) {
            types.add(typeof(MenuGroup).name());
            descriptions.set(typeof(MenuGroup).name(), type_description);
        }

        type_description = SessionGroup.register();
        if (type_description != null) {
            types.add(typeof(SessionGroup).name());
            descriptions.set(typeof(SessionGroup).name(), type_description);
        }

        type_description = WindowListGroup.register();
        if (type_description != null) {
            types.add(typeof(WindowListGroup).name());
            descriptions.set(typeof(WindowListGroup).name(), type_description);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a Group for a given type name.
    /////////////////////////////////////////////////////////////////////

    public static ActionGroup? create_group(string type_id, string parent_id) {
        bool wayland = GLib.Environment.get_variable("XDG_SESSION_TYPE") == "wayland";

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
                if (wayland) return null;
                return new WindowListGroup(parent_id);
            // deprecated
            case "workspace_window_list":
		if (wayland) return null;
                var group = new WindowListGroup(parent_id);
                group.current_workspace_only = true;
                return group;
        }

        return null;
    }
}

}
