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

public class TriggerSelectWindow : Gtk.Dialog {
    
    /////////////////////////////////////////////////////////////////////
    /// This signal is emitted when the user selects a new hot key.
    /////////////////////////////////////////////////////////////////////
    
    public signal void on_select(Trigger trigger);
    
    /////////////////////////////////////////////////////////////////////
    /// Some private members which are needed by other methods.
    /////////////////////////////////////////////////////////////////////
    
    private Gtk.CheckButton turbo;
    private Gtk.CheckButton delayed;
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
        this.title = _("Define an open-command");
        this.resizable = false;
        this.delete_event.connect(hide_on_delete);
        this.key_press_event.connect(on_key_press);
        this.button_press_event.connect(on_button_press);
        
        this.show.connect_after(() => {
            FocusGrabber.grab(this);
        });
        
        this.hide.connect(() => {
            FocusGrabber.ungrab(this);
        });

        var container = new Gtk.VBox(false, 6);
            container.set_border_width(6);
             
             // click area
             var click_frame = new Gtk.Frame(_("Click here if you want to bind a mouse button!"));
            
                var click_box = new Gtk.EventBox();
                    click_box.height_request = 100;
                    click_box.button_press_event.connect(on_area_clicked);
                    
                    this.preview = new Gtk.Label(null);
                    
                    click_box.add(this.preview);
                    
                click_frame.add(click_box);
                
            container.pack_start(click_frame, false);
            
            // turbo checkbox
            this.turbo = new Gtk.CheckButton.with_label (_("Turbo mode"));
                this.turbo.tooltip_text = _("If checked, the Pie will close when you " + 
                                            "release the chosen hot key.");
                this.turbo.active = false;
                this.turbo.toggled.connect(() => {
                	if (this.trigger != null)
		            	this.update_trigger(new Trigger.from_values(
		            		this.trigger.key_sym, this.trigger.modifiers,
							this.trigger.with_mouse, this.turbo.active,
							this.delayed.active));
                });
                
            container.pack_start(turbo, false);
            
            // delayed checkbox
            this.delayed = new Gtk.CheckButton.with_label (_("Long press for activation"));
                this.delayed.tooltip_text = _("If checked, the Pie will only open if you " + 
                                              "press this hot key a bit longer.");
                this.delayed.active = false;
                this.delayed.toggled.connect(() => {
                	if (this.trigger != null)
		            	this.update_trigger(new Trigger.from_values(
		            		this.trigger.key_sym, this.trigger.modifiers,
							this.trigger.with_mouse, this.turbo.active,
							this.delayed.active));
                });
                
            container.pack_start(delayed, false);

        container.show_all();
        
        this.vbox.pack_start(container, true, true);
        
        this.add_button(Gtk.Stock.CANCEL, 1);
        this.add_button(Gtk.Stock.OK, 0);
        
        // select a new trigger on OK, hide on CANCEL
        this.response.connect((id) => {
        	if (id == 1)
        		this.hide();
        	else if (id == 0) {
        		var assigned_id = PieManager.get_assigned_id(this.trigger);
    
    			
				if (this.trigger == this.original_trigger) {
					// nothing did change
					this.hide();
				} else if (this.trigger.key_code == this.original_trigger.key_code
						   && this.trigger.modifiers == this.original_trigger.modifiers
						   && this.trigger.with_mouse == this.original_trigger.with_mouse
						   && this.trigger.delayed == this.original_trigger.delayed) {
					// only turbo mode changed, no need to check for double assignment
					this.on_select(this.trigger);
				    this.hide();
				} else if (assigned_id != "") {
					// it's already assigned
				    var error = _("This hotkey is already assigned to the pie \"%s\"! \n\nPlease select " +
				                  "another one or cancel your selection.").printf(PieManager.get_name_of(assigned_id));
				    var dialog = new Gtk.MessageDialog((Gtk.Window)this.get_toplevel(), 
				    									Gtk.DialogFlags.MODAL, 
				                                        Gtk.MessageType.ERROR, 
				                                        Gtk.ButtonsType.CANCEL, 
				                                        error);
				    dialog.run();
				    dialog.destroy();
				} else {
					// a unused hot key has been chosen, great!
				    this.on_select(this.trigger);
				    this.hide();
				}
        	}
        });
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Used to set the currently selected trigger on opening.
    /////////////////////////////////////////////////////////////////////
    
    public void set_trigger(Trigger trigger) {
        this.turbo.active = trigger.turbo;
        this.delayed.active = trigger.delayed;
        this.original_trigger = trigger;
        this.update_trigger(trigger);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the user clicks in the click area.
    /////////////////////////////////////////////////////////////////////
    
    private bool on_area_clicked(Gdk.EventButton event) {
        Gdk.ModifierType state = event.state & ~ this.lock_modifiers;
        var new_trigger = new Trigger.from_values((int)event.button, state, true, 
                                                  this.turbo.active, this.delayed.active);
        if (new_trigger.name.contains("button1")) {
            var dialog = new Gtk.MessageDialog((Gtk.Window)this.get_toplevel(), Gtk.DialogFlags.MODAL, 
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
            this.hide();
        } else if (Gdk.keyval_name(event.keyval) == "BackSpace") {
            this.update_trigger(new Trigger());
        } else if (event.is_modifier == 0) {
            Gdk.ModifierType state = event.state & ~ this.lock_modifiers;
            this.update_trigger(new Trigger.from_values((int)event.keyval, state, false, 
                                                   this.turbo.active, this.delayed.active));
        }
        
        return true;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the user presses a mouse button.
    /////////////////////////////////////////////////////////////////////
    
    private bool on_button_press(Gdk.EventButton event) {
        int width = 0, height = 0;
        this.window.get_geometry(null, null, out width, out height, null);
        if (event.x < 0 || event.x > width || event.y < 0 || event.y > height)
            this.hide();
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
