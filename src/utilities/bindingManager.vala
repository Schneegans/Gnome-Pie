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

/////////////////////////////////////////////////////////////////////////    
/// Globally binds key stroke to given ID's. When one of the bound 
/// strokes is invoked, a signal with the according ID is emitted.
/////////////////////////////////////////////////////////////////////////

public class BindingManager : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Called when a stored binding is invoked. The according ID is
    /// passed as argument.
    /////////////////////////////////////////////////////////////////////

    public signal void on_press(string id);
    
    /////////////////////////////////////////////////////////////////////
    /// A list storing bindings, which are invoked even if Gnome-Pie
    /// doesn't have the current focus
    /////////////////////////////////////////////////////////////////////
    
    private Gee.List<Keybinding> bindings = new Gee.ArrayList<Keybinding>();

    /////////////////////////////////////////////////////////////////////
    /// Ignored modifier masks, used to grab all keys even if these locks
    /// are active.
    /////////////////////////////////////////////////////////////////////
    
    private static uint[] lock_modifiers = {
        0,
        Gdk.ModifierType.MOD2_MASK,
        Gdk.ModifierType.LOCK_MASK,
        Gdk.ModifierType.MOD5_MASK,
        
        Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK,
        Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.MOD5_MASK,
        Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK,
        
        Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK
    };
    
    /////////////////////////////////////////////////////////////////////
    /// Some variables to remember which delayed binding was delayed.
    /// When the delay passes without another event indicating that the
    /// Trigger was released, the stored binding will be activated.
    /////////////////////////////////////////////////////////////////////
    
    private uint32 delayed_count = 0;
    private X.Event? delayed_event = null;
    private Keybinding? delayed_binding = null;
 
    /////////////////////////////////////////////////////////////////////
    /// Helper class to store keybinding
    /////////////////////////////////////////////////////////////////////
    
    private class Keybinding {
    
        public Keybinding(Trigger trigger, string id) {
            this.trigger = trigger;
            this.id = id;
        }
 
        public Trigger trigger { get; set; }
        public string id { get; set; }
    }
 
    /////////////////////////////////////////////////////////////////////
    /// C'tor adds the event filter to the root window.
    /////////////////////////////////////////////////////////////////////
    
    public BindingManager() {
        // init filter to retrieve X.Events
        Gdk.Window rootwin = Gdk.get_default_root_window();
        if(rootwin != null) {
            rootwin.add_filter(event_filter);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Binds the ID to the given accelerator.
    /////////////////////////////////////////////////////////////////////
     
    public void bind(Trigger trigger, string id) {
        if(trigger.key_code != 0) {
            X.Display display = Gdk.x11_get_default_xdisplay();
            X.ID xid = Gdk.x11_get_default_root_xwindow();
        
            Gdk.error_trap_push();
 
            foreach(uint lock_modifier in lock_modifiers) {
                if (trigger.with_mouse) {
                    display.grab_button(trigger.key_code, trigger.modifiers|lock_modifier, xid, false,
                                        X.EventMask.ButtonPressMask | X.EventMask.ButtonReleaseMask, 
                                        X.GrabMode.Async, X.GrabMode.Async, xid, 0);
                } else {
                    display.grab_key(trigger.key_code, trigger.modifiers|lock_modifier, 
                                     xid, false, X.GrabMode.Async, X.GrabMode.Async);
                }
            }
 
            Gdk.flush();
 
            Keybinding binding = new Keybinding(trigger, id);
            bindings.add(binding);
            display.flush();
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Unbinds the accelerator of the given ID.
    /////////////////////////////////////////////////////////////////////
 
    public void unbind(string id) {
        X.Display display = Gdk.x11_get_default_xdisplay();
        X.ID xid = Gdk.x11_get_default_root_xwindow();
            
        Gee.List<Keybinding> remove_bindings = new Gee.ArrayList<Keybinding>();
        foreach(var binding in bindings) {
            if(id == binding.id) {
                foreach(uint lock_modifier in lock_modifiers) {
                    if (binding.trigger.with_mouse) {
                        display.ungrab_button(binding.trigger.key_code, binding.trigger.modifiers|lock_modifier, xid);
                    } else {
                        display.ungrab_key(binding.trigger.key_code, binding.trigger.modifiers|lock_modifier, xid);
                    } 
                }
                remove_bindings.add(binding);
            }
        }

        bindings.remove_all(remove_bindings);
        display.flush();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Returns a human readable accelerator for the given ID.
    /////////////////////////////////////////////////////////////////////
    
    public string get_accelerator_label_of(string id) {
        foreach (var binding in bindings) {
            if (binding.id == id) {
                return binding.trigger.label_with_specials;
            }
        }
        
        return _("Not bound");
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Returns the accelerator to which the given ID is bound.
    /////////////////////////////////////////////////////////////////////
    
    public string get_accelerator_of(string id) {
        foreach (var binding in bindings) {
            if (binding.id == id) {
                return binding.trigger.name;
            }
        }
        
        return "";
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Returns whether the pie with the given ID is in turbo mode.
    /////////////////////////////////////////////////////////////////////
    
    public bool get_is_turbo(string id) {
        foreach (var binding in bindings) {
            if (binding.id == id) {
                return binding.trigger.turbo;
            }
        }
        
        return false;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Returns whether the pie with the given ID opens centered.
    /////////////////////////////////////////////////////////////////////
    
    public bool get_is_centered(string id) {
        foreach (var binding in bindings) {
            if (binding.id == id) {
                return binding.trigger.centered;
            }
        }
        
        return false;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Returns the name ID of the Pie bound to the given Trigger.
    /// Returns "" if there is nothing bound to this trigger.
    /////////////////////////////////////////////////////////////////////
    
    public string get_assigned_id(Trigger trigger) {
        foreach (var binding in bindings) {
            var first = binding.trigger.name.replace("[turbo]", "").replace("[delayed]", "");
            var second = trigger.name.replace("[turbo]", "").replace("[delayed]", "");
            if (first == second) {
                return binding.id;
            }
        }
        
        return "";
    }

    /////////////////////////////////////////////////////////////////////
    /// Event filter method needed to fetch X.Events.
    /////////////////////////////////////////////////////////////////////
    
    private Gdk.FilterReturn event_filter(Gdk.XEvent gdk_xevent, Gdk.Event gdk_event) { 
        
        #if VALA_0_16
            X.Event* xevent = (X.Event*) gdk_xevent;
        #else
            void* pointer = &gdk_xevent;
            X.Event* xevent = (X.Event*) pointer;
        #endif
 
        if(xevent->type == X.EventType.KeyPress) {
            foreach(var binding in bindings) {
                // remove NumLock, CapsLock and ScrollLock from key state
                uint event_mods = xevent.xkey.state & ~ (lock_modifiers[7]);
                if(xevent->xkey.keycode == binding.trigger.key_code && event_mods == binding.trigger.modifiers) {
                    if (binding.trigger.delayed) {
                        this.activate_delayed(binding, *xevent);
                    } else {
                        on_press(binding.id);
                    }
                }
            }
         } 
         else if(xevent->type == X.EventType.ButtonPress) {
            foreach(var binding in bindings) {
                // remove NumLock, CapsLock and ScrollLock from key state
                uint event_mods = xevent.xbutton.state & ~ (lock_modifiers[7]);
                if(xevent->xbutton.button == binding.trigger.key_code && event_mods == binding.trigger.modifiers) {
                    if (binding.trigger.delayed) {
                        this.activate_delayed(binding, *xevent);
                    } else {
                        on_press(binding.id);
                    }
                }
            }
         }
         else if(xevent->type == X.EventType.ButtonRelease || xevent->type == X.EventType.KeyRelease) {
            this.activate_delayed(null, *xevent);
         } 
 
        return Gdk.FilterReturn.CONTINUE;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// This method is always called when a trigger is activated which is
    /// delayed. Therefore on_press() is only emitted, when this method
    /// is not called again within 300 milliseconds. Else a fake event is
    /// sent in order to simulate the actual key which has been pressed.
    /////////////////////////////////////////////////////////////////////
    
    private void activate_delayed(Keybinding? binding , X.Event event) {
    	// increase event count, so any waiting event will realize that
    	// something happened in the meantime
        var current_count = ++this.delayed_count;
        
        if (binding == null && this.delayed_event != null) {
        	// if the trigger is released and an event is currently waiting
		    // simulate that the trigger has been pressed without any inter-
		    // ference of Gnome-Pie
       		X.Display display = Gdk.x11_get_default_xdisplay();
       		
       		// unbind the trigger, else we'll capture that event again ;)
       		unbind(delayed_binding.id);
       		
       		if (this.delayed_binding.trigger.with_mouse) {
       			// simulate mouse click
       			X.Test.fake_button_event(display, this.delayed_event.xbutton.button, true, 0);
       			display.flush();
       			
            	X.Test.fake_button_event(display, this.delayed_event.xbutton.button, false, 0);
            	display.flush();
            	
       		} else {
       			// simulate key press
       			X.Test.fake_key_event(display, this.delayed_event.xkey.keycode, true, 0);
       			display.flush();
       			
       			X.Test.fake_key_event(display, this.delayed_event.xkey.keycode, false, 0);
       			display.flush();
       		}
            
            // bind it again
            bind(delayed_binding.trigger, delayed_binding.id);
        } else if (binding != null) {
        	// if the trigger has been pressed, store it and wait for any interuption
        	// within the next 300 milliseconds
            this.delayed_event = event;
            this.delayed_binding = binding;

            Timeout.add(300, () => {
            	// if nothing has been pressed in the meantime
                if (current_count == this.delayed_count) {
                	this.delayed_binding = null;
                    this.delayed_event = null;
                    on_press(binding.id);
                }
                return false;
            });
        }
    }
}

}
