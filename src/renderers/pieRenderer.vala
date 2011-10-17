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

    public int quick_action { get; private set; }

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

    public int size { get; private set; }
    
    /////////////////////////////////////////////////////////////////////
    /// All SliceRenderers used to draw this Pie.
    /////////////////////////////////////////////////////////////////////
    
    private Gee.ArrayList<SliceRenderer?> slices;
    
    /////////////////////////////////////////////////////////////////////
    /// The renderer for the center of this pie.
    /////////////////////////////////////////////////////////////////////
    
    private CenterRenderer center;
    
    /////////////////////////////////////////////////////////////////////
    /// True if the pie is currently navigated with the keyboard. This is
    /// set to false as soon as the mouse moves.
    /////////////////////////////////////////////////////////////////////
    
    private bool key_board_control = false;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes members.
    /////////////////////////////////////////////////////////////////////
    
    public PieRenderer() {
        this.slices = new Gee.ArrayList<SliceRenderer?>(); 
        this.center = new CenterRenderer(this);
        this.quick_action = -1;
        this.active_slice = -2;
        this.size = 0;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads an Pie. All members are initialized accordingly.
    /////////////////////////////////////////////////////////////////////
    
    public void load_pie(Pie pie) {
        this.slices.clear();
    
        int count = 0;
        foreach (var group in pie.action_groups) {
            foreach (var action in group.actions) {
                var renderer = new SliceRenderer(this);
                this.slices.add(renderer);
                renderer.load(action, slices.size-1);
                
                if (action.is_quick_action) {
                    this.quick_action = count;
                }
                
                ++count;
            }
        }
        
        this.set_highlighted_slice(this.quick_action);
        
        this.size = (int)fmax(2*Config.global.theme.radius + 2*Config.global.theme.slice_radius*Config.global.theme.max_zoom,
                              2*Config.global.theme.center_radius);
        
        // increase size if there are many slices
        if (slices.size > 0) {
            this.size = (int)fmax(this.size,
                (((Config.global.theme.slice_radius + Config.global.theme.slice_gap)/tan(PI/slices.size)) 
                + Config.global.theme.slice_radius)*2*Config.global.theme.max_zoom);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Activates the currently active slice.
    /////////////////////////////////////////////////////////////////////
    
    public void activate() {
        if (this.active_slice >= 0 && this.active_slice < this.slices.size)
            slices[active_slice].activate();
        this.cancel();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Asks all renders to fade out.
    /////////////////////////////////////////////////////////////////////
    
    public void cancel() {
        foreach (var slice in this.slices)
            slice.fade_out();
            
        center.fade_out();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the up-key is pressed. Selects the next slice towards
    /// the top. 
    /////////////////////////////////////////////////////////////////////
    
    public void select_up() {
        int bottom = this.slice_count()/4;
        int top = this.slice_count()*3/4;
    
        if (this.active_slice == -1 || this.active_slice == bottom)
           this.set_highlighted_slice(top);
        else if (this.active_slice > bottom && this.active_slice < top)
           this.set_highlighted_slice(this.active_slice+1);
        else if (this.active_slice != top)
           this.set_highlighted_slice((this.active_slice-1+this.slice_count())%this.slice_count());
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the down-key is pressed. Selects the next slice
    /// towards the bottom. 
    /////////////////////////////////////////////////////////////////////
    
    public void select_down() {
        int bottom = this.slice_count()/4;
        int top = this.slice_count()*3/4;
    
        if (this.active_slice == -1 || this.active_slice == top)
           this.set_highlighted_slice(bottom);
        else if (this.active_slice > bottom && this.active_slice < top)
           this.set_highlighted_slice(this.active_slice-1);
        else if (this.active_slice != bottom)
           this.set_highlighted_slice((this.active_slice+1)%this.slice_count());
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the left-key is pressed. Selects the next slice
    /// towards the left. 
    /////////////////////////////////////////////////////////////////////
    
    public void select_left() {
        int left = this.slice_count()/2;
        int right = 0;
    
        if (this.active_slice == -1 || this.active_slice == right)
           this.set_highlighted_slice(left);
        else if (this.active_slice > left)
           this.set_highlighted_slice(this.active_slice-1);
        else if (this.active_slice < left)
           this.set_highlighted_slice(this.active_slice+1);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the right-key is pressed. Selects the next slice
    /// towards the right. 
    /////////////////////////////////////////////////////////////////////
    
    public void select_right() {
        int left = this.slice_count()/2;
        int right = 0;
    
        if (this.active_slice == -1 || this.active_slice == left)
           this.set_highlighted_slice(right);
        else if (this.active_slice > left)
           this.set_highlighted_slice((this.active_slice+1)%this.slice_count());
        else if (this.active_slice < left && this.active_slice != right)
           this.set_highlighted_slice((this.active_slice-1+this.slice_count())%this.slice_count());
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
	    double distance = sqrt(mouse_x*mouse_x + mouse_y*mouse_y);
	    double angle = 0.0;

	    if (this.key_board_control) {
	        angle = 2.0*PI*this.active_slice/(double)slice_count();
	    } else {
	    
	        if (distance > 0) {
	            angle = acos(mouse_x/distance);
		        if (mouse_y < 0) 
		            angle = 2*PI - angle;
	        }
	        
	        int next_active_slice = this.active_slice;
	        
	        if (distance < Config.global.theme.active_radius
	            && this.quick_action >= 0 && this.quick_action < this.slices.size) {
	         
	            next_active_slice = this.quick_action;   
	            angle = 2.0*PI*quick_action/(double)slice_count();
	        } else if (distance > Config.global.theme.active_radius && this.slice_count() > 0) {
	            next_active_slice = (int)(angle*slices.size/(2*PI) + 0.5) % this.slice_count();
	        } else {
	            next_active_slice = -1;
	        }
	    
	        this.set_highlighted_slice(next_active_slice);
	    }

        center.draw(frame_time, ctx, angle, distance);
	    
	    foreach (var slice in this.slices)
		    slice.draw(frame_time, ctx, angle, distance);
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
            if (index >= 0 && index < this.slice_count()) 
                this.active_slice = index;
            else if (this.quick_action >= 0)
                this.active_slice = this.quick_action;
            else
                this.active_slice = -1;
            
            SliceRenderer? active = (this.active_slice >= 0 && this.active_slice < this.slice_count()) ?
                                     this.slices[this.active_slice] : null;
	                    
            center.set_active_slice(active);
            
            foreach (var slice in this.slices)
                slice.set_active_slice(active);
            
            this.key_board_control = true;
        }
    }
}

}
