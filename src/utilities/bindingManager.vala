/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2018 Simon Schneegans
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
    /// Called when a previously pressed binding is released again.
    /////////////////////////////////////////////////////////////////////

    public signal void on_release(uint32 time_stamp);

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
    /// Used to identify wayland sessions.
    /////////////////////////////////////////////////////////////////////

    private bool wayland = GLib.Environment.get_variable("XDG_SESSION_TYPE") == "wayland";

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
        
        // global key grabbing is impossible on wayland
        if (!wayland && trigger.key_code != 0) {
            unowned X.Display display = Gdk.X11.get_default_xdisplay();
            X.ID xid = Gdk.X11.get_default_root_xwindow();

            Gdk.error_trap_push();

            // if bound to super key we need to grab MOD4 instead
            // (for whatever reason...)
            var modifiers = prepare_modifiers(trigger.modifiers);

            foreach(uint lock_modifier in lock_modifiers) {
                if (trigger.with_mouse) {
                    display.grab_button(trigger.key_code, modifiers|lock_modifier, xid, false,
                                        X.EventMask.ButtonPressMask | X.EventMask.ButtonReleaseMask,
                                        X.GrabMode.Async, X.GrabMode.Async, xid, 0);
                } else {
                    display.grab_key(trigger.key_code, modifiers|lock_modifier,
                                     xid, false, X.GrabMode.Async, X.GrabMode.Async);
                }
            }

            Gdk.flush();
            Keybinding binding = new Keybinding(trigger, id);
            bindings.add(binding);
            display.flush();
        } else {
            //no key_code: just add the bindind to the list to save optional trigger parameters
            Keybinding binding = new Keybinding(trigger, id);
            bindings.add(binding);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Unbinds the accelerator of the given ID.
    /////////////////////////////////////////////////////////////////////

    public void unbind(string id) {
        foreach (var binding in bindings) {
            if (id == binding.id) {
                if (binding.trigger.key_code == 0 || wayland) {
                    //no key_code or wayland: just remove the bindind from the list
                    bindings.remove(binding);
                    return;
                }
                break;
            }
        }

        unowned X.Display display = Gdk.X11.get_default_xdisplay();
        X.ID xid = Gdk.X11.get_default_root_xwindow();

        Gee.List<Keybinding> remove_bindings = new Gee.ArrayList<Keybinding>();
        foreach(var binding in bindings) {
            if(id == binding.id) {

                // if bound to super key we need to ungrab MOD4 instead
                // (for whatever reason...)
                var modifiers = prepare_modifiers(binding.trigger.modifiers);

                foreach(uint lock_modifier in lock_modifiers) {
                    if (binding.trigger.with_mouse) {
                        display.ungrab_button(binding.trigger.key_code, modifiers|lock_modifier, xid);
                    } else {
                        display.ungrab_key(binding.trigger.key_code, modifiers|lock_modifier, xid);
                    }
                }
                remove_bindings.add(binding);
            }
        }

        bindings.remove_all(remove_bindings);

        if (!wayland) {
            display.flush();
        }
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
    /// Returns whether the pie with the given ID is in warp mode.
    /////////////////////////////////////////////////////////////////////

    public bool get_is_warp(string id) {
        foreach (var binding in bindings) {
            if (binding.id == id) {
                return binding.trigger.warp;
            }
        }

        return false;
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns whether the pie with the given ID is auto shaped
    /////////////////////////////////////////////////////////////////////

    public bool get_is_auto_shape(string id) {
        foreach (var binding in bindings) {
            if (binding.id == id) {
                return (binding.trigger.shape == 0);
            }
        }

        return false;
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the prefered pie shape number
    /////////////////////////////////////////////////////////////////////

    public int get_shape_number(string id) {
        foreach (var binding in bindings) {
            if (binding.id == id) {
                if (binding.trigger.shape == 0)
                    break;  //return default if auto-shaped
                return binding.trigger.shape; //use selected shape
            }
        }

        return 5;   //default= full pie
    }


    /////////////////////////////////////////////////////////////////////
    /// Returns the name ID of the Pie bound to the given Trigger.
    /// Returns "" if there is nothing bound to this trigger.
    /////////////////////////////////////////////////////////////////////

    public string get_assigned_id(Trigger trigger) {
        var second = Trigger.remove_optional(trigger.name);
        if (second != "") {
            foreach (var binding in bindings) {
                var first = Trigger.remove_optional(binding.trigger.name);
                if (first == second) {
                    return binding.id;
                }
            }
        }
        return "";
    }

    /////////////////////////////////////////////////////////////////////
    /// If SUPER_MASK is set in the input, it will be replaced with
    /// MOD4_MASK. For some reason this is required to listen for key
    /// presses of the super button....
    /////////////////////////////////////////////////////////////////////

    private Gdk.ModifierType prepare_modifiers(Gdk.ModifierType mods) {
        if ((mods & Gdk.ModifierType.SUPER_MASK) > 0) {
            mods |= Gdk.ModifierType.MOD4_MASK;
            mods = mods & ~ Gdk.ModifierType.SUPER_MASK;
        }

        mods &= ~(Gdk.ModifierType.BUTTON1_MASK
                | Gdk.ModifierType.BUTTON2_MASK
                | Gdk.ModifierType.BUTTON3_MASK
                | Gdk.ModifierType.BUTTON4_MASK
                | Gdk.ModifierType.BUTTON5_MASK);

        return mods & ~lock_modifiers[7];
    }

    /////////////////////////////////////////////////////////////////////
    /// Event filter method needed to fetch X.Events.
    /////////////////////////////////////////////////////////////////////

    private Gdk.FilterReturn event_filter(Gdk.XEvent gdk_xevent, Gdk.Event gdk_event) {

        #if VALA_0_16 || VALA_0_17
            X.Event* xevent = (X.Event*) gdk_xevent;
        #else
            void* pointer = &gdk_xevent;
            X.Event* xevent = (X.Event*) pointer;
        #endif


        if (xevent->type == X.EventType.KeyPress) {
            // remove NumLock, CapsLock and ScrollLock from key state
            var event_mods = prepare_modifiers((Gdk.ModifierType)xevent.xkey.state);

            foreach(var binding in bindings) {
                var bound_mods = prepare_modifiers(binding.trigger.modifiers);
                if(xevent->xkey.keycode == binding.trigger.key_code &&
                   event_mods == bound_mods) {

                    if (binding.trigger.delayed) {
                        this.activate_delayed(binding, *xevent);
                    } else {
                        on_press(binding.id);
                    }
                }
            }
        } else if(xevent->type == X.EventType.ButtonPress) {
            // remove NumLock, CapsLock and ScrollLock from key state
            var event_mods = prepare_modifiers((Gdk.ModifierType)xevent.xbutton.state);

            foreach(var binding in bindings) {
                var bound_mods = prepare_modifiers(binding.trigger.modifiers);
                if(xevent->xbutton.button == binding.trigger.key_code &&
                   event_mods == bound_mods) {

                    if (binding.trigger.delayed) {
                        this.activate_delayed(binding, *xevent);
                    } else {
                        on_press(binding.id);
                    }
                }
            }
        }
        else if(xevent->type == X.EventType.ButtonRelease || xevent->type == X.EventType.KeyRelease) {
            on_release((uint32)xevent.xkey.time);
            this.cancel_activate_delayed();
        }

        return Gdk.FilterReturn.CONTINUE;
    }

    /////////////////////////////////////////////////////////////////////
    /// This method is always called when a trigger is activated which is
    /// delayed. Therefore on_press() is only emitted, when
    /// cancel_activate_delayed is not called again 300 milliseconds.
    /// Else a fake event is sent in order to simulate the actual key
    /// which has been pressed.
    /////////////////////////////////////////////////////////////////////

    private void activate_delayed(Keybinding binding, X.Event event) {

        if (this.delayed_binding == null) {
            // the current event count is captured in the lambda below. If
            // cancel_activate_delayed is not called within 300 milliseconds,
            // the binding can be activated
            var current_count = this.delayed_count;

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

    private void cancel_activate_delayed() {

        if (this.delayed_event != null) {
            // increase event count, so any waiting event will realize that
            // something happened in the meantime
            ++this.delayed_count;

            // if the trigger is released and an event is currently waiting
            // simulate that the trigger has been pressed without any inter-
            // ference of Gnome-Pie
            unowned X.Display display = Gdk.X11.get_default_xdisplay();

            // unbind the trigger, else we'll capture that event again ;-)
            unbind(delayed_binding.id);

            if (this.delayed_binding.trigger.with_mouse) {
                // simulate mouse click
                XTest.fake_button_event(display, this.delayed_event.xbutton.button, true, 0);
                display.flush();

                XTest.fake_button_event(display, this.delayed_event.xbutton.button, false, 0);
                display.flush();

            } else {
                // simulate key press
                XTest.fake_key_event(display, this.delayed_event.xkey.keycode, true, 0);
                display.flush();

                XTest.fake_key_event(display, this.delayed_event.xkey.keycode, false, 0);
                display.flush();
            }

            // bind it again
            bind(delayed_binding.trigger, delayed_binding.id);

            this.delayed_binding = null;
            this.delayed_event = null;
        }
    }
}

}
