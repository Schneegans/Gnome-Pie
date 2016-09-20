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
    /// Two members needed to avoid useless, frequent changes of the
    /// stored Actions.
    /////////////////////////////////////////////////////////////////////

    private bool changing = false;
    private bool changed_again = false;

    private Wnck.Screen screen;

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

        this.screen.window_opened.connect(reload);
        this.screen.window_closed.connect(reload);
        this.screen.active_workspace_changed.connect(reload);

        this.update();
    }

    /////////////////////////////////////////////////////////////////////
    /// This one is called, when the ActionGroup is saved.
    /////////////////////////////////////////////////////////////////////

    public override void on_save(Xml.TextWriter writer) {
        base.on_save(writer);
        writer.write_attribute("current_workspace_only", this.current_workspace_only.to_string());
    }

    /////////////////////////////////////////////////////////////////////
    /// This one is called, when the ActionGroup is loaded.
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
    /// Loads all currently opened windows and creates actions for them.
    /////////////////////////////////////////////////////////////////////

    private void update() {
        unowned GLib.List<Wnck.Window?> windows = this.screen.get_windows();

        foreach (var window in windows) {
            if (window.get_window_type() == Wnck.WindowType.NORMAL
                && !window.is_skip_pager() && !window.is_skip_tasklist()
                && (!current_workspace_only || (window.get_workspace() != null
                && window.get_workspace() == this.screen.get_active_workspace()))) {

                var application = window.get_application();
                var icon = application.get_icon_name().down();
                var name = window.get_name();

                if (name.length > 30) {
                    name = name.substring(0, 30) + "...";
                }

                var action = new SigAction(name, icon, "%lu".printf(window.get_xid()));

                action.activated.connect((time_stamp) => {
                    Wnck.Screen.get_default().force_update();

                    var xid = (X.Window)uint64.parse(action.real_command);
                    var win = Wnck.Window.get(xid);

                    if (win.get_workspace() != null) {
                        //select the workspace
                        if (win.get_workspace() != win.get_screen().get_active_workspace()) {
                            win.get_workspace().activate(time_stamp);
                        }

                        //select the viewport inside the workspace
                        if (!win.is_in_viewport(win.get_workspace()) ) {
                            int xp, yp, widthp, heightp, scx, scy, nx, ny, wx, wy;
                            win.get_geometry (out xp, out yp, out widthp, out heightp);
                            scx = win.get_screen().get_width();
                            scy = win.get_screen().get_height();
                            wx = win.get_workspace().get_viewport_x();
                            wy = win.get_workspace().get_viewport_y();
                            if (scx > 0 && scy > 0) {
                                nx= ((wx+xp) / scx) * scx;
                                ny= ((wy+yp) / scy) * scy;
                                win.get_screen().move_viewport(nx, ny);
                            }
                        }
                    }

                    if (win.is_minimized()) {
                        win.unminimize(time_stamp);
                    }

                    win.activate_transient(time_stamp);
                });
                this.add_action(action);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Reloads all running applications.
    /////////////////////////////////////////////////////////////////////

    private void reload() {
        // avoid too frequent changes...
        if (!this.changing) {
            this.changing = true;
            Timeout.add(500, () => {
                if (this.changed_again) {
                    this.changed_again = false;
                    return true;
                }

                // reload
                this.delete_all();
                this.update();

                this.changing = false;
                return false;
            });
        } else {
            this.changed_again = true;
        }
    }
}

}
