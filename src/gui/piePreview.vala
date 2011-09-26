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

    private PieRenderer renderer = null;

    public PiePreview() {
        
        this.expose_event.connect(this.on_draw);
    }
    
    private bool on_draw(Gtk.Widget da, Gdk.EventExpose event) {
        
        if (this.renderer == null) {
            this.renderer = new PieRenderer();
            this.renderer.load_pie(PieManager.all_pies["896"]);
        }
        
        var ctx = Gdk.cairo_create(this.window);
            ctx.translate(this.allocation.width*0.5, this.allocation.height*0.5);
        
        this.renderer.draw(10.0, ctx, 0, 0);
        
        return true;
    }
   
}

}
