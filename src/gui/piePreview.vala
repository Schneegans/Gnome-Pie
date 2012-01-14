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

class PiePreview : Gtk.DrawingArea {

    public signal void on_last_slice_removed();
    public signal void on_first_slice_added();

    private PiePreviewRenderer renderer = null;
    private NewSliceWindow? new_slice_window = null;
    
    /////////////////////////////////////////////////////////////////////
    /// A timer used for calculating the frame time.
    /////////////////////////////////////////////////////////////////////
    
    private GLib.Timer timer;
    
    private bool drawing = false;
    private bool drag_enabled = false;
    private string current_id = "";
    
    private int drag_start_index = -1;
    private int drag_end_index = -1;

    public PiePreview() {
        this.renderer = new PiePreviewRenderer();
        this.expose_event.connect(this.on_draw);
        this.timer = new GLib.Timer();
        this.set_events(Gdk.EventMask.POINTER_MOTION_MASK 
                      | Gdk.EventMask.LEAVE_NOTIFY_MASK
                      | Gdk.EventMask.ENTER_NOTIFY_MASK);
        
        // setup drag and drop
        this.enable_drag_source();
        
        Gtk.TargetEntry uri_dest = {"text/uri-list", 0, 0};
        Gtk.TargetEntry slice_dest = {"text/plain", Gtk.TargetFlags.SAME_WIDGET, 0};
        Gtk.TargetEntry[] destinations = { uri_dest, slice_dest };
        Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, destinations, Gdk.DragAction.COPY | Gdk.DragAction.MOVE | Gdk.DragAction.LINK);
        
        this.drag_begin.connect(this.on_start_drag);
        this.drag_end.connect(this.on_end_drag);
        this.drag_data_received.connect(this.on_dnd_received);
        
        // connect mouse events
        this.drag_motion.connect(this.on_drag_move);
        this.leave_notify_event.connect(this.on_mouse_leave);
        this.enter_notify_event.connect(this.on_mouse_enter);  
        this.motion_notify_event.connect_after(this.on_mouse_move);
        this.button_release_event.connect_after(this.on_button_release);
        this.button_press_event.connect_after(this.on_button_press);
        
        this.new_slice_window = new NewSliceWindow();
        this.new_slice_window.on_select.connect((new_action, as_new_slice, at_position) => {
            var pie = PieManager.all_pies[this.current_id];
            
            if (new_action.has_quickaction())
                renderer.disable_quickactions();
            
            if (as_new_slice) {
                pie.add_group(new_action, at_position+1);
                this.renderer.add_group(new_action, at_position+1);
                
                if (this.renderer.slice_count() == 1)
                    this.on_first_slice_added();
            } else {
                pie.update_group(new_action, at_position);
                this.renderer.update_group(new_action, at_position);
            }
        });
        
        this.renderer.on_edit_slice.connect((pos) => {
            this.new_slice_window.reload();
            
            this.new_slice_window.set_parent(this.get_toplevel() as Gtk.Window);
            this.new_slice_window.show();
            
            var pie = PieManager.all_pies[this.current_id];
            this.new_slice_window.set_action(pie.action_groups[pos], pos);
        });
        
        this.renderer.on_add_slice.connect((pos) => {
            this.new_slice_window.reload();
            
            this.new_slice_window.set_parent(this.get_toplevel() as Gtk.Window);
            this.new_slice_window.show();
            
            this.new_slice_window.set_default(this.current_id, pos);
        });
        
        this.renderer.on_remove_slice.connect((pos) => {
            
            var dialog = new Gtk.MessageDialog(this.get_toplevel() as Gtk.Window, Gtk.DialogFlags.MODAL,
                         Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO,
                         _("Do you really want to delete this Slice?"));
                                                     
            dialog.response.connect((response) => {
                if (response == Gtk.ResponseType.YES) {
                    var pie = PieManager.all_pies[this.current_id];
            
                    pie.remove_group(pos);
                    this.renderer.remove_group(pos);
                    
                    if (this.renderer.slice_count() == 0)
                        this.on_last_slice_removed();
                }
            });
            
            dialog.run();
            dialog.destroy();
        });
    }
    
    public void set_pie(string id) {
        this.current_id = id;
        this.window.set_background(Gtk.rc_get_style(this).light[0]);
        this.renderer.load_pie(PieManager.all_pies[id]);
    }
    
    public void draw_loop() {
        this.drawing = true;
        this.timer.start();
        this.queue_draw();
        
        GLib.Timeout.add((uint)(1000.0/Config.global.refresh_rate), () => {
            this.queue_draw();
            return this.get_toplevel().visible;
        });
    }

    
    private bool on_draw(Gtk.Widget da, Gdk.EventExpose event) { 
        // store the frame time
        double frame_time = this.timer.elapsed();
        this.timer.reset();
        
        var ctx = Gdk.cairo_create(this.window);
        ctx.translate((int)(this.allocation.width*0.5), (int)(this.allocation.height*0.5));
        
        this.renderer.draw(frame_time, ctx);
        
        return true;
    }
    
    public bool on_mouse_leave(Gdk.EventCrossing event) {
        this.renderer.on_mouse_leave();
        return true;
    }
    
    public bool on_mouse_enter(Gdk.EventCrossing event) {
        this.renderer.on_mouse_enter();
        return true;
    }
    
    private bool on_mouse_move(Gdk.EventMotion event) {
        this.renderer.set_dnd_mode(false);
        this.renderer.on_mouse_move(event.x-this.allocation.width*0.5, event.y-this.allocation.height*0.5);
        
        if (this.renderer.get_active_slice() < 0) this.disable_drag_source();
        else                                      this.enable_drag_source();
        
        return true;
    }
    
    private bool on_button_press() {
        this.renderer.on_button_press();
        return true;
    }
    
    private bool on_button_release() {
        if (!this.renderer.drag_n_drop_mode) 
            this.renderer.on_button_release();
        return true;
    }
    
    private bool on_drag_move(Gdk.DragContext ctx, int x, int y, uint time) {
        this.renderer.set_dnd_mode(true);
        this.renderer.on_mouse_move(x-this.allocation.width*0.5, y-this.allocation.height*0.5);
        return true;
    }
    
    private void on_start_drag(Gdk.DragContext ctx) {
        this.drag_start_index = this.renderer.get_active_slice();
        var icon = this.renderer.get_active_icon();
        var pixbuf = icon.to_pixbuf();

        this.renderer.hide_group(this.drag_start_index);
        Gtk.drag_set_icon_pixbuf(ctx, pixbuf, icon.size()/2, icon.size()/2);
        
        this.renderer.set_dnd_mode(true);
    }
    
    private void on_end_drag(Gdk.DragContext context) {
        
        if (context.targets != null) {
        
            int target_index = this.renderer.get_active_slice();
            this.renderer.set_dnd_mode(false);

            context.targets.foreach((target) => {
                Gdk.Atom target_type = (Gdk.Atom)target;
                if (target_type.name() == "text/plain") {
                    var pie = PieManager.all_pies[this.current_id];
                    pie.move_group(this.drag_start_index, target_index);
                    this.renderer.show_hidden_group_at(target_index);
                }
            });
        }  
    }
    
    private void on_dnd_received(Gdk.DragContext context, int x, int y, 
                                 Gtk.SelectionData selection_data, uint info, uint time_) {
                                 
        var pie = PieManager.all_pies[this.current_id];
        int position = this.renderer.get_active_slice();
        this.renderer.set_dnd_mode(false);
        
        foreach (var uri in selection_data.get_uris()) {
            pie.add_action(ActionRegistry.new_for_uri(uri), position);
            this.renderer.add_group(pie.action_groups[position], position);
            
            if (this.renderer.slices.size == 1)
                this.on_first_slice_added();
        }
    }
    
    private void enable_drag_source() {
        if (!this.drag_enabled) {
            this.drag_enabled = true;
            Gtk.TargetEntry slice_source = {"text/plain", Gtk.TargetFlags.SAME_WIDGET | Gtk.TargetFlags.SAME_APP, 0};
            Gtk.TargetEntry[] sources = { slice_source };
            Gtk.drag_source_set(this, Gdk.ModifierType.BUTTON1_MASK, sources, Gdk.DragAction.MOVE);
        }
    }
    
    private void disable_drag_source() {
        if (this.drag_enabled) {
            this.drag_enabled = false;
            Gtk.drag_source_unset(this);
        }
    }
   
}

}
