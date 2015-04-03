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
/// This class represents a hotkey, used to open pies. It supports any
/// combination of modifier keys with keyboard and mouse buttons.
/////////////////////////////////////////////////////////////////////////

public class Trigger : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Returns a human-readable version of this Trigger.
    /////////////////////////////////////////////////////////////////////

    public string label { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// Returns a human-readable version of this Trigger. Small
    /// identifiers for turbo mode and delayed mode are added.
    /////////////////////////////////////////////////////////////////////

    public string label_with_specials { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// The Trigger string. Like [delayed]<Control>button3
    /////////////////////////////////////////////////////////////////////

    public string name { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// The key code of the hotkey or the button number of the mouse.
    /////////////////////////////////////////////////////////////////////

    public int key_code { get; private set; default=0; }

    /////////////////////////////////////////////////////////////////////
    /// The keysym of the hotkey or the button number of the mouse.
    /////////////////////////////////////////////////////////////////////

    public uint key_sym { get; private set; default=0; }

    /////////////////////////////////////////////////////////////////////
    /// Modifier keys pressed for this hotkey.
    /////////////////////////////////////////////////////////////////////

    public Gdk.ModifierType modifiers { get; private set; default=0; }

    /////////////////////////////////////////////////////////////////////
    /// True if this hotkey involves the mouse.
    /////////////////////////////////////////////////////////////////////

    public bool with_mouse { get; private set; default=false; }

    /////////////////////////////////////////////////////////////////////
    /// True if the pie closes when the trigger hotkey is released.
    /////////////////////////////////////////////////////////////////////

    public bool turbo { get; private set; default=false; }

    /////////////////////////////////////////////////////////////////////
    /// True if the trigger should wait a short delay before being
    /// triggered.
    /////////////////////////////////////////////////////////////////////

    public bool delayed { get; private set; default=false; }

    /////////////////////////////////////////////////////////////////////
    /// True if the pie opens in the middle of the screen.
    /////////////////////////////////////////////////////////////////////

    public bool centered { get; private set; default=false; }

    /////////////////////////////////////////////////////////////////////
    /// True if the pie selects its shape to minimize mouse traveling
    /////////////////////////////////////////////////////////////////////

    public bool auto_shape { get; private set; default=false; }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates a new, "unbound" Trigger.
    /////////////////////////////////////////////////////////////////////

    public Trigger() {
        this.set_unbound();
    }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates a new Trigger from a given Trigger string. This is
    /// in this format: "[option(s)]<modifier(s)>button" where
    /// "<modifier>" is something like "<Alt>" or "<Control>", "button"
    /// something like "s", "F4" or "button0" and "[option]" is either
    /// "[turbo]", "[centered]", "["delayed"]" or "["auto_shape"]".
    /////////////////////////////////////////////////////////////////////

    public Trigger.from_string(string trigger) {
        this.parse_string(trigger);
    }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates a new Trigger from the key values.
    /////////////////////////////////////////////////////////////////////

    public Trigger.from_values(uint key_sym, Gdk.ModifierType modifiers,
                               bool with_mouse, bool turbo, bool delayed,
                               bool centered, bool auto_shape ) {

        string trigger = (turbo ? "[turbo]" : "")
                       + (delayed ? "[delayed]" : "")
                       + (centered ? "[centered]" : "")
                       + (auto_shape ? "[auto_shape]" : "");

        if (with_mouse) {
            trigger += Gtk.accelerator_name(0, modifiers) + "button%u".printf(key_sym);
        } else {
            trigger += Gtk.accelerator_name(key_sym, modifiers);
        }

        this.parse_string(trigger);
    }

    /////////////////////////////////////////////////////////////////////
    /// Parses a Trigger string. This is
    /// in this format: "[option(s)]<modifier(s)>button" where
    /// "<modifier>" is something like "<Alt>" or "<Control>", "button"
    /// something like "s", "F4" or "button0" and "[option]" is either
    /// "[turbo]", "[centered]", "["delayed"]" or "["auto_shape"]".
    /////////////////////////////////////////////////////////////////////

    public void parse_string(string trigger) {
        if (this.is_valid(trigger)) {
            // copy string
            string check_string = trigger;

            this.name = check_string;

            this.turbo = check_string.contains("[turbo]");
            this.delayed = check_string.contains("[delayed]");
            this.centered = check_string.contains("[centered]");
            this.auto_shape = check_string.contains("[auto_shape]");

            // remove optional arguments
            check_string = check_string.replace("[turbo]", "");
            check_string = check_string.replace("[delayed]", "");
            check_string = check_string.replace("[centered]", "");
            check_string = check_string.replace("[auto_shape]", "");

            int button = this.get_mouse_button(check_string);
            if (button > 0) {
                this.with_mouse = true;
                this.key_code = button;
                this.key_sym = button;

                Gtk.accelerator_parse(check_string, null, out this._modifiers);
                this.label = Gtk.accelerator_get_label(0, this.modifiers);

                string button_text = _("Button %i").printf(this.key_code);

                if (this.key_code == 1)
                    button_text = _("LeftButton");
                else if (this.key_code == 3)
                    button_text = _("RightButton");
                else if (this.key_code == 2)
                    button_text = _("MiddleButton");

                this.label += button_text;
            } else {
                this.with_mouse = false;

                var display = new X.Display();

                uint keysym = 0;
                Gtk.accelerator_parse(check_string, out keysym, out this._modifiers);
                this.key_code = display.keysym_to_keycode(keysym);
                this.key_sym = keysym;
                this.label = Gtk.accelerator_get_label(keysym, this.modifiers);
            }

            this.label_with_specials = GLib.Markup.escape_text(this.label);

            string msg= "";
            if (this.turbo) {
                msg= _("Turbo");
            }
            if (this.delayed) {
                if (msg == "")
                    msg= _("Delayed");
                else
                    msg += " | " + _("Delayed");
            }
            if (this.centered) {
                if (msg == "")
                    msg= _("Centered");
                else
                    msg += " | " + _("Centered");
            }
            if (this.auto_shape) {
                if (msg == "")
                    msg= _("Auto-shaped");
                else
                    msg += " | " + _("Auto-shaped");
            }
            if (msg != "")
                this.label_with_specials += ("  <small><span weight='light'>[ " + msg + " ]</span></small>");

        } else {
            this.set_unbound();
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Resets all member variables to their defaults.
    /////////////////////////////////////////////////////////////////////

    private void set_unbound() {
        this.label = _("Not bound");
        this.label_with_specials = _("Not bound");
        this.name = "";
        this.key_code = 0;
        this.key_sym = 0;
        this.modifiers = 0;
        this.turbo = false;
        this.delayed = false;
        this.auto_shape = false;
        this.with_mouse = false;
    }

    /////////////////////////////////////////////////////////////////////
    /// Remove "[turbo]", "[delayed]", "[centered]" and "[auto_shape]"
    /// from the given string 
    /////////////////////////////////////////////////////////////////////
    
    public static string remove_flags(string trigger) {
        string trg= trigger;
        trg = trg.replace("[turbo]", "");
        trg = trg.replace("[delayed]", "");
        trg = trg.replace("[centered]", "");
        trg = trg.replace("[auto_shape]", "");
        return trg;
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns true, if the trigger string is in a valid format.
    /////////////////////////////////////////////////////////////////////

    private bool is_valid(string trigger) {
        // remove optional arguments
        string check_string = remove_flags(trigger);

        if (this.get_mouse_button(check_string) > 0) {
            // it seems to be a valid mouse-trigger so replace button part,
            // with something accepted by gtk, and check it with gtk
            int button_index = check_string.index_of("button");
            check_string = check_string.slice(0, button_index) + "a";
        }

        // now it shouls be a normal gtk accelerator
        uint keysym = 0;
        Gdk.ModifierType modifiers = 0;
        Gtk.accelerator_parse(check_string, out keysym, out modifiers);
        if (keysym == 0)
            return false;

        return true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the mouse button number of the given trigger string.
    /// Returns -1 if it is not a mouse trigger.
    /////////////////////////////////////////////////////////////////////

    private int get_mouse_button(string trigger) {
        if (trigger.contains("button")) {
            // it seems to be a mouse-trigger so check the button part.
            int button_index = trigger.index_of("button");
            int number = int.parse(trigger.slice(button_index + 6, trigger.length));
            if (number > 0)
                return number;
        }

        return -1;
    }
}

}
