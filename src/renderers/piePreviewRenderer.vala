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
    
    private Gee.ArrayList<SlicePreviewRenderer?> slices;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes members.
    /////////////////////////////////////////////////////////////////////
    
    public PiePreviewRenderer() {
        this.slices = new Gee.ArrayList<SlicePreviewRenderer?>(); 
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads an Pie. All members are initialized accordingly.
    /////////////////////////////////////////////////////////////////////
    
    public void load_pie(Pie pie) {
        this.slices.clear();
    
        foreach (var group in pie.action_groups) {
            foreach (var action in group.actions) {
                var renderer = new SlicePreviewRenderer(this);
                this.slices.add(renderer);
                renderer.load(action, slices.size-1);
            }
        }
    }
    
    public int slice_count() {
        return slices.size;
    }
    
    public void draw(double frame_time, Cairo.Context ctx) {
        foreach (var slice in this.slices)
            slice.draw(frame_time, ctx);
    }
}

}
