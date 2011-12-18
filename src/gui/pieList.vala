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
/// 
/////////////////////////////////////////////////////////////////////////

class PieList : Gtk.TreeView {

    /////////////////////////////////////////////////////////////////////
    /// The currently selected row.
    /////////////////////////////////////////////////////////////////////
    
    public signal void on_select(string id);
    
    private Gtk.ListStore data;
    
    private enum DataPos {ICON, NAME, ID}

    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs the Widget.
    /////////////////////////////////////////////////////////////////////

    public PieList() {
        GLib.Object();
        
        this.data = new Gtk.ListStore(3, typeof(Gdk.Pixbuf),   
                                         typeof(string),
                                         typeof(string));
        base.set_model(this.data);
        base.set_headers_visible(false);
        base.set_grid_lines(Gtk.TreeViewGridLines.NONE);
        this.width_request = 170;
        
        var main_column = new Gtk.TreeViewColumn();
            var icon_render = new Gtk.CellRendererPixbuf();
                icon_render.xpad = 4;
                icon_render.ypad = 4;
                main_column.pack_start(icon_render, false);
        
            var name_render = new Gtk.CellRendererText();
                main_column.pack_start(name_render, true);
        
        base.append_column(main_column);
        
        main_column.add_attribute(icon_render, "pixbuf", DataPos.ICON);
        main_column.add_attribute(name_render, "markup", DataPos.NAME);
        
        this.get_selection().changed.connect(() => {
            Gtk.TreeIter active;
            if (this.get_selection().get_selected(null, out active)) {
                string id = "";
                this.data.get(active, DataPos.ID, out id);
                this.on_select(id);
            }
        });
        
        foreach (var pie in PieManager.all_pies.entries) {
            this.load_pie(pie.value);
        }
    }
    
    // loads one given pie to the list
    private void load_pie(Pie pie) {
        if (pie.id.length == 3) {
            Gtk.TreeIter last;
            this.data.append(out last);
            this.data.set(last, DataPos.ICON, this.load_icon(pie.icon, 24), 
                                DataPos.NAME, pie.name,
                                DataPos.ID, pie.id); 
        }
    }
    
    private Gdk.Pixbuf load_icon(string name, int size) {
        Gdk.Pixbuf pixbuf = null;
        
        try {
            if (name.contains("/"))
                pixbuf = new Gdk.Pixbuf.from_file_at_size(name, size, size);
            else
                pixbuf = new Gdk.Pixbuf.from_file_at_size(Icon.get_icon_file(name, size), size, size);
        } catch (GLib.Error e) {
            warning(e.message);
        }
        
        return pixbuf;
    }
}

}
