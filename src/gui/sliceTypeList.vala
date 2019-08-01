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
/// A list displaying all available Action types and ActionGroup types.
/////////////////////////////////////////////////////////////////////////

class SliceTypeList : Gtk.TreeView {

    /////////////////////////////////////////////////////////////////////
    /// This signal gets emitted when the user selects a new Type.
    /////////////////////////////////////////////////////////////////////

    public signal void on_select(string id, string icon_name);

    /////////////////////////////////////////////////////////////////////
    /// The listore which staroes all types internally.
    /////////////////////////////////////////////////////////////////////

    private Gtk.ListStore data;
    private enum DataPos {ICON, ICON_NAME, NAME, ID}

    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs the Widget.
    /////////////////////////////////////////////////////////////////////

    public SliceTypeList() {
        GLib.Object();

        this.data = new Gtk.ListStore(4, typeof(Gdk.Pixbuf),
                                         typeof(string),
                                         typeof(string),
                                         typeof(string));

        this.data.set_sort_column_id(2, Gtk.SortType.ASCENDING);

        base.set_model(this.data);
        base.set_headers_visible(true);
        base.set_grid_lines(Gtk.TreeViewGridLines.NONE);
        this.set_fixed_height_mode(true);

        var main_column = new Gtk.TreeViewColumn();
            main_column.set_sizing(Gtk.TreeViewColumnSizing.FIXED);
            main_column.title = _("Slice types");
            var icon_render = new Gtk.CellRendererPixbuf();
                main_column.pack_start(icon_render, false);

            var name_render = new Gtk.CellRendererText();
                name_render.xpad = 6;
                main_column.pack_start(name_render, true);

        base.append_column(main_column);

        main_column.add_attribute(icon_render, "pixbuf", DataPos.ICON);
        main_column.add_attribute(name_render, "markup", DataPos.NAME);

        this.get_selection().changed.connect(() => {
            Gtk.TreeIter active;
            if (this.get_selection().get_selected(null, out active)) {
                string id = "";
                string icon = "";
                this.data.get(active, DataPos.ID, out id);
                this.data.get(active, DataPos.ICON_NAME, out icon);
                this.on_select(id, icon);
            }
        });

        reload_all();
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads a registered actions and action groups.
    /////////////////////////////////////////////////////////////////////

    public void reload_all() {
        Gtk.TreeIter active;
        string current_id = "";
        if (this.get_selection().get_selected(null, out active))
            this.data.get(active, DataPos.ID, out current_id);

        data.clear();

        foreach (var action_type in ActionRegistry.types) {
            var description = ActionRegistry.descriptions[action_type];

            Gtk.TreeIter current;
            data.append(out current);
            var icon = new Icon(description.icon, 36);
            data.set(current, DataPos.ICON, icon.to_pixbuf());
            data.set(current, DataPos.ICON_NAME, description.icon);
            data.set(current, DataPos.NAME, GLib.Markup.escape_text(description.name) + "\n"
                                 + "<span font-size='x-small'>" + GLib.Markup.escape_text(description.description) + "</span>");
            data.set(current, DataPos.ID, description.id);
        }

        foreach (var group_type in GroupRegistry.types) {
            var description = GroupRegistry.descriptions[group_type];

            Gtk.TreeIter current;
            data.append(out current);
            var icon = new Icon(description.icon, 36);
            data.set(current, DataPos.ICON, icon.to_pixbuf());
            data.set(current, DataPos.ICON_NAME, description.icon);
            data.set(current, DataPos.NAME, GLib.Markup.escape_text(description.name) + "\n"
                                 + "<span font-size='x-small'>" + GLib.Markup.escape_text(description.description) + "</span>");
            data.set(current, DataPos.ID, description.id);
        }

        select_first();
        select(current_id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Selects the first type in the list.
    /////////////////////////////////////////////////////////////////////

    public void select_first() {
        Gtk.TreeIter active;

        if(this.data.get_iter_first(out active) ) {
            this.get_selection().select_iter(active);
            string id = "";
            string icon = "";
            this.data.get(active, DataPos.ID, out id);
            this.data.get(active, DataPos.ICON_NAME, out icon);
            this.on_select(id, icon);
        } else {
            this.on_select("", "stock_unknown");
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Select the given slice type.
    /////////////////////////////////////////////////////////////////////

    public void select(string id) {
        this.data.foreach((model, path, iter) => {
            string pie_id;
            this.data.get(iter, DataPos.ID, out pie_id);

            if (id == pie_id) {
                this.get_selection().select_iter(iter);
                string icon = "";
                this.data.get(iter, DataPos.ICON_NAME, out icon);
                this.on_select(pie_id, icon);
                this.scroll_to_cell(path, null, true, 0.5f, 0.5f);
                this.has_focus = true;

                return true;
            }

            return false;
        });
    }
}

}
