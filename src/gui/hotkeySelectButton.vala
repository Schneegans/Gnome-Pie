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

public class HotkeySelectButton : Gtk.ToggleButton {
    
    /////////////////////////////////////////////////////////////////////
    /// This signal is emitted when the user selects a new hot key.
    /////////////////////////////////////////////////////////////////////
    
    public signal void on_select(Key key);
    
    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////
    
    private Key key = null;
    
    /////////////////////////////////////////////////////////////////////
    /// These modifiers are ignored.
    /////////////////////////////////////////////////////////////////////
    
    private Gdk.ModifierType lock_modifiers = Gdk.ModifierType.MOD2_MASK
                                             |Gdk.ModifierType.LOCK_MASK
                                             |Gdk.ModifierType.MOD5_MASK;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs a new TriggerSelectWindow.
    /////////////////////////////////////////////////////////////////////
    
    public HotkeySelectButton() {
        this.toggled.connect_after(() => {
            if (this.active) {
                this.set_label(_("Press a hotkey ..."));
                FocusGrabber.grab(this.get_window(), true, false);
            }
        });
        
        this.focus_out_event.connect(() => {
            if (this.active) {
                this.cancel();
                return true;
            }
            return false;
        });
        
        this.button_press_event.connect(() => {
            if (this.active) {
                this.cancel();
                return true;
            }
            return false;
        });
        
        this.key_press_event.connect(this.on_key_press);
        this.set_key(new Key());
    }
    
    public void set_key(Key key) {
        this.key = key;
        this.set_label(key.label);
    }
    
    private void cancel() {
        this.set_label(key.label);
        this.set_active(false);
        FocusGrabber.ungrab(true, false);
    }
    
    private void update_key(Key key) {
        if (this.key.accelerator != key.accelerator) {
            this.key = key;
            this.on_select(this.key);
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
                this.update_key(new Key());
            } else if (event.is_modifier == 0) {
                Gdk.ModifierType state = event.state & ~ this.lock_modifiers;
                this.update_key(new Key.from_values(event.keyval, state));
            }
            
            return true;
        }
        return false;
    }
    
}

}
