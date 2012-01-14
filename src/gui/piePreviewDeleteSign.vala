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

public class PiePreviewDeleteSign : GLib.Object {

    public signal void on_clicked();
    
    public Image icon { get; private set; }
    
    private const int radius = 18;
    private const double globale_scale = 0.8;

    private bool visible = false;
    private AnimatedValue size;
    private AnimatedValue alpha; 
    private AnimatedValue activity; 
    private AnimatedValue clicked; 

    public PiePreviewDeleteSign() {
        this.size = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 2.0);
        this.alpha = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 0.0);
        this.activity = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, -3, -3, 0, 0.0);
        this.clicked = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 1, 1, 0, 0.0);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads an Action. All members are initialized accordingly.
    /////////////////////////////////////////////////////////////////////

    public void load() {
        this.icon = new Icon("stock_delete", radius*2);
    }
    
    public void show() {
        if (!this.visible) {
            this.visible = true;
            this.alpha.reset_target(1.0, 0.3);   
        }
    }
    
    public void hide() {
        if (this.visible) {
            this.visible = false;
            this.alpha.reset_target(0.0, 0.3);     
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////

    public void set_size(double size) {
        this.size.reset_target(size, 0.2);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Draws all layers of the slice.
    /////////////////////////////////////////////////////////////////////

    public void draw(double frame_time, Cairo.Context ctx) {
        this.size.update(frame_time);
        this.alpha.update(frame_time);
        this.activity.update(frame_time);
        this.clicked.update(frame_time);
        
        if (this.alpha.val > 0) {
            ctx.save();
            
            // transform the context
            double scale = (this.size.val*this.clicked.val 
                         + this.activity.val*0.2 - 0.2)*globale_scale;
            ctx.scale(scale, scale);
        
            // paint the image
            icon.paint_on(ctx, this.alpha.val);
                
            ctx.restore();
        }
    }
    
    public bool on_mouse_move(double x, double y) {
        if (this.clicked.end == 0.9) {
            this.clicked.reset_target(1.0, 0.1);
        }
    
	    if (GLib.Math.fabs(x) <= radius*globale_scale && GLib.Math.fabs(y) <= radius*globale_scale) {
	        this.activity.reset_target(1.0, 0.2);
	        return true;
        } 
        
        this.activity.reset_target(0.0, 0.2);
        return false;
    }
    
    public bool on_button_press() {
        if (this.activity.end == 1.0) {
            this.clicked.reset_target(0.9, 0.1);
            return true;
        }
        return false;
    }
    
    public bool on_button_release() {
        if (this.clicked.end == 0.9) {
            this.clicked.reset_target(1.0, 0.1);
            this.on_clicked();
            
            return true;
        }
        return false;
    }
}

}
