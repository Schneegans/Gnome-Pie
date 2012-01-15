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
/// 
/////////////////////////////////////////////////////////////////////////

public class SlicePreviewRenderer : GLib.Object {

    public signal void on_clicked(int position);
    
    public Image icon { get; private set; }
    public ActionGroup action_group { get; private set; }

    private unowned PiePreviewRenderer parent;  
    
    private double time = 0;
    private AnimatedValue angle; 
    private AnimatedValue size; 
    private AnimatedValue activity; 
    private AnimatedValue clicked; 
    
    /////////////////////////////////////////////////////////////////////
    /// The index of this slice in a pie. Clockwise assigned, starting
    /// from the right-most slice.
    /////////////////////////////////////////////////////////////////////
    
    private int position;

    public SlicePreviewRenderer(PiePreviewRenderer parent) {
        this.parent = parent;
        this.angle = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 0.5);
        this.size = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 0.0);
        this.activity = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 0.0);
        this.clicked = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 1, 1, 0, 0.0);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads an Action. All members are initialized accordingly.
    /////////////////////////////////////////////////////////////////////

    public void load(ActionGroup group) {
        this.action_group = group;
        
        // if it's a custom ActionGroup
        if (group.get_type().depth() == 2 && group.actions.size > 0) {
            this.icon = new Icon(group.actions[0].icon, 48);
        } else {
            this.icon = new Icon(GroupRegistry.descriptions[group.get_type()].icon, 48);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////

    public void set_position(int position) {
        double direction = 2.0 * PI * position/parent.slice_count();
        
        if (direction != this.angle.end) {
            this.position = position;
            this.angle.reset_target(direction, 0.5);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////

    public void set_size(double size) {
        this.size.reset_target(size, 0.5);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Draws all layers of the slice.
    /////////////////////////////////////////////////////////////////////

    public void draw(double frame_time, Cairo.Context ctx) {

        this.time += frame_time;
        
        this.size.update(frame_time);
        this.angle.update(frame_time);
        this.activity.update(frame_time);
        this.clicked.update(frame_time);

        ctx.save();
        
        // distance from the center
        double radius = 120;
        
        // transform the context
        ctx.translate(cos(this.angle.val)*radius, sin(this.angle.val)*radius);
        ctx.scale(this.size.val*this.clicked.val, this.size.val*this.clicked.val);
        ctx.rotate(this.activity.val*GLib.Math.sin(this.time*10)*0.2);
    
        // paint the image
        icon.paint_on(ctx);
            
        ctx.restore();
    }
    
    public void on_mouse_move(double angle) {
        double direction = 2.0 * PI * position/parent.slice_count();
        double diff = fabs(angle-direction);
        
        if (diff > PI)
	        diff = 2 * PI - diff;
	    
	    if (diff < 0.5*PI/parent.slice_count()) this.activity.reset_target(0.5, 0.3);
        else                                    this.activity.reset_target(0.0, 0.3);
        
        if (this.clicked.end == 0.8) {
            this.clicked.reset_target(1.0, 0.1);
        }
    }
    
    public void on_button_press() {
        if (this.activity.end == 0.5)
            this.clicked.reset_target(0.8, 0.1);
    }
    
    public void on_button_release() {
        if (this.clicked.end == 0.8) {
            this.clicked.reset_target(1.0, 0.1);
            this.on_clicked(this.position);
        }
    }
}

}
