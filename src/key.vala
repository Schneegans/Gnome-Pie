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

    public class Key : GLib.Object {
    
        private static X.Display display;
        private static int shift_code;
        private static int ctrl_code;
        private static int alt_code;
        private static int super_code;
        
        private static bool need_init = true;

        public static void press(string stroke) {
            
            if (need_init) init();

	        uint keysym;
            Gdk.ModifierType modifiers;
            Gtk.accelerator_parse(stroke, out keysym, out modifiers);
            int keycode = display.keysym_to_keycode(keysym);

            if ((modifiers & Gdk.ModifierType.CONTROL_MASK) > 0)
                X.Test.fake_key_event(display, ctrl_code, true, 0);
                
            if ((modifiers & Gdk.ModifierType.SHIFT_MASK) > 0)
                X.Test.fake_key_event(display, shift_code, true, 0);
                
            if ((modifiers & Gdk.ModifierType.MOD1_MASK) > 0)
                X.Test.fake_key_event(display, alt_code, true, 0);
                
            if ((modifiers & Gdk.ModifierType.SUPER_MASK) > 0)
                X.Test.fake_key_event(display, super_code, true, 0);

	        X.Test.fake_key_event(display, keycode, true, 0);
	        X.Test.fake_key_event(display, keycode, false, 0);
	
	        if ((modifiers & Gdk.ModifierType.CONTROL_MASK) > 0)
                X.Test.fake_key_event(display, ctrl_code, false, 0);
	
	        if ((modifiers & Gdk.ModifierType.SHIFT_MASK) > 0)
                X.Test.fake_key_event(display, shift_code, false, 0);
                
            if ((modifiers & Gdk.ModifierType.MOD1_MASK) > 0)
                X.Test.fake_key_event(display, alt_code, false, 0);
	
	        if ((modifiers & Gdk.ModifierType.SUPER_MASK) > 0)
                X.Test.fake_key_event(display, super_code, false, 0);

	        display.flush();
	
	        //string accel = Gtk.accelerator_get_label (keysym, modifiers);
            //debug("key: %s keysum: %u keycode: %i", accel, keysym, keycode);
        }
        
        private static void init() {
            display = new X.Display();
            
            shift_code = display.keysym_to_keycode(Gdk.keyval_from_name("Shift_L"));
            ctrl_code  = display.keysym_to_keycode(Gdk.keyval_from_name("Control_L"));
            alt_code  = display.keysym_to_keycode(Gdk.keyval_from_name("Alt_L"));
            super_code  = display.keysym_to_keycode(Gdk.keyval_from_name("Super_L"));
            
            need_init = false;
        }
	}
}
