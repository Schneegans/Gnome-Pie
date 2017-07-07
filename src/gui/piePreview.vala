/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2017 by Simon Schneegans
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
/// A custom widget displaying the preview of a Pie. It can be used to
/// configure the displayed Pie in various aspects.
/////////////////////////////////////////////////////////////////////////

class PiePreview : Gtk.DrawingArea {

    /////////////////////////////////////////////////////////////////////
    /// These get called when the last Slice is removed and when the
    /// first Slice is added respectively.
    /////////////////////////////////////////////////////////////////////

    public signal void on_last_slice_removed();
    public signal void on_first_slice_added();

    /////////////////////////////////////////////////////////////////////
    /// The internally used renderer to draw the Pie.
    /////////////////////////////////////////////////////////////////////

    private PiePreviewRenderer renderer = null;

    /////////////////////////////////////////////////////////////////////
    /// The window which pops up, when a Slice is added or edited.
    /////////////////////////////////////////////////////////////////////

    private NewSliceWindow? new_slice_window = null;

    /////////////////////////////////////////////////////////////////////
    /// A timer used for calculating the frame time.
    /////////////////////////////////////////////////////////////////////

    private GLib.Timer timer;

    /////////////////////////////////////////////////////////////////////
    /// True, when it is possible to drag a slice from this widget.
    /// False, when the user currently hovers over the add sign.
    /////////////////////////////////////////////////////////////////////

    private bool drag_enabled = false;

    /////////////////////////////////////////////////////////////////////
    /// The ID of the currently displayed Pie.
    /////////////////////////////////////////////////////////////////////

    private string current_id = "";

    /////////////////////////////////////////////////////////////////////
    /// The position from where a Slice-drag started.
    /////////////////////////////////////////////////////////////////////

    private int drag_start_index = -1;
    private string drag_start_id = "";

    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates the widget.
    /////////////////////////////////////////////////////////////////////

    public PiePreview() {
        this.renderer = new PiePreviewRenderer(this);

        this.draw.connect(this.on_draw);
        this.timer = new GLib.Timer();
        this.set_events(Gdk.EventMask.POINTER_MOTION_MASK
                      | Gdk.EventMask.LEAVE_NOTIFY_MASK
                      | Gdk.EventMask.ENTER_NOTIFY_MASK);

        // setup drag and drop
        this.enable_drag_source();

        Gtk.TargetEntry uri_dest = {"text/uri-list", 0, 0};
        Gtk.TargetEntry text_dest = {"text/plain", 0, 0};
        Gtk.TargetEntry slice_dest = {"text/plain", Gtk.TargetFlags.SAME_WIDGET, 0};
        Gtk.TargetEntry[] destinations = { uri_dest, text_dest, slice_dest };
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

    /////////////////////////////////////////////////////////////////////
    /// Sets the currently displayed Pie to the Pie with the given ID.
    /////////////////////////////////////////////////////////////////////

    public void set_pie(string id) {
        this.current_id = id;
        this.renderer.load_pie(PieManager.all_pies[id]);

        if (id == this.drag_start_id) {
            this.renderer.hide_group(this.drag_start_index);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Begins the draw loop. It automatically ends, when the containing
    /// window becomes invisible.
    /////////////////////////////////////////////////////////////////////

    public void draw_loop() {
        this.timer.start();
        this.queue_draw();

        GLib.Timeout.add((uint)(1000.0/Config.global.refresh_rate), () => {
            this.queue_draw();
            return this.get_toplevel().visible;
        });
    }

    /////////////////////////////////////////////////////////////////////
    /// Called every frame.
    /////////////////////////////////////////////////////////////////////

    private bool on_draw(Cairo.Context ctx) {
        // store the frame time
        double frame_time = this.timer.elapsed();
        this.timer.reset();

        Gtk.Allocation allocation;
        this.get_allocation(out allocation);

        ctx.translate((int)(allocation.width*0.5), (int)(allocation.height*0.5));

        this.renderer.draw(frame_time, ctx);

        return true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the mouse leaves the area of this widget.
    /////////////////////////////////////////////////////////////////////

    public bool on_mouse_leave(Gdk.EventCrossing event) {
        this.renderer.on_mouse_leave();
        return true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the mouse enters the area of this widget.
    /////////////////////////////////////////////////////////////////////

    public bool on_mouse_enter(Gdk.EventCrossing event) {
        this.renderer.on_mouse_enter();
        return true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the mouse moves in the area of this widget.
    /////////////////////////////////////////////////////////////////////

    private bool on_mouse_move(Gdk.EventMotion event) {
        this.renderer.set_dnd_mode(false);
        Gtk.Allocation allocation;
        this.get_allocation(out allocation);
        this.renderer.on_mouse_move(event.x-allocation.width*0.5, event.y-allocation.height*0.5);

        if (this.renderer.get_active_slice() < 0) this.disable_drag_source();
        else                                      this.enable_drag_source();

        return true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when a mouse button is pressed.
    /////////////////////////////////////////////////////////////////////

    private bool on_button_press() {
        this.renderer.on_button_press();
        return true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when a mouse button is released.
    /////////////////////////////////////////////////////////////////////

    private bool on_button_release() {
        if (!this.renderer.drag_n_drop_mode)
            this.renderer.on_button_release();
        return true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the mouse is moved over this widget.
    /////////////////////////////////////////////////////////////////////

    private bool on_drag_move(Gdk.DragContext ctx, int x, int y, uint time) {
        this.renderer.set_dnd_mode(true);
        Gtk.Allocation allocation;
        this.get_allocation(out allocation);
        this.renderer.on_mouse_move(x-allocation.width*0.5, y-allocation.height*0.5);

        return true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the user tries to drag something from this widget.
    /////////////////////////////////////////////////////////////////////

    private void on_start_drag(Gdk.DragContext ctx) {
        this.drag_start_index = this.renderer.get_active_slice();
        this.drag_start_id = this.current_id;
        var icon = this.renderer.get_active_icon();
        var pixbuf = icon.to_pixbuf();

        this.renderer.hide_group(this.drag_start_index);
        Gtk.drag_set_icon_pixbuf(ctx, pixbuf, icon.size()/2, icon.size()/2);

        this.renderer.set_dnd_mode(true);
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the user finishes a drag operation on this widget.
    /// Only used for Slice-movement.
    /////////////////////////////////////////////////////////////////////

    private void on_end_drag(Gdk.DragContext context) {

        if (context.list_targets() != null) {

            int target_index = this.renderer.get_active_slice();
            this.renderer.set_dnd_mode(false);

            context.list_targets().foreach((target) => {
                Gdk.Atom target_type = (Gdk.Atom)target;
                if (target_type.name() == "text/plain") {
                    if (this.current_id == this.drag_start_id) {
                        var pie = PieManager.all_pies[this.current_id];
                        pie.move_group(this.drag_start_index, target_index);
                        this.renderer.show_hidden_group_at(target_index);
                    } else {
                        var src_pie = PieManager.all_pies[this.drag_start_id];
                        var dst_pie = PieManager.all_pies[this.current_id];
                        dst_pie.add_group(src_pie.action_groups[this.drag_start_index], target_index);
                        this.renderer.add_group(dst_pie.action_groups[target_index], target_index);

                        if (this.renderer.slices.size == 1)
                            this.on_first_slice_added();

                        if ((context.get_actions() & Gdk.DragAction.COPY) == 0)
                            src_pie.remove_group(this.drag_start_index);
                    }


                }
            });

            this.drag_start_index = -1;
            this.drag_start_id = "";
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the user finishes a drag operation on this widget.
    /// Only used for external drags.
    /////////////////////////////////////////////////////////////////////

    private void on_dnd_received(Gdk.DragContext context, int x, int y,
                                 Gtk.SelectionData selection_data, uint info, uint time_) {

        var pie = PieManager.all_pies[this.current_id];
        int position = this.renderer.get_active_slice();
        this.renderer.set_dnd_mode(false);

        var text = selection_data.get_text();
        if (text != null && GLib.Uri.parse_scheme(text) != null) {
            pie.add_action(ActionRegistry.new_for_uri(text), position);
            this.renderer.add_group(pie.action_groups[position], position);

            if (this.renderer.slices.size == 1)
                this.on_first_slice_added();
        }


        foreach (var uri in selection_data.get_uris()) {
            pie.add_action(ActionRegistry.new_for_uri(uri), position);
            this.renderer.add_group(pie.action_groups[position], position);

            if (this.renderer.slices.size == 1)
                this.on_first_slice_added();
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Enables this widget to be a source for drag operations.
    /////////////////////////////////////////////////////////////////////

    private void enable_drag_source() {
        if (!this.drag_enabled) {
            this.drag_enabled = true;
            Gtk.TargetEntry slice_source = {"text/plain", Gtk.TargetFlags.SAME_WIDGET | Gtk.TargetFlags.SAME_APP, 0};
            Gtk.TargetEntry[] sources = { slice_source };
            Gtk.drag_source_set(this, Gdk.ModifierType.BUTTON1_MASK, sources, Gdk.DragAction.MOVE | Gdk.DragAction.COPY);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Disables this widget to be a source for drag operations.
    /////////////////////////////////////////////////////////////////////

    private void disable_drag_source() {
        if (this.drag_enabled) {
            this.drag_enabled = false;
            Gtk.drag_source_unset(this);
        }
    }

}

}
