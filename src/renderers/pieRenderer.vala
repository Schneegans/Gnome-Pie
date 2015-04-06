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
/// This class renders a Pie. In order to accomplish that, it owns a
/// CenterRenderer and some SliceRenderers.
/////////////////////////////////////////////////////////////////////////

public class PieRenderer : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// The index of the slice used for quick action. (The action which
    /// gets executed when the user clicks on the middle of the pie)
    /////////////////////////////////////////////////////////////////////

    public int quickaction { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// The index of the currently active slice.
    /////////////////////////////////////////////////////////////////////

    public int active_slice { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// True, if the hot keys are currently displayed.
    /////////////////////////////////////////////////////////////////////

    public bool show_hotkeys { get; set; }

    /////////////////////////////////////////////////////////////////////
    /// The width and height of the Pie in pixels.
    /////////////////////////////////////////////////////////////////////

    public int size_w { get; private set; }
    public int size_h { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Center position relative to window top-left corner
    /////////////////////////////////////////////////////////////////////

    public int center_x { get; private set; }
    public int center_y { get; private set; }


    ////////////////////////////////////////////////////////////////////
    /// Possible show pie modes.
    /// FULL_PIE:       Show the pie as a complete circle.
    /// HPIE_LEFT:      Eat half pie so it can be shown at the left of the screen.
    /// HPIE_RIGHT:     Eat half pie so it can be shown at the right of the screen.
    /// HPIE_TOP:       Eat half pie so it can be shown at the top of the screen.
    /// HPIE_BOTTOM:    Eat half pie so it can be shown at the bottom of the screen.
    /// CPIE_TOP_LEFT:  Eat  3/4 pie so it can be shown at the top-left corner.
    /// CPIE_TOP_RIGHT: Eat  3/4 pie so it can be shown at the top-right corner.
    /// CPIE_BOT_LEFT:  Eat  3/4 pie so it can be shown at the bottom-left corner.
    /// CPIE_BOT_RIGHT: Eat  3/4 pie so it can be shown at the bottom-right corner.
    /// (use the same numbers as the radio-button shape selector)
    /////////////////////////////////////////////////////////////////////

    public enum ShowPieMode {
        FULL_PIE,
        HPIE_LEFT, HPIE_RIGHT, HPIE_TOP, HPIE_BOTTOM,
        CPIE_TOP_LEFT, CPIE_TOP_RIGHT, CPIE_BOT_LEFT, CPIE_BOT_RIGHT}

    /////////////////////////////////////////////////////////////////////
    ///  Show pie mode: full, half-circle, corner
    /////////////////////////////////////////////////////////////////////

    public ShowPieMode pie_show_mode { get; private set; default= ShowPieMode.FULL_PIE; }

    /////////////////////////////////////////////////////////////////////
    /// Number of visible slices
    /////////////////////////////////////////////////////////////////////

    public int visible_slice_count { get; private set; }

    public int original_visible_slice_count { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Number of slices in full pie (visible or not)
    /////////////////////////////////////////////////////////////////////

    public int total_slice_count { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Maximun number of visible slices in a full pie
    /////////////////////////////////////////////////////////////////////

    public int max_visible_slices { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// The index of the first visible slice
    /////////////////////////////////////////////////////////////////////

    public int first_slice_idx { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Angular position of the first visible slice
    /////////////////////////////////////////////////////////////////////

    public double first_slice_angle { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Index of the slice where to go when up/down/left/right key is pressed
    /// or -1 if that side of the pie was eaten
    /////////////////////////////////////////////////////////////////////

    public int up_slice_idx { get; private set; }
    public int down_slice_idx { get; private set; }
    public int left_slice_idx { get; private set; }
    public int right_slice_idx { get; private set; }


    /////////////////////////////////////////////////////////////////////
    /// True if the pie should close when it's trigger is released.
    /////////////////////////////////////////////////////////////////////

    public bool turbo_mode { get; private set; default=false; }

    /////////////////////////////////////////////////////////////////////
    /// True if the pie is currently navigated with the keyboard. This is
    /// set to false as soon as the mouse moves.
    /////////////////////////////////////////////////////////////////////

    public bool key_board_control { get; set; default=false; }

    /////////////////////////////////////////////////////////////////////
    /// All SliceRenderers used to draw this Pie.
    /////////////////////////////////////////////////////////////////////

    private Gee.ArrayList<SliceRenderer?> slices;

    /////////////////////////////////////////////////////////////////////
    /// The renderer for the center of this pie.
    /////////////////////////////////////////////////////////////////////

    private CenterRenderer center;

    /////////////////////////////////////////////////////////////////////
    /// Maximum distance from the center that activates the slices
    /////////////////////////////////////////////////////////////////////
    private int activation_range;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes members.
    /////////////////////////////////////////////////////////////////////

    public PieRenderer() {
        this.slices = new Gee.ArrayList<SliceRenderer?>();
        this.center = new CenterRenderer(this);
        this.quickaction = -1;
        this.active_slice = -2;
        this.size_w = 0;
        this.size_h = 0;
        this.activation_range= 300;

        this.max_visible_slices= Config.global.max_visible_slices;

        set_show_mode(ShowPieMode.FULL_PIE);
    }


    private void get_mouse_and_screen(out int mousex, out int mousey, out int screenx, out int screeny) {
        // get the mouse position and screen resolution
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
        mousex= (int) x;
        mousey= (int) y;
        screenx= Gdk.Screen.width();
        screeny= Gdk.Screen.height();
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads a Pie. All members are initialized accordingly.
    /////////////////////////////////////////////////////////////////////

    public void load_pie(Pie pie) {
        this.slices.clear();

        int count = 0;
        foreach (var group in pie.action_groups) {
            foreach (var action in group.actions) {
                var renderer = new SliceRenderer(this);
                this.slices.add(renderer);
                renderer.load(action, slices.size-1);

                if (action.is_quickaction) {
                    this.quickaction = count;
                }

                ++count;
            }
        }

        this.turbo_mode = PieManager.get_is_turbo(pie.id);

        this.set_highlighted_slice(this.quickaction);


        ShowPieMode showpie= ShowPieMode.FULL_PIE;
        //set full pie to determine the number of visible slices
        set_show_mode(showpie);

        int sz0= (int)fmax(2*Config.global.theme.radius + 2*Config.global.theme.slice_radius*Config.global.theme.max_zoom,
                              2*Config.global.theme.center_radius);

        int sz= sz0;
        // increase size if there are many slices
        if (this.total_slice_count > 0) {
            sz = (int)fmax(sz0,
                (((Config.global.theme.slice_radius + Config.global.theme.slice_gap)/tan(PI/this.total_slice_count))
                + Config.global.theme.slice_radius)*2*Config.global.theme.max_zoom);
        }


        if (PieManager.get_is_auto_shape(pie.id) && !PieManager.get_is_centered(pie.id)) {
            // get mouse position and screen resolution
            int mouse_x, mouse_y, screen_x, screen_y;
            get_mouse_and_screen( out mouse_x, out mouse_y, out screen_x, out screen_y );
            //set the best show mode that put the mouse near the center
            if (mouse_x < sz/2) {
                if (mouse_y < sz/2)
                    showpie= ShowPieMode.CPIE_TOP_LEFT;         //show 1/4 pie
                else if (screen_y > 0 && screen_y-mouse_y < sz/2)
                    showpie= ShowPieMode.CPIE_BOT_LEFT;         //show 1/4 pie
                else
                    showpie= ShowPieMode.HPIE_LEFT;             //show 1/2 pie

            } else if (mouse_y < sz/2) {
                if (screen_x > 0 && screen_x-mouse_x < sz/2)
                    showpie= ShowPieMode.CPIE_TOP_RIGHT;        //show 1/4 pie
                else
                    showpie= ShowPieMode.HPIE_TOP;              //show 1/2 pie

            } else if (screen_x > 0 && screen_x-mouse_x < sz/2) {
                if (screen_y > 0 && screen_y-mouse_y < sz/2)
                    showpie= ShowPieMode.CPIE_BOT_RIGHT;        //show 1/4 pie
                else
                    showpie= ShowPieMode.HPIE_RIGHT;            //show 1/2 pie

            } else if (screen_y > 0 && screen_y-mouse_y < sz/2)
                showpie= ShowPieMode.HPIE_BOTTOM;               //show 1/2 pie


        } else {
            //select the configured shape
            //convert from radio-buttum number to ShowPieMode enum
            switch( PieManager.get_shape_number(pie.id) ) {
            case 1:  showpie= ShowPieMode.CPIE_BOT_RIGHT;   break;
            case 2:  showpie= ShowPieMode.HPIE_RIGHT;       break;
            case 3:  showpie= ShowPieMode.CPIE_TOP_RIGHT;   break;
            case 4:  showpie= ShowPieMode.HPIE_BOTTOM;      break;
            case 6:  showpie= ShowPieMode.HPIE_TOP;         break;
            case 7:  showpie= ShowPieMode.CPIE_BOT_LEFT;    break;
            case 8:  showpie= ShowPieMode.HPIE_LEFT;        break;
            case 9:  showpie= ShowPieMode.CPIE_TOP_LEFT;    break;
            }
        }
        //set the new show pie mode
        set_show_mode(showpie);

        //recalc size
        sz = sz0;
        if (this.total_slice_count > 0) {
            sz = (int)fmax(sz0,
                (((Config.global.theme.slice_radius + Config.global.theme.slice_gap)/tan(PI/this.total_slice_count))
                + Config.global.theme.slice_radius)*2*Config.global.theme.max_zoom);
        }
        //activation_range = normal pie radius + "outer" activation_range
        this.activation_range= (int)((double)Config.global.activation_range + sz/(2*Config.global.theme.max_zoom));

        int szx = 1; //full width
        int szy = 1; //full height
        switch(this.pie_show_mode) {
            //half pie
            case ShowPieMode.HPIE_LEFT:
                szx = 0; //half width, center to the left
                break;
            case ShowPieMode.HPIE_RIGHT:
                szx = 2; //half width, center to the right
                break;
            case ShowPieMode.HPIE_TOP:
                szy = 0; //half height, center to the top
                break;
            case ShowPieMode.HPIE_BOTTOM:
                szy = 2; //half height, center to the bottom
                break;

            //cuarter pie
            case ShowPieMode.CPIE_TOP_LEFT:
                szx = 0; //half width, center to the left
                szy = 0; //half height, center to the top
                break;
            case ShowPieMode.CPIE_TOP_RIGHT:
                szx = 2; //half width, center to the right
                szy = 0; //half height, center to the top
                break;
            case ShowPieMode.CPIE_BOT_LEFT:
                szx = 0; //half width, center to the left
                szy = 2; //half height, center to the bottom
                break;
            case ShowPieMode.CPIE_BOT_RIGHT:
                szx = 2; //half width, center to the right
                szy = 2; //half height, center to the bottom
                break;
        }
        int rc = (int)Config.global.theme.center_radius;
        if (szx == 1 ) {
            //full width
            this.size_w = sz;
            this.center_x = sz/2;    //center position
        } else {
            //half width
            this.size_w = sz/2 + rc;
            if (szx == 0) {
                this.center_x = rc;    //center to the left
            } else {
                this.center_x = this.size_w-rc;    //center to the right
            }
        }
        if (szy == 1) {
            //full heigth
            this.size_h = sz;
            this.center_y = sz/2;    //center position
        } else {
            //half heigth
            this.size_h = sz/2 + rc;
            if (szy == 0) {
                this.center_y = rc;    //center to the top
            } else {
                this.center_y = this.size_h-rc;    //center to the bottom
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Activates the currently active slice.
    /////////////////////////////////////////////////////////////////////

    public void activate() {
        if (this.active_slice >= this.first_slice_idx
            && this.active_slice < this.first_slice_idx+this.visible_slice_count) {
            slices[active_slice].activate();
        }

        //foreach (var slice in this.slices)
        //    slice.fade_out();
        for (int i= 0; i < this.visible_slice_count; ++i) {
            this.slices[ i+this.first_slice_idx ].fade_out();
        }

        center.fade_out();
    }

    /////////////////////////////////////////////////////////////////////
    /// Asks all renders to fade out.
    /////////////////////////////////////////////////////////////////////

    public void cancel() {
        //foreach (var slice in this.slices)
        //    slice.fade_out();
        for (int i= 0; i < this.visible_slice_count; ++i) {
            this.slices[ i+this.first_slice_idx ].fade_out();
        }

        center.fade_out();
    }


    /////////////////////////////////////////////////////////////////////
    /// Called when the up-key is pressed. Selects the next slice towards
    /// the top.
    /////////////////////////////////////////////////////////////////////

    public void select_up() {
        move_active_slice(this.up_slice_idx, this.down_slice_idx);
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the down-key is pressed. Selects the next slice
    /// towards the bottom.
    /////////////////////////////////////////////////////////////////////

    public void select_down() {
        move_active_slice(this.down_slice_idx, this.up_slice_idx);
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the left-key is pressed. Selects the next slice
    /// towards the left.
    /////////////////////////////////////////////////////////////////////

    public void select_left() {
        move_active_slice(this.left_slice_idx, this.right_slice_idx);
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the right-key is pressed. Selects the next slice
    /// towards the right.
    /////////////////////////////////////////////////////////////////////

    public void select_right() {
        move_active_slice(this.right_slice_idx, this.left_slice_idx);
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the page_up-key is pressed. Selects the next
    /// group of slices.
    /////////////////////////////////////////////////////////////////////

    public void select_nextpage() {
        if (this.first_slice_idx+this.visible_slice_count < slices.size) {
            //advance one page
            this.first_slice_idx += this.visible_slice_count;
            if (this.first_slice_idx+this.visible_slice_count >= slices.size) {
                this.visible_slice_count= slices.size - this.first_slice_idx;
            }
            this.reset_sclice_anim();
            this.set_highlighted_slice(-1);
            calc_key_navigation_pos();
            this.key_board_control = true;

        } else if (this.first_slice_idx > 0) {
            //go to first page
            this.first_slice_idx= 0;
            this.reset_sclice_anim();
            //recover the original value
            this.visible_slice_count= this.original_visible_slice_count;
            this.reset_sclice_anim();
            this.set_highlighted_slice(-1);
            calc_key_navigation_pos();
            this.key_board_control = true;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the page_down-key is pressed. Selects the previous
    /// group of slices.
    /////////////////////////////////////////////////////////////////////

    public void select_prevpage() {
        if (this.first_slice_idx > 0) {
            //go back one page
            //recover the original value
            this.visible_slice_count= this.original_visible_slice_count;
            this.first_slice_idx -= this.visible_slice_count;
            if (this.first_slice_idx < 0) {
                this.first_slice_idx= 0;
            }
            this.reset_sclice_anim();
            this.set_highlighted_slice(-1);
            calc_key_navigation_pos();
            this.key_board_control = true;

        } else if (this.visible_slice_count < slices.size) {
            //go to last page
            int n= slices.size % this.original_visible_slice_count;
            if (n == 0)
                //all pages have the same number of slices
                this.visible_slice_count= this.original_visible_slice_count;
            else
                //last page has less slices than previous
                this.visible_slice_count= n;
            this.first_slice_idx= slices.size - this.visible_slice_count;
            this.reset_sclice_anim();
            this.set_highlighted_slice(-1);
            calc_key_navigation_pos();
            this.key_board_control = true;
        }
    }

    private void reset_sclice_anim() {
        //reset animation values in all the new visible slices
        for (int i= 0; i < this.visible_slice_count; ++i)
            this.slices[ i+this.first_slice_idx ].reset_anim();
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the amount of slices in this pie.
    /////////////////////////////////////////////////////////////////////

    public int slice_count() {
        return slices.size;
    }

    /////////////////////////////////////////////////////////////////////
    /// Draws the entire pie.
    /////////////////////////////////////////////////////////////////////

    public void draw(double frame_time, Cairo.Context ctx, int mouse_x, int mouse_y) {
        if (this.size_w > 0) {
            double distance = sqrt(mouse_x*mouse_x + mouse_y*mouse_y);
            double angle = 0.0;
            int slice_track= 0;

            if (this.key_board_control) {
                int n= this.active_slice - this.first_slice_idx;
                angle = 2.0*PI*n/(double)this.total_slice_count + this.first_slice_angle;
                slice_track= 1;
            } else {

                if (distance > 0) {
                    angle = acos(mouse_x/distance);
                    if (mouse_y < 0)
                        angle = 2*PI - angle;
                }

                int next_active_slice = this.active_slice;

                if (distance < Config.global.theme.active_radius
                    && this.quickaction >= this.first_slice_idx
                    && this.quickaction < this.first_slice_idx+this.visible_slice_count) {

                    next_active_slice = this.quickaction;
                    int n= this.quickaction - this.first_slice_idx;
                    angle = 2.0*PI*n/(double)this.total_slice_count + this.first_slice_angle;

                } else if (distance > Config.global.theme.active_radius && this.total_slice_count > 0
                           && distance < this.activation_range) {
                    double a= angle-this.first_slice_angle;
                    if (a < 0)
                        a= a + 2*PI;
                    next_active_slice = (int)(a*this.total_slice_count/(2*PI) + 0.5) % this.total_slice_count;
                    if (next_active_slice >= this.visible_slice_count)
                        next_active_slice = -1;
                    else {
                        next_active_slice = next_active_slice + this.first_slice_idx;
                        slice_track= 1;
                    }
                } else {
                    next_active_slice = -1;
                }

                this.set_highlighted_slice(next_active_slice);
            }

            center.draw(frame_time, ctx, angle, slice_track);

            //foreach (var slice in this.slices)
            for (int i= 0; i < this.visible_slice_count; ++i) {
               this.slices[ i+this.first_slice_idx ].draw(frame_time, ctx, angle, slice_track);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the user moves the mouse.
    /////////////////////////////////////////////////////////////////////

    public void on_mouse_move() {
        this.key_board_control = false;
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the currently active slice changes.
    /////////////////////////////////////////////////////////////////////

    public void set_highlighted_slice(int index) {
        if (index != this.active_slice) {
            if (index >= this.first_slice_idx && index < this.first_slice_idx+this.visible_slice_count)
                this.active_slice = index;
            // else if (this.quickaction >= this.first_slice_idx && this.quickaction < this.first_slice_idx+this.visible_slice_count)
            //     this.active_slice = this.quickaction;
            else
                this.active_slice = -1;

            SliceRenderer? active = (this.active_slice >= 0 && this.active_slice < slices.size) ?
                                     this.slices[this.active_slice] : null;

            center.set_active_slice(active);

            //foreach (var slice in this.slices)
            //    slice.set_active_slice(active);
            for (int i= 0; i < this.visible_slice_count; ++i) {
               this.slices[ i+this.first_slice_idx ].set_active_slice(active);
            }
        }
    }

    private void set_show_mode(ShowPieMode show_mode) {
        //The index of the first visible slice
        this.first_slice_idx= 0;
        //Angular position of the first visible slice
        this.first_slice_angle= 0;

        int mult= 1;
        switch(show_mode) {
            //half pie
            case ShowPieMode.HPIE_LEFT:
                mult= 2;
                this.first_slice_angle= -PI/2;
                break;
            case ShowPieMode.HPIE_RIGHT:
                mult= 2;
                this.first_slice_angle= PI/2;
                break;
            case ShowPieMode.HPIE_TOP:
                mult= 2;
                break;
            case ShowPieMode.HPIE_BOTTOM:
                this.first_slice_angle= PI;
                mult= 2;
                break;

            //cuarter pie
            case ShowPieMode.CPIE_TOP_LEFT:
                mult= 4;
                break;
            case ShowPieMode.CPIE_TOP_RIGHT:
                this.first_slice_angle= PI/2;
                mult= 4;
                break;
            case ShowPieMode.CPIE_BOT_LEFT:
                this.first_slice_angle= -PI/2;
                mult= 4;
                break;
            case ShowPieMode.CPIE_BOT_RIGHT:
                this.first_slice_angle= PI;
                mult= 4;
                break;

            default:     //ShowPieMode.FULL_PIE or invalid values
                show_mode= ShowPieMode.FULL_PIE;
                break;
        }
        this.pie_show_mode= show_mode;
        //limit the number of visible slices
        int maxview= this.max_visible_slices / mult;
        //Number of visible slices
        this.visible_slice_count= (int)fmin(slices.size, maxview);
        //Number of slices in full pie (visible or not)
        this.total_slice_count= this.visible_slice_count*mult;
        if (mult > 1) {
            this.total_slice_count -= mult;
        }

        //keep a copy of the original value since page up/down change it
        original_visible_slice_count= visible_slice_count;

        calc_key_navigation_pos();
    }

    private void calc_key_navigation_pos() {
           //calc slices index for keyboard navigation

        int a= this.first_slice_idx;
        int b= this.first_slice_idx + this.visible_slice_count/4;
        int c= this.first_slice_idx + this.visible_slice_count/2;
        int d= this.first_slice_idx + (this.visible_slice_count*3)/4;
        int e= this.first_slice_idx + this.visible_slice_count -1;
        switch(this.pie_show_mode) {
            //half pie
            case ShowPieMode.HPIE_LEFT:
                this.up_slice_idx=    a;
                this.right_slice_idx= c;
                this.down_slice_idx=  e;
                this.left_slice_idx=  -1;    //no left slice, go up instead
                break;
            case ShowPieMode.HPIE_RIGHT:
                this.down_slice_idx=  a;
                this.left_slice_idx=  c;
                this.up_slice_idx=    e;
                this.right_slice_idx= -1;   //no right slice, go down instead
                break;
            case ShowPieMode.HPIE_TOP:
                this.right_slice_idx= a;
                this.down_slice_idx=  c;
                this.left_slice_idx=  e;
                this.up_slice_idx=    -1;    //no up slice, go left instead
                break;
            case ShowPieMode.HPIE_BOTTOM:
                this.left_slice_idx=  a;
                this.up_slice_idx=    c;
                this.right_slice_idx= e;
                this.down_slice_idx=  -1;   //no down slice, go right instead
                break;

            //cuarter pie
            case ShowPieMode.CPIE_TOP_LEFT:
                this.right_slice_idx= a;
                this.down_slice_idx=  e;
                this.up_slice_idx=    -1;    //no up slice, go right instead
                this.left_slice_idx=  -1;    //no left slice, go down instead
                break;
            case ShowPieMode.CPIE_TOP_RIGHT:
                this.down_slice_idx=  a;
                this.left_slice_idx=  e;
                this.up_slice_idx=    -1;    //no up slice, go left instead
                this.right_slice_idx= -1;    //no righ slice, go down instead
                break;
            case ShowPieMode.CPIE_BOT_LEFT:
                this.up_slice_idx=    a;
                this.right_slice_idx= e;
                this.down_slice_idx=  -1;    //no down slice, go right instead
                this.left_slice_idx=  -1;    //no left slice, go up instead
                break;
            case ShowPieMode.CPIE_BOT_RIGHT:
                this.left_slice_idx=  a;
                this.up_slice_idx=    e;
                this.down_slice_idx=  -1;    //no down slice, go left instead
                this.right_slice_idx= -1;    //no right slice, go up instead
                break;

            default:     //ShowPieMode.FULL_PIE or invalid values
                this.right_slice_idx= a;
                this.down_slice_idx=  b;
                this.left_slice_idx=  c;
                this.up_slice_idx=    d;
                break;
        }
    }


   /////////////////////////////////////////////////////////////////////
    /// keyboard navigation helper
    /// move current position one slice towards the given extreme
    /////////////////////////////////////////////////////////////////////

    private void move_active_slice(int extreme, int other_extreme ) {
        int pos= this.active_slice;

        if (pos < 0 || pos == extreme) {
            //no actual position or allready at the extreme
            pos= extreme; //go to the extreme pos

        } else if (extreme == -1) {
            //the extreme was eaten, just go away from the other_extreme
            if (pos > other_extreme || other_extreme == 0) {
                if (pos < this.visible_slice_count+this.first_slice_idx-1)
                    pos++;
            } else if (pos > this.first_slice_idx)
                pos--;

        } else if (other_extreme == -1) {
            //the other_extreme was eaten, just get closer to the extreme
            if (pos < extreme)
                pos++;
            else if (pos > extreme)
                pos--;

        } else if (pos == other_extreme) {
            //both extremes are present
            //jump quickly form one extreme to the other
            pos= extreme; //go to the extreme pos

        } else {
            //both extremes are present
            //add or substract 1 to position in a circular manner
            if (extreme > other_extreme) {
                if (pos > other_extreme && pos < extreme)
                    //other_extreme < pos < extreme
                    pos= pos+1;
                else
                    pos= pos-1;
            } else {
                if (pos > extreme && pos < other_extreme)
                    //extreme < pos < other_extreme
                    pos= pos-1;
                else
                    pos= pos+1;
            }

            if (pos < this.first_slice_idx)
                pos= this.visible_slice_count-1+this.first_slice_idx;

            if (pos >= this.visible_slice_count+this.first_slice_idx)
                pos= this.first_slice_idx;
        }

        this.set_highlighted_slice(pos);

        this.key_board_control = true;
    }
}

}
