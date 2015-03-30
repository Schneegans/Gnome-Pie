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

using GLib.Math;

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
///  An invisible window. Used to draw Pies onto.
/////////////////////////////////////////////////////////////////////////

public class PieWindow : Gtk.Window {

    /////////////////////////////////////////////////////////////////////
    /// Signal which gets emitted when the PieWindow is about to close.
    /////////////////////////////////////////////////////////////////////

    public signal void on_closing();

    /////////////////////////////////////////////////////////////////////
    /// Signal which gets emitted when the PieWindow is closed.
    /////////////////////////////////////////////////////////////////////

    public signal void on_closed();

    /////////////////////////////////////////////////////////////////////
    /// The background image used for fake transparency if
    /// has_compositing is false.
    /////////////////////////////////////////////////////////////////////

    public Image background { get; private set; default=null; }

    /////////////////////////////////////////////////////////////////////
    /// The owned renderer.
    /////////////////////////////////////////////////////////////////////

    private PieRenderer renderer;

    /////////////////////////////////////////////////////////////////////
    /// True, if the Pie is currently fading out.
    /////////////////////////////////////////////////////////////////////

    private bool closing = false;
    private bool closed = false;

    /////////////////////////////////////////////////////////////////////
    /// A timer used for calculating the frame time.
    /////////////////////////////////////////////////////////////////////

    private GLib.Timer timer;

    /////////////////////////////////////////////////////////////////////
    /// True, if the screen supports compositing.
    /////////////////////////////////////////////////////////////////////

    private bool has_compositing = false;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, sets up the window.
    /////////////////////////////////////////////////////////////////////

    public PieWindow() {
        this.renderer = new PieRenderer();

        this.set_title("Gnome-Pie");
        this.set_skip_taskbar_hint(true);
        this.set_skip_pager_hint(true);
        this.set_keep_above(true);
        this.set_type_hint(Gdk.WindowTypeHint.POPUP_MENU);
        this.set_decorated(false);
        this.set_resizable(false);
        this.icon_name = "gnome-pie";
        this.set_accept_focus(false);
        this.app_paintable = true;

        // check for compositing
        if (this.screen.is_composited()) {
            this.set_visual(this.screen.get_rgba_visual());
            this.has_compositing = true;
        }

        // set up event filter
        this.add_events(Gdk.EventMask.BUTTON_RELEASE_MASK |
                        Gdk.EventMask.KEY_RELEASE_MASK |
                        Gdk.EventMask.KEY_PRESS_MASK |
                        Gdk.EventMask.POINTER_MOTION_MASK |
                        Gdk.EventMask.SCROLL_MASK );

        // activate on left click
        this.button_release_event.connect ((e) => {
            if (e.button == 1 || this.renderer.turbo_mode) this.activate_slice();
            return true;
        });

         // cancel on right click
        this.button_press_event.connect ((e) => {
            if (e.button == 3) this.cancel();
            return true;
        });

        // remember last pressed key in order to disable key repeat
        uint last_key = 0;
        this.key_press_event.connect((e) => {
            if (e.keyval != last_key) {
                last_key = e.keyval;
                this.handle_key_press(e.keyval);
            }
            return true;
        });

        // activate on key release if turbo_mode is enabled
        this.key_release_event.connect((e) => {
            last_key = 0;
            if (this.renderer.turbo_mode)
                this.activate_slice();
            else
                this.handle_key_release(e.keyval);
            return true;
        });

        // notify the renderer of mouse move events
        this.motion_notify_event.connect((e) => {
            this.renderer.on_mouse_move();
            return true;
        });

        this.show.connect_after(() => {
            Gtk.grab_add(this);
            FocusGrabber.grab(this.get_window(), true, true, false);
        });
        
        this.scroll_event.connect((e) => {
            if (e.direction == Gdk.ScrollDirection.UP)
                this.renderer.select_prevpage();
                
            else if (e.direction == Gdk.ScrollDirection.DOWN)
                this.renderer.select_nextpage();
            return true;
        });

        // draw the pie on expose
        this.draw.connect(this.draw_window);
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads a Pie to be rendered.
    /////////////////////////////////////////////////////////////////////

    public void load_pie(Pie pie) {
        this.renderer.load_pie(pie);
        this.set_window_position(pie);
        this.set_size_request(renderer.size_w, renderer.size_h);
    }

    /////////////////////////////////////////////////////////////////////
    /// Opens the window. load_pie should have been called before.
    /////////////////////////////////////////////////////////////////////

    public void open() {
        this.realize();
        // capture the background image if there is no compositing
        if (!this.has_compositing) {
            int x, y, width, height;
            this.get_position(out x, out y);
            this.get_size(out width, out height);
            this.background = new Image.capture_screen(x, y, width+1, height+1);
        }

        // capture the input focus
        this.show();

        // start the timer
        this.timer = new GLib.Timer();
        this.timer.start();
        this.queue_draw();

        // the main draw loop
        GLib.Timeout.add((uint)(1000.0/Config.global.refresh_rate), () => {
            if (this.closed)
                return false;

            this.queue_draw();
            return this.visible;
        });
    }

    /////////////////////////////////////////////////////////////////////
    /// Gets the center position of the window.
    /////////////////////////////////////////////////////////////////////

    public void get_center_pos(out int out_x, out int out_y) {
        int x=0, y=0; //width=0, height=0;
        this.get_position(out x, out y);
        out_x = x + renderer.center_x;
        out_y = y + renderer.center_y;
    }
    
    private void get_mouse_position(out double mx, out double my) {
        // get the mouse position
        mx = 0.0;
        my = 0.0;
        Gdk.ModifierType mask;

        var display = Gdk.Display.get_default();
        var manager = display.get_device_manager();
        GLib.List<weak Gdk.Device?> list = manager.list_devices(Gdk.DeviceType.MASTER);

        foreach(var device in list) {
            if (device.input_source != Gdk.InputSource.KEYBOARD) {
                this.get_window().get_device_position_double(device, out mx, out my, out mask);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Draw the Pie.
    /////////////////////////////////////////////////////////////////////

    private bool draw_window(Cairo.Context ctx) {
        // paint the background image if there is no compositing
        if (this.has_compositing) {
            ctx.set_operator (Cairo.Operator.CLEAR);
            ctx.paint();
            ctx.set_operator (Cairo.Operator.OVER);
        } else {
		    
            ctx.set_operator (Cairo.Operator.OVER);
            ctx.set_source_surface(background.surface, -1, -1);
            ctx.paint();
        }

        // align the context to the center of the PieWindow
        ctx.translate(this.renderer.center_x, this.renderer.center_y);

        // get the mouse position
        double mouse_x, mouse_y;
        get_mouse_position( out mouse_x, out mouse_y );

        // store the frame time
        double frame_time = this.timer.elapsed();
        this.timer.reset();

        // render the Pie
        this.renderer.draw(frame_time, ctx, (int)(mouse_x - this.renderer.center_x),
                                            (int)(mouse_y - this.renderer.center_y));

        return true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Activates the currently activate slice.
    /////////////////////////////////////////////////////////////////////

    private void activate_slice() {
        if (!this.closing) {
            this.closing = true;
            this.on_closing();
            Gtk.grab_remove(this);
            FocusGrabber.ungrab();

            GLib.Timeout.add(10, () => {
                this.renderer.activate();
                return false;
            });

            GLib.Timeout.add((uint)(Config.global.theme.fade_out_time*1000), () => {
                this.closed = true;
                this.on_closed();
                this.destroy();
                return false;
            });
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Activates no slice and closes the PieWindow.
    /////////////////////////////////////////////////////////////////////

    private void cancel() {
        if (!this.closing) {
            this.closing = true;
            this.on_closing();
            Gtk.grab_remove(this);
            FocusGrabber.ungrab();
            this.renderer.cancel();

            GLib.Timeout.add((uint)(Config.global.theme.fade_out_time*1000), () => {
                this.closed = true;
                this.on_closed();
                this.destroy();
                return false;
            });
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Sets the position of the window to the center of the screen or to
    /// the mouse.
    /////////////////////////////////////////////////////////////////////

    private void set_window_position(Pie pie) {
        if(PieManager.get_is_centered(pie.id)) this.set_position(Gtk.WindowPosition.CENTER);
        else                                   this.set_position(Gtk.WindowPosition.MOUSE);
    }

    /////////////////////////////////////////////////////////////////////
    /// Do some useful stuff when keys are pressed.
    /////////////////////////////////////////////////////////////////////

    private void handle_key_press(uint key) {
        if      (Gdk.keyval_name(key) == "Escape") this.cancel();
        else if (Gdk.keyval_name(key) == "Return") this.activate_slice();
        else if (!this.renderer.turbo_mode) {
            if (Gdk.keyval_name(key) == "Up") this.renderer.select_up();
            else if (Gdk.keyval_name(key) == "Down") this.renderer.select_down();
            else if (Gdk.keyval_name(key) == "Left") this.renderer.select_left();
            else if (Gdk.keyval_name(key) == "Right") this.renderer.select_right();
            else if (Gdk.keyval_name(key) == "Page_Down") this.renderer.select_nextpage();
            else if (Gdk.keyval_name(key) == "Page_Up") this.renderer.select_prevpage();
            else if (Gdk.keyval_name(key) == "Tab") this.renderer.select_nextpage();
            else if (Gdk.keyval_name(key) == "ISO_Left_Tab") this.renderer.select_prevpage();
            else if (Gdk.keyval_name(key) == "Alt_L") this.renderer.show_hotkeys = true;
            else {
                int index = -1;

                if (key >= 48 && key <= 57)        index = ((int)key - 39)%10;
                else if (key >= 97 && key <= 122)  index = (int)key - 87;
                else if (key >= 65 && key <= 90)   index = (int)key - 55;

                if (index >= 0 && index < this.renderer.slice_count()) {
                    this.renderer.key_board_control = true;
                    this.renderer.set_highlighted_slice(index);

                    if (this.renderer.active_slice == index) {
                        GLib.Timeout.add((uint)(Config.global.theme.transition_time*1000.0), ()=> {
                            this.activate_slice();
                            return false;
                        });
                    }
                }
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Do some useful stuff when keys are released.
    /////////////////////////////////////////////////////////////////////

    private void handle_key_release(uint key) {
        if (!this.renderer.turbo_mode) {
            if (Gdk.keyval_name(key) == "Alt_L") this.renderer.show_hotkeys = false;
        }
    }
}

}
