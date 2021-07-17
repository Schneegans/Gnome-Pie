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
