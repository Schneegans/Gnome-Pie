/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2021 Simon Schneegans
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

    public static Gdk.ModifierType get_modifiers() {
        return (Gdk.ModifierType)Gdk.Keymap.get_for_display(
                Gdk.Display.get_default()).get_modifier_state();
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
