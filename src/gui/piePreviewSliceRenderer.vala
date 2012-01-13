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

public class PiePreviewSliceRenderer : GLib.Object {

    public signal void on_clicked(int position);
    public signal void on_remove(int position);
    
    public Icon icon { get; private set; }
    public ActionGroup action_group { get; private set; }
    public string name { get; private set; default=""; }

    private unowned PiePreviewRenderer parent;  
    
    private PiePreviewDeleteSign delete_sign = null;
    
    private AnimatedValue angle; 
    private AnimatedValue size; 
    private AnimatedValue activity; 
    private AnimatedValue clicked; 
    
    // distance from the center
    private double pie_radius = 120;
    private double radius = 24;
    private const double delete_x = 15;
    private const double delete_y = -15;
    
    /////////////////////////////////////////////////////////////////////
    /// The index of this slice in a pie. Clockwise assigned, starting
    /// from the right-most slice.
    /////////////////////////////////////////////////////////////////////
    
    private int position;

    public PiePreviewSliceRenderer(PiePreviewRenderer parent) {
        this.delete_sign = new PiePreviewDeleteSign();
        this.delete_sign.load();
        this.delete_sign.on_clicked.connect(() => {
            this.on_remove(this.position);
        });
    
        this.parent = parent;
        this.angle = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 0.5);
        this.size = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 1.0);
        this.activity = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 0.0);
        this.clicked = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 1, 1, 0, 1.0);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads an Action. All members are initialized accordingly.
    /////////////////////////////////////////////////////////////////////

    public void load(ActionGroup group) {
        this.action_group = group;
        
        // if it's a custom ActionGroup
        if (group.get_type().depth() == 2 && group.actions.size > 0) {
            this.icon = new Icon(group.actions[0].icon, (int)(radius*2));
            this.name = group.actions[0].name;
        } else {
            this.icon = new Icon(GroupRegistry.descriptions[group.get_type()].icon, (int)(radius*2));
            this.name = GroupRegistry.descriptions[group.get_type()].name;
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////

    public void set_position(int position, bool smoothly = true) {
        double direction = 2.0 * PI * position/parent.slice_count();
        
        if (direction != this.angle.end) {
            this.position = position;
            this.angle.reset_target(direction, smoothly ? 0.5 : 0.0);
            
            if (!smoothly)
                this.angle.update(1.0);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////

    public void set_size(double size) {
        this.size.reset_target(size, 0.5);
        this.delete_sign.set_size(size);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Draws all layers of the slice.
    /////////////////////////////////////////////////////////////////////

    public void draw(double frame_time, Cairo.Context ctx) {
        this.size.update(frame_time);
        this.angle.update(frame_time);
        this.activity.update(frame_time);
        this.clicked.update(frame_time);

        ctx.save();
        
            // transform the context
            ctx.translate(cos(this.angle.val)*pie_radius, sin(this.angle.val)*pie_radius);
            
            double scale = this.size.val*this.clicked.val 
                         + this.activity.val*0.1 - 0.1;
            ctx.save();     
                        
                ctx.scale(scale, scale);
            
                // paint the image
                icon.paint_on(ctx);
            
            ctx.restore();
            
            ctx.translate(delete_x*this.size.val, delete_y*this.size.val);
            this.delete_sign.draw(frame_time, ctx);
            
        ctx.restore();
    }
    
    public bool on_mouse_move(double angle, double x, double y) {
        double direction = 2.0 * PI * position/parent.slice_count();
        double diff = fabs(angle-direction);
        
        if (diff > PI)
	        diff = 2 * PI - diff;
	        
	    bool active = diff < 0.5*PI/parent.slice_count();
	    
	    if (active) {
	        this.activity.reset_target(1.0, 0.3);
	        this.delete_sign.show();
        } else {
            this.activity.reset_target(0.0, 0.3);
            this.delete_sign.hide();
        }                                  
        
        if (this.clicked.end == 0.8) {
            this.clicked.reset_target(1.0, 0.1);
        }
        
        double own_x = cos(this.angle.val)*pie_radius;
        double own_y = sin(this.angle.val)*pie_radius;
        this.delete_sign.on_mouse_move(x - own_x - delete_x*this.size.val, 
                                       y - own_y - delete_y*this.size.val);
                                       
        return active;
    }
    
    public void on_button_press() {
        bool delete_pressed = this.delete_sign.on_button_press();
    
        if (!delete_pressed && this.activity.end == 1.0)
            this.clicked.reset_target(0.9, 0.1);
    }
    
    public void on_button_release() {
        this.delete_sign.on_button_release();
        
        if (this.clicked.end == 0.9) {
            this.clicked.reset_target(1.0, 0.1);
            this.on_clicked(this.position);
        }
    }
}

}
