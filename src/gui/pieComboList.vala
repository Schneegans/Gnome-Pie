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
/// A drop-down list, containing one entry for each existing Pie.
/////////////////////////////////////////////////////////////////////////

class PieComboList : Gtk.ComboBox {

    /////////////////////////////////////////////////////////////////////
    /// This signal gets emitted when the user selects a new Pie.
    /////////////////////////////////////////////////////////////////////

    public signal void on_select(string id);

    /////////////////////////////////////////////////////////////////////
    /// The currently selected row.
    /////////////////////////////////////////////////////////////////////

    public string current_id { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// Stores the data internally.
    /////////////////////////////////////////////////////////////////////

    private Gtk.ListStore data;
    private enum DataPos {ICON, NAME, ID}

    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs the Widget.
    /////////////////////////////////////////////////////////////////////

    public PieComboList() {
        GLib.Object();

        this.data = new Gtk.ListStore(3, typeof(Gdk.Pixbuf),
                                         typeof(string),
                                         typeof(string));

        this.data.set_sort_column_id(1, Gtk.SortType.ASCENDING);

        base.set_model(this.data);

        var icon_render = new Gtk.CellRendererPixbuf();
            icon_render.xpad = 4;
            this.pack_start(icon_render, false);

        var name_render = new Gtk.CellRendererText();
            this.pack_start(name_render, true);

        this.add_attribute(icon_render, "pixbuf", DataPos.ICON);
        this.add_attribute(name_render, "text", DataPos.NAME);

        this.changed.connect(() => {
            Gtk.TreeIter active;
            if (this.get_active_iter(out active)) {
                string id = "";
                this.data.get(active, DataPos.ID, out id);
                this.on_select(id);
                this.current_id = id;
            }
        });

        reload();
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads all existing Pies to the list.
    /////////////////////////////////////////////////////////////////////

    public void reload() {
        Gtk.TreeIter active;
        string id = "";
        if (this.get_active_iter(out active))
            this.data.get(active, DataPos.ID, out id);

        data.clear();
        foreach (var pie in PieManager.all_pies.entries) {
            this.load_pie(pie.value);
        }

        select_first();
        select(id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Selects the first Pie.
    /////////////////////////////////////////////////////////////////////

    public void select_first() {
        Gtk.TreeIter active;

        if(this.data.get_iter_first(out active) ) {
            this.set_active_iter(active);
            string id = "";
            this.data.get(active, DataPos.ID, out id);
            this.on_select(id);
            this.current_id = id;
        } else {
            this.on_select("");
            this.current_id = "";
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Selects the Pie with the given ID.
    /////////////////////////////////////////////////////////////////////

    public void select(string id) {
        this.data.foreach((model, path, iter) => {
            string pie_id;
            this.data.get(iter, DataPos.ID, out pie_id);

            if (id == pie_id) {
                this.set_active_iter(iter);
                return true;
            }

            return false;
        });
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads one given pie to the list.
    /////////////////////////////////////////////////////////////////////

    private void load_pie(Pie pie) {
        if (pie.id.length == 3) {
            Gtk.TreeIter last;
            this.data.append(out last);
            var icon = new Icon(pie.icon, 24);
            this.data.set(last, DataPos.ICON, icon.to_pixbuf(),
                                DataPos.NAME, pie.name,
                                DataPos.ID, pie.id);
        }
    }
}

}
