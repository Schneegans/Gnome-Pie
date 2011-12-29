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

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////    
/// 
/////////////////////////////////////////////////////////////////////////

class PiePreview : Gtk.DrawingArea {

    private PiePreviewRenderer renderer = null;
    
    /////////////////////////////////////////////////////////////////////
    /// A timer used for calculating the frame time.
    /////////////////////////////////////////////////////////////////////
    
    private GLib.Timer timer;

    public PiePreview() {
        this.renderer = new PiePreviewRenderer();
        this.expose_event.connect(this.on_draw);
        this.timer = new GLib.Timer();
        this.show.connect(this.timer.start);
        
        this.set_size_request(900, 900);
    }
    
    public void set_pie(string id) {
        this.renderer.load_pie(PieManager.all_pies[id]);
        this.queue_draw();
    }
    
    private bool on_draw(Gtk.Widget da, Gdk.EventExpose event) { 
        // store the frame time
        double frame_time = this.timer.elapsed();
        this.timer.reset();
        
        var ctx = Gdk.cairo_create(this.window);
        ctx.translate(this.allocation.width*0.5, this.allocation.height*0.5);
        
        this.renderer.draw(frame_time, ctx);
        
        return true;
    }
   
}

}
