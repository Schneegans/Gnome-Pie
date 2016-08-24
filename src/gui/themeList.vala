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
/// A widget displaying all available themes of Gnome-Pie.
/////////////////////////////////////////////////////////////////////////

class ThemeList : Gtk.TreeView {

    /////////////////////////////////////////////////////////////////////
    /// This signal gets emitted, when a new theme is selected by the
    /// user. This new theme is applied automatically, with this signal
    /// actions may be triggered which should be executed AFTER the
    /// change to a new theme.
    /////////////////////////////////////////////////////////////////////

    public signal void on_select_new();

    /////////////////////////////////////////////////////////////////////
    /// The currently selected row.
    /////////////////////////////////////////////////////////////////////

    private Gtk.TreeIter active { private get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// The positions in the data list store.
    /////////////////////////////////////////////////////////////////////

    private enum DataPos {ICON, NAME}

    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs the Widget.
    /////////////////////////////////////////////////////////////////////

    public ThemeList() {
        GLib.Object();

        this.set_headers_visible(true);
        this.set_grid_lines(Gtk.TreeViewGridLines.NONE);
        this.set_fixed_height_mode(true);

        var main_column = new Gtk.TreeViewColumn();
            main_column.title = _("Themes");
            main_column.set_sizing(Gtk.TreeViewColumnSizing.FIXED);
            var icon_render = new Gtk.CellRendererPixbuf();
                icon_render.xpad = 4;
                icon_render.ypad = 4;
                main_column.pack_start(icon_render, false);

            var name_render = new Gtk.CellRendererText();
                name_render.xpad = 6;
                main_column.pack_start(name_render, true);

        this.append_column(main_column);

        main_column.add_attribute(icon_render, "pixbuf", DataPos.ICON);
        main_column.add_attribute(name_render, "markup", DataPos.NAME);

        this.get_selection().changed.connect(() => {
            Gtk.TreeIter active;
            if (this.get_selection().get_selected(null, out active)) {
                Timeout.add(10, () => {
                    int index = int.parse(this.model.get_path(active).to_string());
                    Config.global.theme = Config.global.themes[index];

                    this.on_select_new();

                    Config.global.theme.load();
                    Config.global.theme.load_images();
                    return false;
                });
            }
        });

        reload();
    }

    public void reload() {

        var data = new Gtk.ListStore(2, typeof(Gdk.Pixbuf),
                                        typeof(string));
        this.set_model(data);

        // load all themes into the list
        var themes = Config.global.themes;
        foreach(var theme in themes) {
            Gtk.TreeIter current;
            data.append(out current);
            data.set(current, DataPos.ICON, theme.preview_icon.to_pixbuf());
            data.set(current, DataPos.NAME, GLib.Markup.escape_text(theme.name)+"\n"
                                            + "<span font-size='x-small'>" + GLib.Markup.escape_text(theme.description)
                                            + " - <i>"+GLib.Markup.escape_text(_("by")+" "+theme.author)
                                            + "</i></span>");
            if(theme == Config.global.theme) {
                get_selection().select_iter(current);
                this.scroll_to_cell(get_selection().get_selected_rows(null).nth_data(0), null, true, 0.5f, 0.5f);
            }
        }
    }
}

}
