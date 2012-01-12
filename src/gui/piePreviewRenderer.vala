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
    
    public Gee.ArrayList<PiePreviewSliceRenderer?> slices;
    public bool drag_n_drop_mode { get; private set; default=false; }
    
    private PiePreviewSliceRenderer hidden_group = null;
    private PiePreviewAddSign add_sign = null;
    private double angle = 0.0;
    private int active_slice = -1;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes members.
    /////////////////////////////////////////////////////////////////////
    
    public PiePreviewRenderer() {
        this.slices = new Gee.ArrayList<PiePreviewSliceRenderer?>(); 
        this.add_sign = new PiePreviewAddSign(this);
        this.add_sign.load();
        
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
            var renderer = new PiePreviewSliceRenderer(this);
            this.slices.add(renderer);
            renderer.load(group);
            
            renderer.on_clicked.connect((pos) => {
                this.on_edit_slice(pos);
            });
            
            renderer.on_remove.connect((pos) => {
                this.on_remove_slice(pos);
            });
        }
        
        this.update_sizes();
        this.update_positions(false);
    }
    
    public void set_dnd_mode(bool dnd) {
        if (this.drag_n_drop_mode != dnd) {
            this.drag_n_drop_mode = dnd;
            this.update_positions();
            this.update_sizes();
        }
    }
    
    public int slice_count() {
        if (this.drag_n_drop_mode && !(this.slices.size == 0)) 
            return slices.size+1;
        
        return slices.size;
    }
    
    public int get_active_slice() {
        if (this.slices.size == 0)
            return 0;
    
        if (this.drag_n_drop_mode)
            return (int)(this.angle/(2*PI)*this.slice_count() + 0.5) % this.slice_count();
            
        return this.active_slice;
    }
    
    public Icon get_active_icon() {
        if (this.active_slice >= 0 && this.active_slice < this.slices.size)
            return this.slices[this.active_slice].icon;
        else
            return new Icon("", 24);
    }
    
    public void draw(double frame_time, Cairo.Context ctx) {
        this.add_sign.draw(frame_time, ctx);
        
        foreach (var slice in this.slices)
            slice.draw(frame_time, ctx);
    }
    
    public void on_mouse_leave(double x, double y) {
        this.add_sign.hide();
    }
    
    public void on_mouse_enter(double x, double y) {
        this.add_sign.show();
    }
    
    public void on_mouse_move(double x, double y) {
        this.angle = acos(x/sqrt(x*x + y*y));
        if (y < 0) this.angle = 2*PI - this.angle;
    
        if (!this.drag_n_drop_mode)
            this.active_slice = -1;
        
        for (int i=0; i<this.slices.size; ++i)
            if (slices[i].on_mouse_move(this.angle, x, y) && !this.drag_n_drop_mode)
                this.active_slice = i;
            
        this.add_sign.on_mouse_move(this.angle);
        
        this.update_positions();
    }
    
    public void on_button_press() {
        for (int i=0; i<this.slices.size; ++i)
            this.slices[i].on_button_press();
        this.add_sign.on_button_press();
    }
    
    public void on_button_release() {
        for (int i=0; i<this.slices.size; ++i)
            this.slices[i].on_button_release();
        this.add_sign.on_button_release();
    }
    
    public void add_group(ActionGroup group, int at_position = -1) {
        var renderer = new PiePreviewSliceRenderer(this);
        renderer.load(group);
        this.add_slice_renderer(renderer, at_position);
    }
    
    public void remove_group(int index) {
        if (this.slices.size > index) {
            this.slices.remove_at(index);
            this.update_positions();
            this.update_sizes();
        }
    }
    
    public void hide_group(int index) {
        if (this.slices.size > index) {
            this.hidden_group = this.slices[index];
            this.remove_group(index);
        }
    }
    
    public void show_hidden_group_at(int index) {
        if (this.slices.size >= index && this.hidden_group != null) {
            this.hidden_group.set_position(index, false);
            this.add_slice_renderer(this.hidden_group, index);
        }
    }
    
    public void move_group(int from, int to) {
        if (this.slices.size > from && this.slices.size > to) {
            var tmp = this.slices[from];
            this.remove_group(from);
            this.slices.insert(to, tmp);
            this.update_positions();
            this.update_sizes();
        }
    }
    
    public void update_group(ActionGroup group, int index) {
        if (this.slices.size > index) {
            var renderer = new PiePreviewSliceRenderer(this);
            this.slices.set(index, renderer);
            renderer.load(group);
            
            renderer.on_clicked.connect((pos) => {
                this.on_edit_slice(pos);
            });
            
            this.update_positions(false);
            this.update_sizes();
        }
    }
    
    private void add_slice_renderer(PiePreviewSliceRenderer renderer, int at_position) {
        if (at_position < 0 || at_position >= this.slices.size) {
            this.slices.add(renderer);
            
            renderer.on_clicked.connect((pos) => {
                this.on_edit_slice(pos);
            });
            
            renderer.on_remove.connect((pos) => {
                this.on_remove_slice(pos);
            });
            
        } else {
            this.slices.insert(at_position, renderer);
            
            renderer.on_clicked.connect((pos) => {
                this.on_edit_slice(pos);
            });
            
            renderer.on_remove.connect((pos) => {
                this.on_remove_slice(pos);
            });
        }
        this.update_positions(false);
        this.update_sizes();
    }
    
    private void update_positions(bool smoothly = true) {
        if (this.slices.size > 0) {
            if (this.add_sign.visible) {
                int add_position = 0;
                add_position = (int)(this.angle/(2*PI)*this.slice_count()) % this.slice_count();
                this.add_sign.set_position(add_position);
                
                for (int i=0; i<this.slices.size; ++i) {
                    this.slices[i].set_position(i, smoothly);
                }
            
            } else if (this.drag_n_drop_mode) {
                int add_position = 0;
                add_position = (int)(this.angle/(2*PI)*this.slice_count() + 0.5) % this.slice_count();

                for (int i=0; i<this.slices.size; ++i) {
                    this.slices[i].set_position(i >= add_position ? i+1 : i, smoothly);
                }
            } else {
                for (int i=0; i<this.slices.size; ++i) {
                    this.slices[i].set_position(i, smoothly);
                }
            }
        }
    }
        
    private void update_sizes() {
        double size = this.slice_count() > 8 ? (1.0 - (this.slice_count() - 8)/16.0) : 1.0;
        
        this.add_sign.set_size(size);
        
        for (int i=0; i<this.slices.size; ++i) 
            this.slices[i].set_size(size);
    }
}

}
