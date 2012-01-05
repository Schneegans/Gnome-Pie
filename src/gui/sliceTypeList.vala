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

class SliceTypeList : Gtk.TreeView {

    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////
    
    public signal void on_select(string id);
    
    private Gtk.ListStore data;
    
    private enum DataPos {ICON, NAME, ID}

    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs the Widget.
    /////////////////////////////////////////////////////////////////////

    public SliceTypeList() {
        GLib.Object();
        
        this.data = new Gtk.ListStore(3, typeof(Gdk.Pixbuf),   
                                         typeof(string),
                                         typeof(string));
                                         
        this.data.set_sort_column_id(1, Gtk.SortType.ASCENDING);
        
        base.set_model(this.data);
        base.set_headers_visible(false);
        base.set_grid_lines(Gtk.TreeViewGridLines.NONE);
        this.width_request = 170;
        
        var main_column = new Gtk.TreeViewColumn();
            var icon_render = new Gtk.CellRendererPixbuf();
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
        
        reload_all();
    }
    
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
            data.set(current, DataPos.NAME, "<b>" + description.name + "</b>\n"
                                 + "<small>" + description.description + "</small>"); 
            data.set(current, DataPos.ID, description.id); 
        }
        
        foreach (var group_type in GroupRegistry.types) {
            var description = GroupRegistry.descriptions[group_type];
            
            Gtk.TreeIter current;
            data.append(out current);
            var icon = new Icon(description.icon, 36);
            data.set(current, DataPos.ICON, icon.to_pixbuf()); 
            data.set(current, DataPos.NAME, "<b>" + description.name + "</b>\n"
                                 + "<small>" + description.description + "</small>"); 
            data.set(current, DataPos.ID, description.id); 
        }
        
        select_first();
        select(current_id);
    }
    
    public void select_first() {
        Gtk.TreeIter active;
        
        if(this.data.get_iter_first(out active) ) {
            this.get_selection().select_iter(active);
            string id = "";
            this.data.get(active, DataPos.ID, out id);
            this.on_select(id);
        } else {
            this.on_select("");
        }
    }
    
    public void select(string id) {
        this.data.foreach((model, path, iter) => {
            string pie_id;
            this.data.get(iter, DataPos.ID, out pie_id);
            
            if (id == pie_id) {
                this.get_selection().select_iter(iter);
                return true;
            }
            
            return false;
        });
    }
}

}
