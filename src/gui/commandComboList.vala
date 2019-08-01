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
