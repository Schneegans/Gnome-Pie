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
    /// True if the mouse pointer is warped to the pie's center.
    /////////////////////////////////////////////////////////////////////

    public bool warp { get; private set; default=false; }

    /////////////////////////////////////////////////////////////////////
    /// Returns the current selected "radio-button" shape: 0= automatic
    /// 5= full pie; 1,3,7,8= quarters; 2,4,6,8=halves
    /// 1 | 4 | 7
    /// 2 | 5 | 8
    /// 3 | 6 | 9
    /////////////////////////////////////////////////////////////////////

    public int shape { get; private set; default=5; }

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
    /// "[turbo]", "[centered]", "[warp]", "["delayed"]" or "["shape#"]"
    /////////////////////////////////////////////////////////////////////

    public Trigger.from_string(string trigger) {
        this.parse_string(trigger);
    }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates a new Trigger from the key values.
    /////////////////////////////////////////////////////////////////////

    public Trigger.from_values(uint key_sym, Gdk.ModifierType modifiers,
                               bool with_mouse, bool turbo, bool delayed,
                               bool centered, bool warp, int shape ) {

        string trigger = (turbo ? "[turbo]" : "")
                       + (delayed ? "[delayed]" : "")
                       + (centered ? "[centered]" : "")
                       + (warp ? "[warp]" : "")
                       + (shape!=5 ? "[shape%d]".printf(shape) : "");

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
    /// "[turbo]", "[centered]", "[warp]", "["delayed"]" or "["shape#"]"
    /////////////////////////////////////////////////////////////////////

    public void parse_string(string trigger) {
        if (this.is_valid(trigger)) {
            // copy string
            string check_string = trigger;

            this.name = check_string;

            this.turbo = check_string.contains("[turbo]");
            this.delayed = check_string.contains("[delayed]");
            this.centered = check_string.contains("[centered]");
            this.warp = check_string.contains("[warp]");

            this.shape= parse_shape( check_string );

            // remove optional arguments
            check_string = remove_optional(check_string);

            int button = this.get_mouse_button(check_string);
            if (button > 0) {
                check_string = check_string.substring(0, check_string.index_of("button"));

                this.with_mouse = true;
                this.key_code = button;
                this.key_sym = button;

                Gtk.accelerator_parse(check_string, null, out this._modifiers);
                this.label = Gtk.accelerator_get_label(0, this.modifiers);

                if (this.label != "") {
                    label += "+";
                }

                string button_text = _("Button %i").printf(this.key_code);

                if (this.key_code == 1)
                    button_text = _("LeftButton");
                else if (this.key_code == 3)
                    button_text = _("RightButton");
                else if (this.key_code == 2)
                    button_text = _("MiddleButton");

                this.label += button_text;
            } else {
                //empty triggers are ok now, they carry open options as well
                if (check_string == "") {
                    this.label = _("Not bound");
                    this.key_code = 0;
                    this.key_sym = 0;
                    this.modifiers = 0;
                } else {
                    this.with_mouse = false;

                    var display = new X.Display();

                    uint keysym = 0;
                    Gtk.accelerator_parse(check_string, out keysym, out this._modifiers);
                    this.key_code = display.keysym_to_keycode(keysym);
                    this.key_sym = keysym;
                    this.label = Gtk.accelerator_get_label(keysym, this.modifiers);
                }
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
            if (this.warp) {
                if (msg == "")
                    msg= _("Warp");
                else
                    msg += " | " + _("Warp");
            }
            if (this.shape == 0) {
                if (msg == "")
                    msg= _("Auto-shaped");
                else
                    msg += " | " + _("Auto-shaped");
            } else if (this.shape == 1 || this.shape ==3 || this.shape == 7 || this.shape == 9) {
                if (msg == "")
                    msg= _("Quarter pie");
                else
                    msg += " | " + _("Quarter pie");

            } else if (this.shape == 2 || this.shape == 4 || this.shape == 6 || this.shape == 8) {
                if (msg == "")
                    msg= _("Half pie");
                else
                    msg += " | " + _("Half pie");
            }
            if (msg != "")
                this.label_with_specials += ("  [ " + msg + " ]");

        } else {
            this.set_unbound();
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Extract shape number from trigger string
    /// "[0]".."[9]" 0:auto 5:full pie (default)
    /// 1,3,7,9=quarters    2,4,6,8= halves
    /////////////////////////////////////////////////////////////////////

    private int parse_shape(string trigger) {
        int rs;
        for( rs= 0; rs < 10; rs++ )
            if (trigger.contains("[shape%d]".printf(rs) ))
                return rs;
        return 5; //default= full pie
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
        this.centered = false;
        this.warp = false;
        this.shape = 5; //full pie
        this.with_mouse = false;
    }

    /////////////////////////////////////////////////////////////////////
    /// Remove optional arguments from the given string
    /// "[turbo]", "[delayed]", "[warp]" "[centered]" and "[shape#]"
    /////////////////////////////////////////////////////////////////////

    public static string remove_optional(string trigger) {
        string trg= trigger;
        trg = trg.replace("[turbo]", "");
        trg = trg.replace("[delayed]", "");
        trg = trg.replace("[centered]", "");
        trg = trg.replace("[warp]", "");
        for (int rs= 0; rs < 10; rs++)
            trg = trg.replace("[shape%d]".printf(rs), "");
        return trg;
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns true, if the trigger string is in a valid format.
    /////////////////////////////////////////////////////////////////////

    private bool is_valid(string trigger) {
        // remove optional arguments
        string check_string = remove_optional(trigger);

        if (this.get_mouse_button(check_string) > 0) {
            // it seems to be a valid mouse-trigger so replace button part,
            // with something accepted by gtk, and check it with gtk
            int button_index = check_string.index_of("button");
            check_string = check_string.slice(0, button_index) + "a";
        }

        //empty triggers are ok now, they carry open options as well
        if (check_string == "")
            return true;

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
