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
    
    private Image icon;

    private unowned PiePreviewRenderer parent;    
    
    /////////////////////////////////////////////////////////////////////
    /// The index of this slice in a pie. Clockwise assigned, starting
    /// from the right-most slice.
    /////////////////////////////////////////////////////////////////////
    
    private int position;

    public SlicePreviewRenderer(PiePreviewRenderer parent) {
        this.parent = parent;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads an Action. All members are initialized accordingly.
    /////////////////////////////////////////////////////////////////////

    public void load(Action action, int position) {
        this.position = position;
        this.icon = new ThemedIcon(action.icon, true);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Draws all layers of the slice.
    /////////////////////////////////////////////////////////////////////

    public void draw(double frame_time, Cairo.Context ctx) {
	    double direction = 2.0 * PI * position/parent.slice_count();
        
        ctx.save();
        
        // distance from the center
        double radius = 100;
        
        // transform the context
        ctx.translate(cos(direction)*radius, sin(direction)*radius);
    
        // paint the image
        icon.paint_on(ctx);
            
        ctx.restore();
    }
}

}
