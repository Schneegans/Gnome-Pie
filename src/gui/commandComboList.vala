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

/////////////////////////////////////////////////////////////////////////
/// A drop-down list, containing one entry for each
/// installed application.
/////////////////////////////////////////////////////////////////////////

class CommandComboList : Gtk.ComboBox {

    /////////////////////////////////////////////////////////////////////
    /// Called when something is selected from the drop down.
    /////////////////////////////////////////////////////////////////////

    public signal void on_select(string name, string command, string icon);

    /////////////////////////////////////////////////////////////////////
    /// The currently selected item.
    /////////////////////////////////////////////////////////////////////

    public string text {
        get { return (this.get_child() as Gtk.Entry).get_text();}
        set {        (this.get_child() as Gtk.Entry).set_text(value);}
    }

    /////////////////////////////////////////////////////////////////////
    /// Stores the data internally.
    /////////////////////////////////////////////////////////////////////

    private Gtk.ListStore data;
    private enum DataPos {ICON, NAME, COMMAND}

    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs the Widget.
    /////////////////////////////////////////////////////////////////////

    public CommandComboList() {
        GLib.Object(has_entry : true);

        this.data = new Gtk.ListStore(3, typeof(string),
                                         typeof(string),
                                         typeof(string));

        this.data.set_sort_column_id(1, Gtk.SortType.ASCENDING);
        this.entry_text_column = 2;
        this.id_column = 2;

        base.set_model(this.data);

        // hide default renderer
        this.get_cells().nth_data(0).visible = false;

        var icon_render = new Gtk.CellRendererPixbuf();
            icon_render.xpad = 4;
            this.pack_start(icon_render, false);

        var name_render = new Gtk.CellRendererText();
            this.pack_start(name_render, true);

        this.add_attribute(icon_render, "icon_name", DataPos.ICON);
        this.add_attribute(name_render, "text", DataPos.NAME);

        this.changed.connect(() => {
            Gtk.TreeIter active;
            if (this.get_active_iter(out active)) {
                string name = "";
                string command = "";
                string icon = "";
                this.data.get(active, DataPos.NAME, out name);
                this.data.get(active, DataPos.COMMAND, out command);
                this.data.get(active, DataPos.ICON, out icon);
                on_select(name, command, icon);
            }
        });

        reload();
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads all existing applications to the list.
    /////////////////////////////////////////////////////////////////////

    public void reload() {
        var apps = GLib.AppInfo.get_all();
        foreach (var app in apps) {
            if (app.should_show()) {
                Gtk.TreeIter last;
                var icon_name = "application-x-executable";
                var icon = app.get_icon();

                if (icon != null) {
                    icon_name = icon.to_string();
                }

                this.data.append(out last);
                this.data.set(last, DataPos.ICON, icon_name,
                                    DataPos.NAME, app.get_display_name(),
                                    DataPos.COMMAND, app.get_commandline());
            }
        }
    }
}

}
