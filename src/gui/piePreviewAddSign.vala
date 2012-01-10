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

public class PiePreviewAddSign : GLib.Object {

    public signal void on_clicked(int position);
    
    public Image icon { get; private set; }
    public bool visible { get; private set; default=false; }
    
    private double position = 0;

    private unowned PiePreviewRenderer parent;  
    
    private double time = 0;
    private double max_size = 0; 
    private double angle = 0; 
    private AnimatedValue size; 
    private AnimatedValue alpha; 
    private AnimatedValue activity; 
    private AnimatedValue clicked; 

    public PiePreviewAddSign(PiePreviewRenderer parent) {
        this.parent = parent;
        
        this.size = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 2.0);
        this.alpha = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 0.0);
        this.activity = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 0.0);
        this.clicked = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 1, 1, 0, 0.0);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads an Action. All members are initialized accordingly.
    /////////////////////////////////////////////////////////////////////

    public void load(Icon icon) {
        this.icon = icon;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////

    public void set_position(int position) {
        double new_position = position;
        
        if (!this.parent.drag_n_drop_mode)
            new_position += 0.5;

        this.position = new_position;
        this.angle = 2.0 * PI * new_position/parent.slice_count();
    }
    
    public void show() {
        this.visible = true;
        this.size.reset_target(this.max_size, 0.3); 
        this.alpha.reset_target(1.0, 0.3);   
    }
    
    public void hide() {
        this.visible = false;
        this.size.reset_target(0.0, 0.3); 
        this.alpha.reset_target(0.0, 0.3);     
    }
    
    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////

    public void set_size(double size) {
        this.max_size = size;
        this.size.reset_target(size, 0.5);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Draws all layers of the slice.
    /////////////////////////////////////////////////////////////////////

    public void draw(double frame_time, Cairo.Context ctx) {

        this.time += frame_time;
        
        this.size.update(frame_time);
        this.alpha.update(frame_time);
        this.activity.update(frame_time);
        this.clicked.update(frame_time);
        
        if (this.alpha.val*this.activity.val > 0) {
            ctx.save();
            
            // distance from the center
            double radius = 120;
            
            // transform the context
            ctx.translate(cos(this.angle)*radius, sin(this.angle)*radius);
            ctx.scale(this.size.val*this.activity.val*this.clicked.val, this.size.val*this.activity.val*this.clicked.val);
            ctx.rotate(this.activity.val*GLib.Math.sin(this.time*10)*0.2);
        
            // paint the image
            icon.paint_on(ctx, this.alpha.val*this.activity.val);
                
            ctx.restore();
        }
    }
    
    public void on_mouse_move(double angle) {
        double direction = 2.0 * PI * position/parent.slice_count();
        double diff = fabs(angle-direction);
        
        if (diff > PI)
	        diff = 2 * PI - diff;
	    
	    if (diff < 0.5*PI/parent.slice_count()) this.activity.reset_target(1.0, 0.2);
        else                                    this.activity.reset_target(0.0, 0.2);
    }
    
    public void on_button_press() {
        if (this.activity.end == 1.0)
            this.clicked.reset_target(0.8, 0.1);
    }
    
    public void on_button_release() {
        if (this.clicked.end == 0.8) {
            this.clicked.reset_target(1.0, 0.1);
            this.on_clicked((int)this.position);
        }
    }
}

}
