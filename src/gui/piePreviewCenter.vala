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

public class PiePreviewCenter : GLib.Object {
    
    private RenderedText text = null;
    private RenderedText old_text = null;
    
    private string current_text = null;
    private AnimatedValue blend; 
    
    private unowned PiePreviewRenderer parent;  
    
    public PiePreviewCenter(PiePreviewRenderer parent) {
        this.parent = parent;
        this.blend = new AnimatedValue.linear(0, 0, 0);
        
        this.text = new RenderedText("", 1, 1, "");
        this.old_text = text;
    }
    
    public void set_text(string text) {
        if (text != this.current_text) {
            
            var style = new Gtk.Style();
            
            this.old_text = this.text;
            this.text = new RenderedText.with_markup(text, 180, 180, style.font_desc.get_family()+" 8", 
                                                     new Color.from_gdk(style.fg[0]), 1.0);
            this.current_text = text;
            
            this.blend.reset_target(0.0, 0.0);
            this.blend.reset_target(1.0, 0.05);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////

    public void draw(double frame_time, Cairo.Context ctx) {

        this.blend.update(frame_time);
        
        ctx.save();
        
        if (this.parent.slice_count() == 0) 
            ctx.translate(0, 40);
        
        this.old_text.paint_on(ctx, 1-this.blend.val);
        this.text.paint_on(ctx, this.blend.val);
            
        ctx.restore();
    }
}

}
