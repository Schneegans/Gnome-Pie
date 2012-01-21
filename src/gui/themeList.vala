/* 
Copyright (c) 2011 by Simon Schneegans

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>. 
*/

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////    
/// A widget displaying all available themes of Gnome-Pie.
/////////////////////////////////////////////////////////////////////////

class ThemeList : Gtk.TreeView {

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
        
        var data = new Gtk.ListStore(2, typeof(Gdk.Pixbuf), 
                                        typeof(string));
        this.set_model(data);
        this.set_headers_visible(true);
        this.set_grid_lines(Gtk.TreeViewGridLines.NONE);
        this.set_fixed_height_mode(true);
        
        var main_column = new Gtk.TreeViewColumn();
            main_column.title = _("Themes");
            main_column.set_sizing(Gtk.TreeViewColumnSizing.FIXED);
            var icon_render = new Gtk.CellRendererPixbuf();
                main_column.pack_start(icon_render, false);
        
            var theme_render = new Gtk.CellRendererText();
                main_column.pack_start(theme_render, true);
        
        this.append_column(main_column);
        
        main_column.add_attribute(icon_render, "pixbuf", DataPos.ICON);
        main_column.add_attribute(theme_render, "markup", DataPos.NAME);
        
        this.get_selection().changed.connect(() => {
            Gtk.TreeIter active;
            if (this.get_selection().get_selected(null, out active)) {
                Timeout.add(10, () => {
                    int index = int.parse(data.get_path(active).to_string());
                    Config.global.theme = Config.global.themes[index];
                    Config.global.theme.load();
                    Config.global.theme.load_images();
                    return false;
                });  
            }
        });
        
        // load all themes into the list
        var themes = Config.global.themes;
        foreach(var theme in themes) {
            Gtk.TreeIter current;
            data.append(out current);
            data.set(current, DataPos.ICON, theme.preview_icon.to_pixbuf()); 
            data.set(current, DataPos.NAME, "<b>"+theme.name+"</b><small>  -  "+theme.description+"\n"
                                           +"<i>"+_("By")+" "+theme.author+"</i></small>"); 
            if(theme == Config.global.theme)
                get_selection().select_iter(current);
        }  
    }
}

}
