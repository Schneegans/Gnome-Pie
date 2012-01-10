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

public class PiePreviewRenderer : GLib.Object {

    public signal void on_add_slice(int position);
    public signal void on_remove_slice(int position);
    public signal void on_edit_slice(int position);
    
    public Gee.ArrayList<SlicePreviewRenderer?> slices;
    public bool drag_n_drop_mode { get; private set; default=false; }
    
    private PiePreviewAddSign add_sign = null;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes members.
    /////////////////////////////////////////////////////////////////////
    
    public PiePreviewRenderer() {
        this.slices = new Gee.ArrayList<SlicePreviewRenderer?>(); 
        this.add_sign = new PiePreviewAddSign(this);
        this.add_sign.load(new Icon("add", 24));
        
        this.add_sign.on_clicked.connect((pos) => {
            this.on_add_slice(pos);
        });
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads an Pie. All members are initialized accordingly.
    /////////////////////////////////////////////////////////////////////
    
    public void load_pie(Pie pie) {
        this.slices.clear();
    
        foreach (var group in pie.action_groups) {
            var renderer = new SlicePreviewRenderer(this);
            this.slices.add(renderer);
            renderer.load(group);
            
            renderer.on_clicked.connect((pos) => {
                this.on_edit_slice(pos);
            });
        }
        
        double size = this.slice_count() > 8 ? (1.0 - (this.slice_count() - 8)/16.0) : 1.0;
        
        this.add_sign.set_size(size);
        
        for (int i=0; i<this.slices.size; ++i) {
            this.slices[i].set_position(i);
            this.slices[i].set_size(size);
        }
    }
    
    public void set_dnd_mode(bool dnd) {
        this.drag_n_drop_mode = dnd;
    }
    
    public int slice_count() {
        if (this.drag_n_drop_mode) return slices.size+1;
        
        return slices.size;
    }
    
    public void draw(double frame_time, Cairo.Context ctx) {
        this.add_sign.draw(frame_time, ctx);
        
        foreach (var slice in this.slices)
            slice.draw(frame_time, ctx);
    }
    
    public void on_mouse_leave(double x, double y) {
        this.add_sign.hide();
        this.update_positions(x, y);
    }
    
    public void on_mouse_enter(double x, double y) {
        this.add_sign.show();
        this.update_positions(x, y);
    }
    
    public void on_mouse_move(double x, double y) {
        double angle = acos(x/sqrt(x*x + y*y));
        if (y < 0) angle = 2*PI - angle;
    
        foreach (var slice in this.slices)
            slice.on_mouse_move(angle);
            
        this.add_sign.on_mouse_move(angle);
        
        this.update_positions(x, y);
    }
    
    public void on_button_press() {
        foreach (var slice in this.slices)
            slice.on_button_press();
        this.add_sign.on_button_press();
    }
    
    public void on_button_release() {
        foreach (var slice in this.slices)
            slice.on_button_release();
        this.add_sign.on_button_release();
    }
    
    private void update_positions(double x, double y) {
        double angle = acos(x/sqrt(x*x + y*y));
        if (y < 0) angle = 2*PI - angle;
        
        if (this.add_sign.visible || this.drag_n_drop_mode) {
            int add_position = 0;
            if (this.drag_n_drop_mode) add_position = (int)(angle/(2*PI)*this.slice_count() + 0.5) % this.slice_count();
            else                       add_position = (int)(angle/(2*PI)*this.slice_count()) % this.slice_count();
            this.add_sign.set_position(add_position);
            
            for (int i=0; i<this.slices.size; ++i) {
                if (this.drag_n_drop_mode) this.slices[i].set_position(i >= add_position ? i+1 : i);
                else                       this.slices[i].set_position(i);
            }
        } else {
            for (int i=0; i<this.slices.size; ++i) {
                this.slices[i].set_position(i);
            }
        }
    }
}

}
