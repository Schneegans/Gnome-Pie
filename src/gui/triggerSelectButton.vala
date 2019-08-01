/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2019 Simon Schneegans
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
/////////////////////////////////////////////////////////////////////////

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
    /// The currently contained Trigger.
    /////////////////////////////////////////////////////////////////////

    private Trigger trigger = null;

    /////////////////////////////////////////////////////////////////////
    /// True, if mouse buttons can be bound as well.
    /////////////////////////////////////////////////////////////////////

    private bool enable_mouse = false;

    /////////////////////////////////////////////////////////////////////
    /// These modifiers are ignored.
    /////////////////////////////////////////////////////////////////////

    private Gdk.ModifierType lock_modifiers = Gdk.ModifierType.MOD2_MASK
                                             |Gdk.ModifierType.MOD4_MASK
                                             |Gdk.ModifierType.MOD5_MASK
                                             |Gdk.ModifierType.LOCK_MASK;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs a new TriggerSelectButton.
    /////////////////////////////////////////////////////////////////////

    public TriggerSelectButton(bool enable_mouse) {
        this.enable_mouse = enable_mouse;

        this.toggled.connect(() => {
            if (this.active) {
                this.set_label(_("Press a hotkey ..."));
                Gtk.grab_add(this);
                FocusGrabber.grab(this.get_window());
            }
        });

        this.button_press_event.connect(this.on_button_press);
        this.key_press_event.connect(this.on_key_press);
        this.set_trigger(new Trigger());
    }

    /////////////////////////////////////////////////////////////////////
    /// Makes the button display the given Trigger.
    /////////////////////////////////////////////////////////////////////

    public void set_trigger(Trigger trigger) {
        this.trigger = trigger;
        this.set_label(trigger.label);
    }

    /////////////////////////////////////////////////////////////////////
    /// Can be called to cancel the selection process.
    /////////////////////////////////////////////////////////////////////

    private void cancel() {
        this.set_label(trigger.label);
        this.set_active(false);
        Gtk.grab_remove(this);
        FocusGrabber.ungrab();
    }

    /////////////////////////////////////////////////////////////////////
    /// Makes the button display the given Trigger.
    /////////////////////////////////////////////////////////////////////

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
                this.update_trigger(new Trigger.from_values(event.keyval, state, false, false, false,
                            false, false, 5));
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
            if (event.x < 0 || event.x > rect.width
             || event.y < 0 || event.y > rect.height) {

                this.cancel();
                return true;
            }
        }

        if (this.active && this.enable_mouse) {
            Gdk.ModifierType state = event.state & ~ this.lock_modifiers;
            var new_trigger = new Trigger.from_values((int)event.button, state, true,
                                                      false, false, false, false, 5);

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
