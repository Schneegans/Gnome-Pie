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
        
        // check for compositing
        if (this.screen.is_composited()) {
            #if HAVE_GTK_3
                this.set_visual(this.screen.get_rgba_visual());
            #else
                this.set_colormap(this.screen.get_rgba_colormap());
            #endif
            this.has_compositing = true;
        }
        
        // set up event filter
        this.add_events(Gdk.EventMask.BUTTON_RELEASE_MASK |
                        Gdk.EventMask.KEY_RELEASE_MASK |
                        Gdk.EventMask.KEY_PRESS_MASK |
                        Gdk.EventMask.POINTER_MOTION_MASK);

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

        // draw the pie on expose
        #if HAVE_GTK_3
            this.draw.connect(this.draw_window);
        #else
            this.expose_event.connect(this.draw_window);
        #endif
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads a Pie to be rendered.
    /////////////////////////////////////////////////////////////////////

    public void load_pie(Pie pie) {
        this.renderer.load_pie(pie);
        this.set_window_position(pie);
        this.set_size_request(renderer.size, renderer.size);
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
        Timeout.add((uint)(1000.0/Config.global.refresh_rate), () => {
            this.queue_draw();
            return this.visible;
        }); 
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Opens the window at a given location.
    /////////////////////////////////////////////////////////////////////
    
    public void open_at(int at_x, int at_y) {
        this.open();
        this.move(at_x-this.width_request/2, at_y-this.height_request/2);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Gets the center position of the window.
    /////////////////////////////////////////////////////////////////////
    
    public void get_center_pos(out int out_x, out int out_y) {
        int x=0, y=0, width=0, height=0;
        this.get_position(out x, out y);
        this.get_size(out width, out height);
        
        out_x = x + width/2;
        out_y = y + height/2;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Draw the Pie.
    /////////////////////////////////////////////////////////////////////

    #if HAVE_GTK_3
        private bool draw_window(Cairo.Context ctx) { 
    #else
        private bool draw_window(Gtk.Widget da, Gdk.EventExpose event) {    
            // clear the window
            var ctx = Gdk.cairo_create(this.get_window());
    #endif
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
        ctx.translate(this.width_request*0.5, this.height_request*0.5);
        
        // get the mouse position
        double mouse_x = 0.0, mouse_y = 0.0;
        this.get_pointer(out mouse_x, out mouse_y);
        
        // store the frame time
        double frame_time = this.timer.elapsed();
        this.timer.reset();
        
        // render the Pie
        this.renderer.draw(frame_time, ctx, (int)(mouse_x - this.width_request*0.5),
                                            (int)(mouse_y - this.height_request*0.5));
        
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
            this.renderer.activate();
            
            Timeout.add((uint)(Config.global.theme.fade_out_time*1000), () => {
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
            
            Timeout.add((uint)(Config.global.theme.fade_out_time*1000), () => {
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
            else if (Gdk.keyval_name(key) == "Alt_L") this.renderer.show_hotkeys = true;
            else {
                int index = -1;
                
                if (key >= 48 && key <= 57)        index = (int)key - 48;
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
