/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2016 by Simon Schneegans
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

/////////////////////////////////////////////////////////////////////
/// This group displays a list of all running application windows.
/////////////////////////////////////////////////////////////////////

public class WindowListGroup : ActionGroup {

    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of ActionGroup. It sets the display
    /// name for this ActionGroup, it's icon name and the string used in
    /// the pies.conf file for this kind of ActionGroups.
    /////////////////////////////////////////////////////////////////////

    public static GroupRegistry.TypeDescription register() {
        var description = new GroupRegistry.TypeDescription();
        description.name = _("Group: Window List");
        description.icon = "preferences-system-windows";
        description.description = _("Shows a Slice for each of your opened Windows. Almost like Alt-Tab.");
        description.id = "window_list";
        return description;
    }

    public bool current_workspace_only { get; set; default=false; }

    /////////////////////////////////////////////////////////////////////
    /// Cached icon names loaded from .desktop files.
    /////////////////////////////////////////////////////////////////////

    private static Gee.HashMap<string, string> cached_icon_name { private get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Instances of libs Wnck and Bamf, to control the list of
    /// opened windows.
    /////////////////////////////////////////////////////////////////////

    private Wnck.Screen screen;
    private Bamf.Matcher bamf_matcher;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public WindowListGroup(string parent_id) {
        GLib.Object(parent_id : parent_id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads all windows.
    /////////////////////////////////////////////////////////////////////

    construct {
        this.screen = Wnck.Screen.get_default();
        this.bamf_matcher = Bamf.Matcher.get_default();

        WindowListGroup.cached_icon_name = new Gee.HashMap<string, string>();

        Gtk.IconTheme.get_default().changed.connect_after(() => {
            WindowListGroup.cached_icon_name = new Gee.HashMap<string, string>();
            this.load_all_windows();
        });

        this.screen.window_opened.connect_after(window_opened);
        this.screen.window_closed.connect_after(window_closed);
        this.screen.active_workspace_changed.connect_after(load_all_windows);
        this.load_all_windows();
    }

    /////////////////////////////////////////////////////////////////////
    /// This one is called when the ActionGroup is saved.
    /////////////////////////////////////////////////////////////////////

    public override void on_save(Xml.TextWriter writer) {
        base.on_save(writer);
        writer.write_attribute("current_workspace_only", this.current_workspace_only.to_string());
    }

    /////////////////////////////////////////////////////////////////////
    /// This one is called when the ActionGroup is loaded.
    /////////////////////////////////////////////////////////////////////

    public override void on_load(Xml.Node* data) {
        for (Xml.Attr* attribute = data->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;

            if (attr_name == "current_workspace_only") {
                this.current_workspace_only = bool.parse(attr_content);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// This one is called when a new window is opened.
    /////////////////////////////////////////////////////////////////////

    private void window_opened(Wnck.Window window) {
        load_window(window);
    }

    /////////////////////////////////////////////////////////////////////
    /// This one is called when a window is closed.
    /////////////////////////////////////////////////////////////////////

    private void window_closed(Wnck.Window window) {
        foreach (Action action in actions)
            if (window.get_xid() == uint64.parse(action.real_command)) {
                actions.remove(action);
                break;
            }
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads all currently opened windows.
    /////////////////////////////////////////////////////////////////////

    private void load_all_windows() {
        this.delete_all();

        foreach (var window in this.screen.get_windows())
            load_window(window);
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads a currently opened windows and create a Action for them.
    /////////////////////////////////////////////////////////////////////

    private void load_window(Wnck.Window window) {
        if (!window.is_skip_pager() && !window.is_skip_tasklist()
            && (!current_workspace_only || (window.get_workspace() != null
            && window.get_workspace() == this.screen.get_active_workspace()))) {

            var name = window.get_name();
            var icon_name = get_icon_name(window);
            var xid = "%lu".printf(window.get_xid());

            if (name.length > 30) {
                name = name.substring(0, 30) + "...";
            }

            var action = new SigAction(name, icon_name, xid);
            this.add_action(action);

            window.name_changed.connect(() => {
                action.name = window.get_name();
            });

            action.activated.connect((time_stamp) => {
                if (window.get_workspace() != null) {
                    //select the workspace
                    if (window.get_workspace() != window.get_screen().get_active_workspace()) {
                        window.get_workspace().activate(time_stamp);
                    }

                    //select the viewport inside the workspace
                    /*if (!window.is_in_viewport(window.get_workspace()) ) {
                        int xp, yp, widthp, heightp, scx, scy, nx, ny, wx, wy;
                        window.get_geometry (out xp, out yp, out widthp, out heightp);
                        scx = window.get_screen().get_width();
                        scy = window.get_screen().get_height();
                        wx = window.get_workspace().get_viewport_x();
                        wy = window.get_workspace().get_viewport_y();
                        if (scx > 0 && scy > 0) {
                            nx= ((wx+xp) / scx) * scx;
                            ny= ((wy+yp) / scy) * scy;
                            window.get_screen().move_viewport(nx, ny);
                        }
                    }*/
                }

                if (window.is_minimized()) {
                    window.unminimize(time_stamp);
                }

                window.activate_transient(time_stamp);
            });
        }
    }

    private string get_icon_name(Wnck.Window window) {
        var xid = (uint32) window.get_xid();
        string desktop_file = null;
        string icon_name = null;
        Bamf.Application app = this.bamf_matcher.get_application_for_xid(xid);

        if (app != null)
            desktop_file = app.get_desktop_file();

        if (desktop_file != null) {
            if (WindowListGroup.cached_icon_name.has_key(desktop_file))
                icon_name = WindowListGroup.cached_icon_name.get(desktop_file);
            else {
                try {
                    var file = new KeyFile();
                    file.load_from_file(desktop_file, 0);

                    if (file.has_key(KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON)) {
                        icon_name = file.get_locale_string(KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON);
                        WindowListGroup.cached_icon_name.set(desktop_file, icon_name);
                    }
                } catch (GLib.KeyFileError e) {
                    error ("%s", e.message);
                } catch (GLib.FileError e) {
                    error ("%s", e.message);
                }
            }
        }

        if (icon_name == null)
            icon_name = Icon.get_icon_name(window.get_icon_name());

        return icon_name;
    }
}

}
