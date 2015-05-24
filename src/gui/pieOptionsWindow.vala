/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2015 by Simon Schneegans
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
/// This window allows the selection of a hotkey. It is returned in form
/// of a Trigger. Therefore it can be either a keyboard driven hotkey or
/// a mouse based hotkey.
/////////////////////////////////////////////////////////////////////////

public class PieOptionsWindow : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// This signal is emitted when the user selects a new hot key.
    /////////////////////////////////////////////////////////////////////

    public signal void on_ok(Trigger trigger, string pie_name, string icon_name);

    /////////////////////////////////////////////////////////////////////
    /// Some private members which are needed by other methods.
    /////////////////////////////////////////////////////////////////////

    private Gtk.Dialog window;
    private Gtk.CheckButton turbo;
    private Gtk.CheckButton delayed;
    private Gtk.CheckButton centered;
    private Gtk.CheckButton warp;
    private Gtk.RadioButton rshape[10];
    private TriggerSelectButton trigger_button;
    private Gtk.Entry name_entry = null;
    private Gtk.Button? icon_button = null;
    private Gtk.Image? icon = null;
    private Gtk.Label? pie_id = null;

    private IconSelectWindow? icon_window = null;

    /////////////////////////////////////////////////////////////////////
    /// The currently configured trigger.
    /////////////////////////////////////////////////////////////////////

    private Trigger trigger = null;

    /////////////////////////////////////////////////////////////////////
    /// The trigger which was active when this window was opened. It is
    /// stored in order to check whether anything has changed when the
    /// user clicks on OK.
    /////////////////////////////////////////////////////////////////////

    private Trigger original_trigger = null;

    /////////////////////////////////////////////////////////////////////
    /// Stores the current icon name of the pie.
    /////////////////////////////////////////////////////////////////////

    private string icon_name = "";

    /////////////////////////////////////////////////////////////////////
    /// Stores the id of the current pie.
    /////////////////////////////////////////////////////////////////////

    private string id = "";

    /////////////////////////////////////////////////////////////////////
    /// Radioboxes call toggled() twice per selection change.
    /// This flag is used to discard one of the two notifications.
    /////////////////////////////////////////////////////////////////////

    private static int notify_toggle = 0;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs a new PieOptionsWindow.
    /////////////////////////////////////////////////////////////////////

    public PieOptionsWindow() {
        try {

            Gtk.Builder builder = new Gtk.Builder();

            builder.add_from_file (Paths.ui_files + "/pie_options.ui");

            this.window = builder.get_object("window") as Gtk.Dialog;
            this.trigger_button = new TriggerSelectButton(true);
            this.trigger_button.show();

            this.trigger_button.on_select.connect((trigger) => {
                this.trigger = new Trigger.from_values(
                    trigger.key_sym,
                    trigger.modifiers,
                    trigger.with_mouse,
                    this.turbo.active,
                    this.delayed.active,
                    this.centered.active,
                    this.warp.active,
                    this.get_radio_shape()
                );
            });

            (builder.get_object("trigger-box") as Gtk.Box).pack_start(this.trigger_button, true, true);

            (builder.get_object("ok-button") as Gtk.Button).clicked.connect(this.on_ok_button_clicked);
            (builder.get_object("cancel-button") as Gtk.Button).clicked.connect(this.on_cancel_button_clicked);

            this.turbo = builder.get_object("turbo-check") as Gtk.CheckButton;
            this.turbo.toggled.connect(this.on_check_toggled);

            this.delayed = builder.get_object("delay-check") as Gtk.CheckButton;
            this.delayed.toggled.connect(this.on_check_toggled);

            this.centered = builder.get_object("center-check") as Gtk.CheckButton;
            this.centered.toggled.connect(this.on_check_toggled);

            this.warp = builder.get_object("warp-check") as Gtk.CheckButton;
            this.warp.toggled.connect(this.on_check_toggled);

            for (int i= 0; i < 10; i++) {
                this.rshape[i] = builder.get_object("rshape%d".printf(i)) as Gtk.RadioButton;
                this.rshape[i].toggled.connect(this.on_radio_toggled);
            }

            this.name_entry = builder.get_object("name-entry") as Gtk.Entry;
            this.name_entry.activate.connect(this.on_ok_button_clicked);

            this.pie_id = builder.get_object("pie-id") as Gtk.Label;

            this.icon = builder.get_object("icon") as Gtk.Image;
            this.icon_button = builder.get_object("icon-button") as Gtk.Button;
            this.icon_button.clicked.connect(on_icon_button_clicked);

            this.window.delete_event.connect(this.window.hide_on_delete);

        } catch (GLib.Error e) {
            error("Could not load UI: %s\n", e.message);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Sets the parent window, in order to make this window stay in
    /// front.
    /////////////////////////////////////////////////////////////////////

    public void set_parent(Gtk.Window parent) {
        this.window.set_transient_for(parent);
    }

    /////////////////////////////////////////////////////////////////////
    /// Displays the window on the screen.
    /////////////////////////////////////////////////////////////////////

    public void show() {
        this.window.show_all();
    }

    /////////////////////////////////////////////////////////////////////
    /// Initilizes all members to match the Trigger of the Pie with the
    /// given ID.
    /////////////////////////////////////////////////////////////////////

    public void set_pie(string id) {
        var trigger = new Trigger.from_string(PieManager.get_accelerator_of(id));
        var pie = PieManager.all_pies[id];

        this.id = id;

        this.turbo.active = trigger.turbo;
        this.delayed.active = trigger.delayed;
        this.centered.active = trigger.centered;
        this.warp.active = trigger.warp;
        this.set_radio_shape( trigger.shape );
        this.original_trigger = trigger;
        this.trigger = trigger;
        this.name_entry.text = PieManager.get_name_of(id);
        this.pie_id.label = "Pie-ID: " + id;
        this.trigger_button.set_trigger(trigger);
        this.set_icon(pie.icon);
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when one of the checkboxes is toggled.
    /////////////////////////////////////////////////////////////////////

    private void on_check_toggled() {
        if (this.trigger != null) {
            this.trigger = new Trigger.from_values(
                this.trigger.key_sym, this.trigger.modifiers,
                this.trigger.with_mouse, this.turbo.active,
                this.delayed.active, this.centered.active,
                this.warp.active,
                this.get_radio_shape()
            );
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the current selected radio-button shape: 0= automatic
    /// 5= full pie; 1,3,7,8= quarters; 2,4,6,8=halves
    /// 1 | 4 | 7
    /// 2 | 5 | 8
    /// 3 | 6 | 9
    /////////////////////////////////////////////////////////////////////

    private int get_radio_shape() {
        int rs;
        for (rs= 0; rs < 10; rs++) {
            if (this.rshape[rs].active) {
                break;
            }
        }
        return rs;
    }

    /////////////////////////////////////////////////////////////////////
    /// Sets the current selected radio-button shape: 0= automatic
    /// 5= full pie; 1,3,7,8= quarters; 2,4,6,8=halves
    /////////////////////////////////////////////////////////////////////

    private void set_radio_shape(int rs) {
        if (rs < 0 || rs > 9) {
            rs= 5;  //replace invalid value with default= full pie
        }
        this.rshape[rs].active= true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Called twice when one of the radioboxes is toggled.
    /////////////////////////////////////////////////////////////////////

    private void on_radio_toggled() {
        notify_toggle= 1 - notify_toggle;
        if (notify_toggle == 1) {
            on_check_toggled(); //just call once
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the icon button is clicked.
    /////////////////////////////////////////////////////////////////////

    private void on_icon_button_clicked(Gtk.Button button) {
        if (this.icon_window == null) {
            this.icon_window = new IconSelectWindow(this.window);
            this.icon_window.on_ok.connect((icon) => {
                set_icon(icon);
            });
        }

        this.icon_window.show();
        this.icon_window.set_icon(this.icon_name);
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the OK-button is pressed.
    /////////////////////////////////////////////////////////////////////

    private void on_ok_button_clicked() {
        if (this.trigger.name != "") {
            var assigned_id = PieManager.get_assigned_id(this.trigger);
            
            if (assigned_id != "" && assigned_id != this.id) {
                // it's already assigned
                var error = _("This hotkey is already assigned to the pie \"%s\"! \n\nPlease select " +
                              "another one or cancel your selection.").printf(PieManager.get_name_of(assigned_id));
                var dialog = new Gtk.MessageDialog((Gtk.Window)this.window.get_toplevel(), Gtk.DialogFlags.MODAL,
                                                   Gtk.MessageType.ERROR, Gtk.ButtonsType.CANCEL, error);
                dialog.run();
                dialog.destroy();
                return;
            }
        }
        // an unbound or unused hot key has been chosen, great!
        this.on_ok(this.trigger, this.name_entry.text, this.icon_name);
        this.window.hide();
    }

    /////////////////////////////////////////////////////////////////////
    /// Sets the icon of the icon_button
    /////////////////////////////////////////////////////////////////////

    private void set_icon(string name) {
        this.icon_name = name;

        if (name.contains("/")) {
            try {
                this.icon.pixbuf = new Gdk.Pixbuf.from_file_at_scale(name,
                                        this.icon.get_pixel_size(), this.icon.get_pixel_size(), true);
            } catch (GLib.Error error) {
                warning(error.message);
            }
        } else {
            this.icon.icon_name = name;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the cancel button is pressed.
    /////////////////////////////////////////////////////////////////////

    private void on_cancel_button_clicked() {
        this.window.hide();
    }
}

}
