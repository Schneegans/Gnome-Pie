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
    /// The background image position and size.
    /////////////////////////////////////////////////////////////////////

    private int back_x;
    private int back_y;
    private int back_sz_x;
    private int back_sz_y;

    /////////////////////////////////////////////////////////////////////
    /// Some panels moves the window after it was realized.
    /// This value set the maximum allowed panel height or width.
    /// (how many pixels the window could be moved in every direction
    ///  from the screen borders towards the center)
    /////////////////////////////////////////////////////////////////////

    private int panel_sz = 64;

    /////////////////////////////////////////////////////////////////////
    /// This value set the maximum allowed mouse movement in pixels
    /// from the capture to the show point in every direction.
    /////////////////////////////////////////////////////////////////////

    private int mouse_move = 30;

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
    /// When a Pie is opened, pressed buttons are accumulated and
    /// matches are searched in all slices.
    /////////////////////////////////////////////////////////////////////

    private string search_string = "";

    /////////////////////////////////////////////////////////////////////
    /// Used to identify wayland sessions.
    /////////////////////////////////////////////////////////////////////

    private bool wayland = GLib.Environment.get_variable("XDG_SESSION_TYPE") == "wayland";

    /////////////////////////////////////////////////////////////////////
    /// C'tor, sets up the window.
    /////////////////////////////////////////////////////////////////////

    public PieWindow() {
        this.renderer = new PieRenderer();

        this.set_title("Gnome-Pie");
        this.set_skip_taskbar_hint(true);
        this.set_skip_pager_hint(true);
        this.set_keep_above(true);
        this.set_type_hint(Gdk.WindowTypeHint.DIALOG);
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

        // activate on left click
        this.button_release_event.connect ((e) => {
            if (e.button == 1 || PieManager.get_is_turbo(this.renderer.id)) this.activate_slice(e.time);
            return true;
        });

         // cancel on right click
        this.button_press_event.connect ((e) => {
            if (e.button == 3) this.cancel();
            return true;
        });

        // remember last pressed key in order to disable key repeat
        uint last_key = 0;
        uint32 last_time_stamp = 0;
        this.key_press_event.connect((e) => {
            if (e.keyval != last_key) {
                this.handle_key_press(e.keyval, e.time, last_time_stamp, e.str);
                last_key        = e.keyval;
                last_time_stamp = e.time;
            }
            return true;
        });

        // activate on key release if turbo_mode is enabled
        this.key_release_event.connect((e) => {
            last_key = 0;
            if (PieManager.get_is_turbo(this.renderer.id))
                this.activate_slice(e.time);
            else
                this.handle_key_release(e.keyval);
            return true;
        });

        ulong connection_id = PieManager.bindings.on_release.connect((time_stamp) => {
            if (PieManager.get_is_turbo(this.renderer.id)) {
                this.activate_slice(time_stamp);
            }
        });

        this.on_closing.connect(() => {
            PieManager.bindings.disconnect(connection_id);
        });

        this.focus_out_event.connect((w, e) => {
            if (this.is_active) {
                this.cancel();
            }
            return true;
        });

        // notify the renderer of mouse move events
        this.motion_notify_event.connect((e) => {
            this.renderer.on_mouse_move();
            return true;
        });

        this.show.connect_after(() => {
            FocusGrabber.grab(this.get_window());
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

        if (wayland) {
            // wayland does not support client side window placement
            // therefore we will make a fullscreen window
            #if HAVE_GTK_3_22
                var monitor = Gdk.Display.get_default().get_monitor_at_point(this.back_x, this.back_y).get_geometry();
                int monitor_x = monitor.width;
                int monitor_y = monitor.height;
            #else
                var screen = Gdk.Screen.get_default().get_root_window();
                int monitor_x = screen.get_width();
                int monitor_y = screen.get_height();
            #endif

            this.set_size_request(monitor_x, monitor_y);
        } else {
            this.set_window_position(pie);
            this.set_size_request(renderer.size_w, renderer.size_h);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Opens the window. load_pie should have been called before.
    /////////////////////////////////////////////////////////////////////

    public void open() {
        this.realize();
        // capture the background image if there is no compositing
        if (!this.has_compositing) {
            this.get_position(out this.back_x, out this.back_y);
            this.get_size(out this.back_sz_x, out this.back_sz_y);
            this.back_sz_x++;
            this.back_sz_y++;

            #if HAVE_GTK_3_22
                var monitor = Gdk.Display.get_default().get_monitor_at_point(this.back_x, this.back_y).get_geometry();
                int monitor_x = monitor.width;
                int monitor_y = monitor.height;
            #else
                var screen = Gdk.Screen.get_default().get_root_window();
                int monitor_x = screen.get_width();
                int monitor_y = screen.get_height();
            #endif

            // allow some window movement from the screen borders
            // (some panels moves the window after it was realized)
            int dx = this.panel_sz - this.back_x;
            if (dx > 0)
                this.back_sz_x += dx;
            dx = this.panel_sz - (monitor_x - this.back_x - this.back_sz_x +1);
            if (dx > 0) {
                this.back_sz_x += dx;
                this.back_x  -= dx;
            }

            int dy = this.panel_sz - this.back_y;
            if (dy > 0)
                this.back_sz_y += dy;
            dy = this.panel_sz - (monitor_y - this.back_y - this.back_sz_y +1);
            if (dy > 0) {
                this.back_sz_y += dy;
                this.back_y  -= dy;
            }

            // also tolerate some mouse movement
            this.back_x -= this.mouse_move;
            this.back_sz_x += this.mouse_move*2;
            this.back_y -= this.mouse_move;
            this.back_sz_y += this.mouse_move*2;

            // make sure we don't go outside the screen
            if (this.back_x < 0) {
                this.back_sz_x += this.back_x;
                this.back_x = 0;
            }
            if (this.back_y < 0) {
                this.back_sz_y += this.back_y;
                this.back_y = 0;
            }
            if (this.back_x + this.back_sz_x > monitor_x)
                this.back_sz_x = monitor_x - this.back_x;
            if (this.back_y + this.back_sz_y > monitor_y)
                this.back_sz_y = monitor_y - this.back_y;
            this.background = new Image.capture_screen(this.back_x, this.back_y, this.back_sz_x, this.back_sz_y);
        }

        // capture the input focus
        this.show();

        // start the timer
        this.timer = new GLib.Timer();
        this.timer.start();
        this.queue_draw();

        bool warp_pointer = PieManager.get_is_warp(this.renderer.id);

        // the main draw loop
        GLib.Timeout.add((uint)(1000.0/Config.global.refresh_rate), () => {
            if (this.closed)
                return false;

            if (warp_pointer) {
                warp_pointer = false;
                int x, y;
                this.get_center_pos(out x, out y);
                this.set_mouse_position(x, y);
            }

            this.queue_draw();
            return this.visible;
        });
    }

    /////////////////////////////////////////////////////////////////////
    /// Gets the center position of the window.
    /////////////////////////////////////////////////////////////////////

    public void get_center_pos(out int out_x, out int out_y) {
        int x = 0, y = 0;
        this.get_position(out x, out y);
        out_x = x + renderer.center_x;
        out_y = y + renderer.center_y;
    }

    /////////////////////////////////////////////////////////////////////
    /// Gets the absolute position of the mouse pointer.
    /////////////////////////////////////////////////////////////////////

    private void get_mouse_position(out int mx, out int my) {
        #if HAVE_GTK_3_20
            var seat = Gdk.Display.get_default().get_default_seat();
            seat.get_pointer().get_position(null, out mx, out my);
        #else
            double x = 0.0;
            double y = 0.0;

            var display = Gdk.Display.get_default();
            var manager = display.get_device_manager();
            GLib.List<weak Gdk.Device?> list = manager.list_devices(Gdk.DeviceType.MASTER);

            foreach(var device in list) {
                if (device.input_source != Gdk.InputSource.KEYBOARD) {
                    Gdk.Screen screen;
                    device.get_position( out screen, out x, out y );
                }
            }
            
            mx = (int) x;
            my = (int) y;
        #endif
    }

    /////////////////////////////////////////////////////////////////////
    /// Sets the absolute position of the mouse pointer.
    /////////////////////////////////////////////////////////////////////

    private void set_mouse_position(int mx, int my) {
        #if HAVE_GTK_3_20
            var seat = Gdk.Display.get_default().get_default_seat();
            seat.get_pointer().warp(this.screen, mx, my);
        #else
            var display = Gdk.Display.get_default();
            var manager = display.get_device_manager();
            GLib.List<weak Gdk.Device?> list = manager.list_devices(Gdk.DeviceType.MASTER);
            foreach(var device in list) {
                if (device.input_source != Gdk.InputSource.KEYBOARD) {
                    device.warp(Gdk.Screen.get_default(), mx, my);
                }
            }
        #endif
    }

    /////////////////////////////////////////////////////////////////////
    /// Draw the Pie.
    /////////////////////////////////////////////////////////////////////

    private bool draw_window(Cairo.Context ctx) {
        int x, y;
        this.get_position(out x, out y);

        // paint the background image if there is no compositing
        if (this.has_compositing) {
            ctx.set_operator (Cairo.Operator.CLEAR);
            ctx.paint();
            ctx.set_operator (Cairo.Operator.OVER);
        } else {
            //correct the background position if the window was moved
            //since the background image was captured
            int dx = this.back_x - x;
            int dy = this.back_y - y;
            ctx.save();
            ctx.translate(dx, dy);
            ctx.set_operator (Cairo.Operator.OVER);
            ctx.set_source_surface(background.surface, -1, -1);
            ctx.paint();
            ctx.restore();
        }

        // get the mouse position
        int mouse_x, mouse_y;
        get_mouse_position( out mouse_x, out mouse_y );

        // store the frame time
        double frame_time = this.timer.elapsed();
        this.timer.reset();

        int center_x = this.renderer.center_x;
        int center_y = this.renderer.center_y;

        // on wayland we have a fullscreen window and since we
        // do not get the pointer location until the mouse moved
        // we can only display the pie centered...
        if (this.wayland) {
            #if HAVE_GTK_3_22
                var monitor = Gdk.Display.get_default().get_monitor_at_point(mouse_x, mouse_y).get_geometry();
                center_x = monitor.width / 2;
                center_y = monitor.height / 2;
            #else
                var screen = Gdk.Screen.get_default().get_root_window();
                center_x = screen.get_width() / 2;
                center_y = screen.get_height() / 2;
            #endif
        }

        // align the context to the center of the PieWindow
        x += center_x;
        y += center_y;
        ctx.translate(center_x, center_y);

        // render the Pie
        this.renderer.draw(frame_time, ctx, mouse_x - x, mouse_y - y);

        return true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Activates the currently activate slice.
    /////////////////////////////////////////////////////////////////////

    private void activate_slice(uint32 time_stamp) {
        if (!this.closing) {

            bool should_close = true;

            // do not close when ctrl or shift is held down
            if ((Key.get_modifiers() &
                    (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK)) > 0 &&
                !PieManager.get_is_turbo(this.renderer.id)) {
                should_close = false;
            }

            GLib.Timeout.add(10, () => {
                this.renderer.activate(time_stamp, should_close);
                return false;
            });

            if (should_close) {
                this.closing = true;
                this.on_closing();
                FocusGrabber.ungrab();

                GLib.Timeout.add((uint)(Config.global.theme.fade_out_time*1000), () => {
                    this.closed = true;
                    this.on_closed();
                    this.destroy();
                    return false;
                });
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Activates no slice and closes the PieWindow.
    /////////////////////////////////////////////////////////////////////

    private void cancel() {
        if (!this.closing) {
            this.closing = true;
            this.on_closing();
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

    private void handle_key_press(uint key, uint32 time_stamp, uint32 last_time_stamp, string text) {
        if (last_time_stamp + 1000 < time_stamp) {
            this.search_string = "";
        }

        if      (Gdk.keyval_name(key) == "Escape") this.cancel();
        else if (Gdk.keyval_name(key) == "Return") this.activate_slice(time_stamp);
        else if (Gdk.keyval_name(key) == "KP_Enter") this.activate_slice(time_stamp);
        else if (!PieManager.get_is_turbo(this.renderer.id)) {
            if (Gdk.keyval_name(key) == "Up") this.renderer.select_up();
            else if (Gdk.keyval_name(key) == "Down") this.renderer.select_down();
            else if (Gdk.keyval_name(key) == "Left") this.renderer.select_left();
            else if (Gdk.keyval_name(key) == "Right") this.renderer.select_right();
            else if (Gdk.keyval_name(key) == "Page_Down") this.renderer.select_nextpage();
            else if (Gdk.keyval_name(key) == "Page_Up") this.renderer.select_prevpage();
            else if (Gdk.keyval_name(key) == "Tab") this.renderer.select_nextpage();
            else if (Gdk.keyval_name(key) == "ISO_Left_Tab") this.renderer.select_prevpage();
            else if (Gdk.keyval_name(key) == "Alt_L" && !Config.global.search_by_string) this.renderer.show_hotkeys = true;
            else {

                if (Config.global.search_by_string) {
                    this.search_string += text;
                    this.renderer.select_by_string(search_string.down());

                } else {

                    int index = -1;

                    if (key >= 48 && key <= 57)        index = ((int)key - 39)%10;
                    else if (key >= 97 && key <= 122)  index = (int)key - 87;
                    else if (key >= 65 && key <= 90)   index = (int)key - 55;

                    if (index >= 0 && index < this.renderer.slice_count()) {
                        this.renderer.key_board_control = true;
                        this.renderer.select_by_index(index);

                        if (this.renderer.active_slice == index) {
                            GLib.Timeout.add((uint)(Config.global.theme.transition_time*1000.0), ()=> {
                                this.activate_slice(time_stamp);
                                return false;
                            });
                        }
                    }
                }
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Do some useful stuff when keys are released.
    /////////////////////////////////////////////////////////////////////

    private void handle_key_release(uint key) {
        if (!PieManager.get_is_turbo(this.renderer.id)) {
            if (Gdk.keyval_name(key) == "Alt_L") this.renderer.show_hotkeys = false;
        }
    }
}

}
