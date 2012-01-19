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

public class TriggerSelectButton : Gtk.ToggleButton {
    
    /////////////////////////////////////////////////////////////////////
    /// This signal is emitted when the user selects a new hot key.
    /////////////////////////////////////////////////////////////////////
    
    public signal void on_select(Trigger trigger);
    
    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////
    
    private Trigger trigger = null;
     
    private bool enable_mouse = false;
    
    /////////////////////////////////////////////////////////////////////
    /// These modifiers are ignored.
    /////////////////////////////////////////////////////////////////////
    
    private Gdk.ModifierType lock_modifiers = Gdk.ModifierType.MOD2_MASK
                                             |Gdk.ModifierType.LOCK_MASK
                                             |Gdk.ModifierType.MOD5_MASK;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs a new TriggerSelectWindow.
    /////////////////////////////////////////////////////////////////////
    
    public TriggerSelectButton(bool enable_mouse) {
        this.enable_mouse = enable_mouse;
    
        this.toggled.connect(() => {
            if (this.active) {
                this.set_label(_("Press a hotkey ..."));
                Gtk.grab_add(this);
                FocusGrabber.grab(this.get_window(), true, true, true);
            }
        });
        
        this.button_press_event.connect(this.on_button_press);
        this.key_press_event.connect(this.on_key_press);
        this.set_trigger(new Trigger());
    }
    
    public void set_trigger(Trigger trigger) {
        this.trigger = trigger;
        this.set_label(trigger.label);
    }
    
    private void cancel() {
        this.set_label(trigger.label);
        this.set_active(false);
        Gtk.grab_remove(this);
        FocusGrabber.ungrab(true, true);
    }
    
    private void update_trigger(Trigger trigger) {
        if (this.trigger.name != trigger.name) {
            this.set_trigger(trigger);
            this.on_select(this.trigger);
        }
        
        this.cancel();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the user presses a keyboard key.
    /////////////////////////////////////////////////////////////////////
    
    private bool on_key_press(Gdk.EventKey event) {
        if (this.active) {
            if (Gdk.keyval_name(event.keyval) == "Escape") {
                this.cancel();
            } else if (Gdk.keyval_name(event.keyval) == "BackSpace") {
                this.update_trigger(new Trigger());
            } else if (event.is_modifier == 0) {
                Gdk.ModifierType state = event.state & ~ this.lock_modifiers;
                this.update_trigger(new Trigger.from_values(event.keyval, state, false, false, false, false));
            }
            
            return true;
        }
        return false;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the user presses a button of the mouse.
    /////////////////////////////////////////////////////////////////////
    
    private bool on_button_press(Gdk.EventButton event) {
        if (this.active) {
                Gtk.Allocation rect;
                this.get_allocation(out rect);
                if (event.x < rect.x || event.x > rect.x + rect.width
                 || event.y < rect.y || event.y > rect.y + rect.height) {
                 
                    this.cancel();
                    return true;
                }
            }
            
            if (this.active && this.enable_mouse) {
                Gdk.ModifierType state = event.state & ~ this.lock_modifiers;
                var new_trigger = new Trigger.from_values((int)event.button, state, true,
                                                          false, false, false);
                                                          
                if (new_trigger.key_code != 1) this.update_trigger(new_trigger);
                else                           this.cancel();
                
                return true;
            } else if (this.active) {
                this.cancel();
                return true;
            }
            
            return false;
    }
}

}
