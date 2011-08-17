/*
Copyright (c) 2011 by Simon Schneegans

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.
*/

namespace GnomePie {
    
    public class BindingManager : GLib.Object {
    
        public signal void on_press(string id);
        
        // stores bindings, which are invoked even if Gnome-Pie doesn't have the current focus
        private Gee.List<Keybinding> bindings = new Gee.ArrayList<Keybinding>();
     
        // Locked modifiers used to grab all keys whatever lock key is pressed.
        private static uint[] lock_modifiers = {
            0,
            Gdk.ModifierType.MOD2_MASK, // NUM_LOCK
            Gdk.ModifierType.LOCK_MASK, // CAPS_LOCK
            Gdk.ModifierType.MOD5_MASK, // SCROLL_LOCK
            Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK,
            Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.MOD5_MASK,
            Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK,
            Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK
        };
     
        // Helper class to store keybinding
        private class Keybinding {
        
            public Keybinding(int keycode, Gdk.ModifierType modifiers, string id) {
                this.keycode = keycode;
                this.modifiers = modifiers;
                this.id = id;
            }
     
            public int keycode { get; set; }
            public Gdk.ModifierType modifiers { get; set; }
            public string id { get; set; }
        }
     
        // c'tor
        public BindingManager() {
            // init filter to retrieve X.Events
            Gdk.Window rootwin = Gdk.get_default_root_window();
            if(rootwin != null) {
                rootwin.add_filter(event_filter);
            }
        }
         
        public void bind(string accelerator, string id) {
     
            uint keysym;
            Gdk.ModifierType modifiers;
            Gtk.accelerator_parse(accelerator, out keysym, out modifiers);
            
            if (keysym == 0) {
                warning("Invalid keystroke: " + accelerator);
                return;
            }
     
            Gdk.Window rootwin = Gdk.get_default_root_window();
            X.Display display = Gdk.x11_drawable_get_xdisplay(rootwin);
            X.ID xid = Gdk.x11_drawable_get_xid(rootwin);
            int keycode = display.keysym_to_keycode(keysym);
     
            if(keycode != 0) {
                Gdk.error_trap_push();
     
                foreach(uint lock_modifier in lock_modifiers) {
                    display.grab_key(keycode, modifiers|lock_modifier, xid, false, X.GrabMode.Async, X.GrabMode.Async);
                }
     
                Gdk.flush();
     
                Keybinding binding = new Keybinding(keycode, modifiers, id);
                bindings.add(binding);
            }
        }
     
        public void unbind(string id) {
            Gdk.Window rootwin = Gdk.get_default_root_window();
            X.Display display = Gdk.x11_drawable_get_xdisplay(rootwin);
            X.ID xid = Gdk.x11_drawable_get_xid(rootwin);
            Gee.List<Keybinding> remove_bindings = new Gee.ArrayList<Keybinding>();
            foreach(var binding in bindings) {
                if(id == binding.id) {
                    foreach(uint lock_modifier in lock_modifiers) {
                        display.ungrab_key(binding.keycode, binding.modifiers, xid);
                    }
                    remove_bindings.add(binding);
                }
            }

            bindings.remove_all(remove_bindings);
        }
     
        // Event filter method needed to fetch X.Events
        private Gdk.FilterReturn event_filter(Gdk.XEvent gdk_xevent, Gdk.Event gdk_event) {
            Gdk.FilterReturn filter_return = Gdk.FilterReturn.CONTINUE;
     
            void* pointer = &gdk_xevent;
            X.Event* xevent = (X.Event*) pointer;
     
            if(xevent->type == X.EventType.KeyPress) {
                foreach(var binding in bindings) {
                    // remove NumLock, CapsLock and ScrollLock from key state
                    uint event_mods = xevent.xkey.state & ~ (lock_modifiers[7]);
                    if(xevent->xkey.keycode == binding.keycode && event_mods == binding.modifiers) {
                        on_press(binding.id);
                    }
                }
             } 
     
            return filter_return;
        }
    }

}
