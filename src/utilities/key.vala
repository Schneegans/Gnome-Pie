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
/// A class which represents a key stroke. It can be used to "press"
/// the associated keys.
/////////////////////////////////////////////////////////////////////////

public class Key : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Some static members, which are often used by this class.
    /////////////////////////////////////////////////////////////////////

    private static X.Display display;

    private static int shift_l_code;
    private static int shift_r_code;
    private static int ctrl_l_code;
    private static int ctrl_r_code;
    private static int alt_l_code;
    private static int alt_r_code;
    private static int super_l_code;
    private static int super_r_code;

    /////////////////////////////////////////////////////////////////////
    /// A human readable form of the Key's accelerator.
    /////////////////////////////////////////////////////////////////////

    public string label { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// The accelerator of the Key.
    /////////////////////////////////////////////////////////////////////

    public string accelerator { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Keycode and modifiers of this stroke.
    /////////////////////////////////////////////////////////////////////

    private int key_code;
    private Gdk.ModifierType modifiers;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members to defaults.
    /////////////////////////////////////////////////////////////////////

    public Key() {
        this.accelerator = "";
        this.modifiers = 0;
        this.key_code = 0;
        this.label = _("Not bound");
    }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public Key.from_string(string stroke) {
        this.accelerator = stroke;

        uint keysym;
        Gtk.accelerator_parse(stroke, out keysym, out this.modifiers);
        this.key_code = display.keysym_to_keycode(keysym);
        this.label = Gtk.accelerator_get_label(keysym, this.modifiers);
    }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public Key.from_values(uint keysym, Gdk.ModifierType modifiers) {
        this.accelerator = Gtk.accelerator_name(keysym, modifiers);
        this.label = Gtk.accelerator_get_label(keysym, modifiers);
        this.key_code = display.keysym_to_keycode(keysym);
        this.modifiers = modifiers;
    }

    /////////////////////////////////////////////////////////////////////
    /// Initializes static members.
    /////////////////////////////////////////////////////////////////////

    static construct {
        display = new X.Display();

        shift_l_code = display.keysym_to_keycode(Gdk.keyval_from_name("Shift_L"));
        shift_r_code = display.keysym_to_keycode(Gdk.keyval_from_name("Shift_R"));
        ctrl_l_code =  display.keysym_to_keycode(Gdk.keyval_from_name("Control_L"));
        ctrl_r_code =  display.keysym_to_keycode(Gdk.keyval_from_name("Control_R"));
        alt_l_code =   display.keysym_to_keycode(Gdk.keyval_from_name("Alt_L"));
        alt_r_code =   display.keysym_to_keycode(Gdk.keyval_from_name("Alt_R"));
        super_l_code = display.keysym_to_keycode(Gdk.keyval_from_name("Super_L"));
        super_r_code = display.keysym_to_keycode(Gdk.keyval_from_name("Super_R"));
    }

    /////////////////////////////////////////////////////////////////////
    /// Simulates the pressing of the Key .
    /////////////////////////////////////////////////////////////////////

    public void press() {
        // store currently pressed modifier keys
        Gdk.ModifierType current_modifiers = get_modifiers();

        // release them and press the desired ones
        release_modifiers(current_modifiers);
        press_modifiers(this.modifiers);

        // send events to X
        display.flush();

        // press and release the actual key
        XTest.fake_key_event(display, this.key_code, true, 0);
        XTest.fake_key_event(display, this.key_code, false, 0);

        // release the pressed modifiers and re-press the keys hold down by the user
        release_modifiers(this.modifiers);
        // press_modifiers(current_modifiers);

        // send events to X
        display.flush();
    }

    /////////////////////////////////////////////////////////////////////
    /// Helper method returning currently hold down modifier keys.
    /////////////////////////////////////////////////////////////////////

    private Gdk.ModifierType get_modifiers() {
        return (Gdk.ModifierType)Gdk.Keymap.get_default().get_modifier_state();
    }

    /////////////////////////////////////////////////////////////////////
    /// Helper method which 'releases' the desired modifier keys.
    /////////////////////////////////////////////////////////////////////

    private void release_modifiers(Gdk.ModifierType modifiers) {
        // since we do not know whether left or right version of each key
        // is pressed, we release both...
        if ((modifiers & Gdk.ModifierType.CONTROL_MASK) > 0) {
            XTest.fake_key_event(display, ctrl_l_code, false, 0);
            XTest.fake_key_event(display, ctrl_r_code, false, 0);
        }

        if ((modifiers & Gdk.ModifierType.SHIFT_MASK) > 0) {
            XTest.fake_key_event(display, shift_l_code, false, 0);
            XTest.fake_key_event(display, shift_r_code, false, 0);
        }

        if ((modifiers & Gdk.ModifierType.MOD1_MASK) > 0) {
            XTest.fake_key_event(display, alt_l_code, false, 0);
            XTest.fake_key_event(display, alt_r_code, false, 0);
        }

        if ((modifiers & Gdk.ModifierType.SUPER_MASK) > 0) {
            XTest.fake_key_event(display, super_l_code, false, 0);
            XTest.fake_key_event(display, super_r_code, false, 0);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Helper method which 'presses' the desired modifier keys.
    /////////////////////////////////////////////////////////////////////

    private void press_modifiers(Gdk.ModifierType modifiers) {
        if ((modifiers & Gdk.ModifierType.CONTROL_MASK) > 0) {
            XTest.fake_key_event(display, ctrl_l_code, true, 0);
        }

        if ((modifiers & Gdk.ModifierType.SHIFT_MASK) > 0) {
            XTest.fake_key_event(display, shift_l_code, true, 0);
        }

        if ((modifiers & Gdk.ModifierType.MOD1_MASK) > 0) {
            XTest.fake_key_event(display, alt_l_code, true, 0);
        }

        if ((modifiers & Gdk.ModifierType.SUPER_MASK) > 0) {
            XTest.fake_key_event(display, super_l_code, true, 0);
        }
    }
}

}
