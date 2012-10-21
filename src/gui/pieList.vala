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
/// A list, containing one entry for each existing Pie.
/////////////////////////////////////////////////////////////////////////

class PieList : Gtk.TreeView {

    /////////////////////////////////////////////////////////////////////
    /// This signal gets emitted when the user selects a new Pie.
    /////////////////////////////////////////////////////////////////////
    
    public signal void on_select(string id);
    
    /////////////////////////////////////////////////////////////////////
    /// Stores the data internally.
    /////////////////////////////////////////////////////////////////////
    
    private Gtk.ListStore data;
    private enum DataPos {ICON, ICON_NAME, NAME, ID}
    
    /////////////////////////////////////////////////////////////////////
    /// Stores where a drag startet.
    /////////////////////////////////////////////////////////////////////
    
    private Gtk.TreeIter? drag_start = null;
    
    /////////////////////////////////////////////////////////////////////
    /// Rembers the time when a last drag move event was reported. Used
    /// to avoid frequent changes of selected Pie when a Pie is dragged
    /// over this widget.
    /////////////////////////////////////////////////////////////////////

    private uint last_hover = 0;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs the Widget.
    /////////////////////////////////////////////////////////////////////

    public PieList() {
        GLib.Object();
        
        this.data = new Gtk.ListStore(4, typeof(Gdk.Pixbuf),   
                                         typeof(string),
                                         typeof(string),
                                         typeof(string));
                                         
        this.data.set_sort_column_id(DataPos.NAME, Gtk.SortType.ASCENDING);
        
        this.set_model(this.data);
        this.set_headers_visible(false);
        this.set_grid_lines(Gtk.TreeViewGridLines.NONE);
        this.width_request = 170;
        this.set_enable_search(false);
        
        this.set_events(Gdk.EventMask.POINTER_MOTION_MASK);
        
        var main_column = new Gtk.TreeViewColumn();
            var icon_render = new Gtk.CellRendererPixbuf();
                icon_render.xpad = 4;
                icon_render.ypad = 4;
                main_column.pack_start(icon_render, false);
        
            var name_render = new Gtk.CellRendererText();
                name_render.ellipsize = Pango.EllipsizeMode.END;
                name_render.ellipsize_set = true;
                main_column.pack_start(name_render, true);
        
        base.append_column(main_column);
        
        main_column.add_attribute(icon_render, "pixbuf", DataPos.ICON);
        main_column.add_attribute(name_render, "text", DataPos.NAME);
        
        // setup drag'n'drop
        Gtk.TargetEntry uri_source = {"text/uri-list", 0, 0};
        Gtk.TargetEntry[] entries = { uri_source };
        this.enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK, entries, Gdk.DragAction.LINK);
        this.enable_model_drag_dest(entries, Gdk.DragAction.COPY | Gdk.DragAction.MOVE | Gdk.DragAction.LINK);
        this.drag_data_get.connect(this.on_dnd_source);
        this.drag_data_received.connect(this.on_dnd_received);
        this.drag_begin.connect_after(this.on_start_drag);
        this.drag_motion.connect(this.on_drag_move);
        this.drag_leave.connect(() => {
            this.last_hover = 0;
        });
        
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
    
    /////////////////////////////////////////////////////////////////////
    /// Loads all existing Pies to the list.
    /////////////////////////////////////////////////////////////////////
    
    public void reload_all() {
        Gtk.TreeIter active;
        string id = "";
        if (this.get_selection().get_selected(null, out active))
            this.data.get(active, DataPos.ID, out id);
    
        data.clear();
        foreach (var pie in PieManager.all_pies.entries) {
            this.load_pie(pie.value);
        }
        
        select(id);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Selects the first Pie.
    /////////////////////////////////////////////////////////////////////
    
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
    
    /////////////////////////////////////////////////////////////////////
    /// Selects the Pie with the given ID.
    /////////////////////////////////////////////////////////////////////
    
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
    
    /////////////////////////////////////////////////////////////////////
    /// Loads one given pie to the list.
    /////////////////////////////////////////////////////////////////////
    
    private void load_pie(Pie pie) {
        if (pie.id.length == 3) {
            Gtk.TreeIter last;
            this.data.append(out last);
            var icon = new Icon(pie.icon, 24);
            this.data.set(last, DataPos.ICON, icon.to_pixbuf(), 
                                DataPos.ICON_NAME, pie.icon,
                                DataPos.NAME, pie.name,
                                DataPos.ID, pie.id); 
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when a drag which started on this Widget was successfull.
    /////////////////////////////////////////////////////////////////////
    
    private void on_dnd_source(Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_) {
        if (this.drag_start != null) {
            string id = "";
            this.data.get(this.drag_start, DataPos.ID, out id);
            selection_data.set_uris({"file://" + Paths.launchers + "/" + id + ".desktop"});
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when a drag operation is started on this Widget.
    /////////////////////////////////////////////////////////////////////
    
    private void on_start_drag(Gdk.DragContext ctx) {
        if (this.get_selection().get_selected(null, out this.drag_start)) {
            string icon_name = "";
            this.data.get(this.drag_start, DataPos.ICON_NAME, out icon_name);
            
            var icon = new Icon(icon_name, 48);
            var pixbuf = icon.to_pixbuf();
            Gtk.drag_set_icon_pixbuf(ctx, pixbuf, icon.size()/2, icon.size()/2);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when something is dragged over this Widget.
    /////////////////////////////////////////////////////////////////////
    
    private bool on_drag_move(Gdk.DragContext context, int x, int y, uint time) {
    
        Gtk.TreeViewDropPosition position;
        Gtk.TreePath path;
        
        if (!this.get_dest_row_at_pos(x, y, out path, out position))
            return false;
        
        if (position == Gtk.TreeViewDropPosition.BEFORE)
            this.set_drag_dest_row(path, Gtk.TreeViewDropPosition.INTO_OR_BEFORE);
        else if (position == Gtk.TreeViewDropPosition.AFTER)
            this.set_drag_dest_row(path, Gtk.TreeViewDropPosition.INTO_OR_AFTER);

        Gdk.drag_status(context, context.get_suggested_action(), time);
        
        // avoid too frequent selection...
        this.last_hover = time;
        
        GLib.Timeout.add(150, () => {
            if (this.last_hover == time)
                this.get_selection().select_path(path); 
            return false;
        });
        
        return true;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the user finishes a drag operation on this widget.
    /// Only used for external drags.
    /////////////////////////////////////////////////////////////////////
    
    private void on_dnd_received(Gdk.DragContext context, int x, int y, 
                                 Gtk.SelectionData selection_data, uint info, uint time_) {
        
        Gtk.TreeIter active;
        if (this.get_selection().get_selected(null, out active)) {
            string id = "";
            this.data.get(active, DataPos.ID, out id);
            
            var pie = PieManager.all_pies[id];
            
            foreach (var uri in selection_data.get_uris()) {
                pie.add_action(ActionRegistry.new_for_uri(uri), 0);
            }
            
            this.on_select(id);
        }
    }
}

}
