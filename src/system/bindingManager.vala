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
    
    public class BindingManager : GLib.Object {
    
        // Keybinding func needed to bind key to handler
        public delegate void HandlerFunc();
        
        // stores bindings, which are invoked even if Gnome-Pie doesn't have the current focus
        private Gee.List<Keybinding> _global_bindings = new Gee.ArrayList<Keybinding>();
        
        // stores bindings, which are only activated when Gnome-Pie has focus
        private Gee.List<Keybinding> _local_bindings = new Gee.ArrayList<Keybinding>();
     
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
        
            public Keybinding(string accelerator, int keycode, Gdk.ModifierType modifiers, bool down, HandlerFunc handler) {
                this.accelerator = accelerator;
                this.keycode = keycode;
                this.modifiers = modifiers;
                this.down = down;
                this.handler = handler;
            }
     
            public string accelerator { get; set; }
            public int keycode { get; set; }
            public Gdk.ModifierType modifiers { get; set; }
            public bool down { get; set; }
            public HandlerFunc handler { get; set; }
        }
     
        // c'tor
        public BindingManager() {
            // init filter to retrieve X.Events
            Gdk.Window rootwin = Gdk.get_default_root_window();
            if(rootwin != null) {
                rootwin.add_filter(event_filter);
            }
        }
        
        // public interface
        public void bind_global_press(string stroke, HandlerFunc handler) {
            bind_global(stroke, true, handler);
        }
        
        public void bind_local_press(string stroke, HandlerFunc handler) {
            bind_local(stroke, true, handler);
        }
        
        public void bind_global_release(string stroke, HandlerFunc handler) {
            bind_global(stroke, false, handler);
        }
        
        public void bind_local_release(string stroke, HandlerFunc handler) {
            bind_local(stroke, false, handler);
        }
        
        public void on_key_press(uint keyval, Gdk.ModifierType modifiers) {
            on_local_key(keyval, modifiers, true);
        }
        
        public void on_key_release(uint keyval, Gdk.ModifierType modifiers) {
            on_local_key(keyval, modifiers, false);
        }
     
        // private stuff
        private void bind_global(string accelerator, bool down, HandlerFunc handler) {
     
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
     
                Keybinding binding = new Keybinding(accelerator, keycode, modifiers, down, handler);
                _global_bindings.add(binding);
            }
        }
        
        private void bind_local(string accelerator, bool down, HandlerFunc handler) {
     
            uint keysym;
            Gdk.ModifierType modifiers;
            Gtk.accelerator_parse(accelerator, out keysym, out modifiers);
            
            if (keysym == 0) {
                warning("Invalid keystroke: " + accelerator);
                return;
            }
     
            Gdk.Window rootwin = Gdk.get_default_root_window();     
            X.Display display = Gdk.x11_drawable_get_xdisplay(rootwin);
            int keycode = display.keysym_to_keycode(keysym);            
     
            if(keycode != 0) {
                Keybinding binding = new Keybinding(accelerator, keycode, modifiers, down, handler);
                _local_bindings.add(binding);
            }
        }
        
        private void on_local_key(uint keyval, Gdk.ModifierType modifiers, bool down) {
            Gdk.Window rootwin = Gdk.get_default_root_window();     
            X.Display display = Gdk.x11_drawable_get_xdisplay(rootwin);
            int keycode = display.keysym_to_keycode(keyval);
        
            foreach(Keybinding binding in _local_bindings) {
                // remove NumLock, CapsLock and ScrollLock from key state
                uint event_mods = modifiers & ~ (lock_modifiers[7]);
                if(down) {
                    if(binding.down == true && keycode == binding.keycode && event_mods == binding.modifiers) {
                        binding.handler();
                    }
                } else {
                    if(binding.down == false && (keycode == binding.keycode || ((event_mods | binding.modifiers) > 0))) {
                        binding.handler();
                    }
                }
            }
        }
     
        // Unbind given accelerator.
        /*private void unbind(string accelerator) {
     
            Gdk.Window rootwin = Gdk.get_default_root_window();     
            X.Display display = Gdk.x11_drawable_get_xdisplay(rootwin);
            X.ID xid = Gdk.x11_drawable_get_xid(rootwin);
     
            // unbind all keys with given accelerator
            Gee.List<Keybinding> remove_bindings = new Gee.ArrayList<Keybinding>();
            foreach(Keybinding binding in _bindings) {
                if(str_equal(accelerator, binding.accelerator)) {
                    foreach(uint lock_modifier in lock_modifiers) {
                        display.ungrab_key(binding.keycode, binding.modifiers, xid);
                    }
                    remove_bindings.add(binding);                    
                }
            }
     
            // remove unbinded keys
            _bindings.remove_all(remove_bindings);
        }*/
     
        // Event filter method needed to fetch X.Events
        private Gdk.FilterReturn event_filter(Gdk.XEvent gdk_xevent, Gdk.Event gdk_event) {
            Gdk.FilterReturn filter_return = Gdk.FilterReturn.CONTINUE;
     
            void* pointer = &gdk_xevent;
            X.Event* xevent = (X.Event*) pointer;
     
            if(xevent->type == X.EventType.KeyPress) {
                foreach(Keybinding binding in _global_bindings) {
                    // remove NumLock, CapsLock and ScrollLock from key state
                    uint event_mods = xevent.xkey.state & ~ (lock_modifiers[7]);
                    if(binding.down && xevent->xkey.keycode == binding.keycode && event_mods == binding.modifiers) {
                        binding.handler();
                    }
                }
             } else if(xevent->type == X.EventType.KeyRelease) {
                foreach(Keybinding binding in _global_bindings) {
                    // remove NumLock, CapsLock and ScrollLock from key state
                    uint event_mods = xevent.xkey.state & ~ (lock_modifiers[7]);
                    if(!binding.down && xevent->xkey.keycode == binding.keycode && event_mods == binding.modifiers) {
                        binding.handler();
                    }
                }
             }
     
            return filter_return;
        }
    }

}
