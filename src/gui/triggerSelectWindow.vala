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
/// This window allows the selection of a hotkey. It is returned in form
/// of a Trigger. Therefore it can be either a keyboard driven hotkey or
/// a mouse based hotkey.
/////////////////////////////////////////////////////////////////////////

public class TriggerSelectWindow : GLib.Object {
    
    /////////////////////////////////////////////////////////////////////
    /// This signal is emitted when the user selects a new hot key.
    /////////////////////////////////////////////////////////////////////
    
    public signal void on_ok(Trigger trigger);
    
    /////////////////////////////////////////////////////////////////////
    /// Some private members which are needed by other methods.
    /////////////////////////////////////////////////////////////////////
    
    private Gtk.Window window;
    private Gtk.CheckButton turbo;
    private Gtk.CheckButton delayed;
    private Gtk.CheckButton centered;
    private Gtk.Label preview;
    
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
    /// These modifiers are ignored.
    /////////////////////////////////////////////////////////////////////
    
    private Gdk.ModifierType lock_modifiers = Gdk.ModifierType.MOD2_MASK
                                             |Gdk.ModifierType.LOCK_MASK
                                             |Gdk.ModifierType.MOD5_MASK;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs a new TriggerSelectWindow.
    /////////////////////////////////////////////////////////////////////
    
    public TriggerSelectWindow() {
        try {
        
            Gtk.Builder builder = new Gtk.Builder();

            builder.add_from_file (Paths.ui_files + "/trigger_select.ui");

            this.window = builder.get_object("window") as Gtk.Window;
            this.preview = builder.get_object("trigger-label") as Gtk.Label;
            
            (builder.get_object("ok-button") as Gtk.Button).clicked.connect(this.on_ok_button_clicked);
            (builder.get_object("cancel-button") as Gtk.Button).clicked.connect(this.on_cancel_button_clicked);
            (builder.get_object("trigger-box") as Gtk.EventBox).button_press_event.connect(this.on_area_clicked);
            
            this.turbo = builder.get_object("turbo-check") as Gtk.CheckButton;
            this.turbo.toggled.connect(this.on_check_toggled);
            
            this.delayed = builder.get_object("delay-check") as Gtk.CheckButton;
            this.delayed.toggled.connect(this.on_check_toggled);
            
            this.centered = builder.get_object("center-check") as Gtk.CheckButton;
            this.centered.toggled.connect(this.on_check_toggled);
            
            this.window.key_press_event.connect(this.on_key_press);
            this.window.button_press_event.connect(this.on_button_press);
            
            this.window.show.connect_after(() => {
                FocusGrabber.grab(this.window.get_window());
            });
            
            this.window.hide.connect(() => {
                FocusGrabber.ungrab();
            });
                
        } catch (GLib.Error e) {
            error("Could not load UI: %s\n", e.message);
        }
    }
    
    public void set_parent(Gtk.Window parent) {
        this.window.set_transient_for(parent);
    }
    
    public void show() {
        this.window.show_all();
    }
    
    public void set_pie(string id) {
        var trigger = new Trigger.from_string(PieManager.get_accelerator_of(id));
        
        this.turbo.active = trigger.turbo;
        this.delayed.active = trigger.delayed;
        this.centered.active = trigger.centered;
        this.original_trigger = trigger;
        this.update_trigger(trigger);
    }
    
    private void on_check_toggled() {
        if (this.trigger != null)
            this.update_trigger(new Trigger.from_values(this.trigger.key_sym, this.trigger.modifiers,
                                                        this.trigger.with_mouse, this.turbo.active,
                                                        this.delayed.active, this.centered.active));
    }
    
    private void on_ok_button_clicked() {
        var assigned_id = PieManager.get_assigned_id(this.trigger);
    
        if (this.trigger == this.original_trigger) {
            // nothing did change
            this.window.hide();
        } else if (this.trigger.key_code == this.original_trigger.key_code
                && this.trigger.modifiers == this.original_trigger.modifiers
                && this.trigger.with_mouse == this.original_trigger.with_mouse) {
            // only turbo and/or delayed mode changed, no need to check for double assignment
            this.on_ok(this.trigger);
            this.window.hide();
        } else if (assigned_id != "") {
            // it's already assigned
            var error = _("This hotkey is already assigned to the pie \"%s\"! \n\nPlease select " +
                          "another one or cancel your selection.").printf(PieManager.get_name_of(assigned_id));
            var dialog = new Gtk.MessageDialog((Gtk.Window)this.window.get_toplevel(), Gtk.DialogFlags.MODAL,
                                               Gtk.MessageType.ERROR, Gtk.ButtonsType.CANCEL, error);
            dialog.run();
            dialog.destroy();
        } else {
            // a unused hot key has been chosen, great!
            this.on_ok(this.trigger);
            this.window.hide();
        }
    }
    
    private void on_cancel_button_clicked() {
        this.window.hide();
    } 
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the user clicks in the click area.
    /////////////////////////////////////////////////////////////////////
    
    private bool on_area_clicked(Gdk.EventButton event) {
        Gdk.ModifierType state = event.state & ~ this.lock_modifiers;
        
        var new_trigger = new Trigger.from_values((int)event.button, state, true,
                                                  this.turbo.active, this.delayed.active, this.centered.active);
        if (new_trigger.key_code == 1) {
            var dialog = new Gtk.MessageDialog((Gtk.Window)this.window.get_toplevel(), Gtk.DialogFlags.MODAL,
                                                Gtk.MessageType.WARNING,
                                                Gtk.ButtonsType.YES_NO,
                                                _("It possible to make your system unusable if " +
                                                  "you bind a Pie to your left mouse button. Do " +
                                                  "you really want to do this?"));
                                                 
            dialog.response.connect((response) => {
                if (response == Gtk.ResponseType.YES) {
                    this.update_trigger(new_trigger);
                }
            });
            
            dialog.run();
            dialog.destroy();
        } else {
            this.update_trigger(new_trigger);
        }
        
        return true;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the user presses a keyboard key.
    /////////////////////////////////////////////////////////////////////
    
    private bool on_key_press(Gdk.EventKey event) {
        if (Gdk.keyval_name(event.keyval) == "Escape") {
            this.window.hide();
        } else if (Gdk.keyval_name(event.keyval) == "BackSpace") {
            this.update_trigger(new Trigger());
        } else if (event.is_modifier == 0) {
            Gdk.ModifierType state = event.state & ~ this.lock_modifiers;
            this.update_trigger(new Trigger.from_values((int)event.keyval, state, false,
                                                   this.turbo.active, this.delayed.active, this.centered.active));
        }
        
        return true;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the user presses a mouse button.
    /////////////////////////////////////////////////////////////////////
    
    private bool on_button_press(Gdk.EventButton event) {
        int width = 0, height = 0;
        this.window.window.get_geometry(null, null, out width, out height, null);
        if (event.x < 0 || event.x > width || event.y < 0 || event.y > height)
            this.window.hide();
        return true;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Helper method to update the content of the trigger preview label.
    /////////////////////////////////////////////////////////////////////
    
    private void update_trigger(Trigger new_trigger) {
        this.trigger = new_trigger;
        this.preview.set_markup("<big><b>" + this.trigger.label + "</b></big>");
    }  
}

}
