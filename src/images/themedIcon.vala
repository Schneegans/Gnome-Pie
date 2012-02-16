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
/// A class representing a square-shaped icon, themed according to the
/// current theme of Gnome-Pie.
/////////////////////////////////////////////////////////////////////////

public class ThemedIcon : Image {
    
    /////////////////////////////////////////////////////////////////////
    /// Paint a slice icon according to the current theme.
    /////////////////////////////////////////////////////////////////////
    
    public ThemedIcon(string caption, string icon_name, bool active) {
    
        // get layers for the desired slice type
        var layers = active ? Config.global.theme.active_slice_layers : Config.global.theme.inactive_slice_layers;
        
        // get max size
        int size = 1;
        foreach (var layer in layers) {
            if (layer.image != null && layer.image.width() > size) 
                size = layer.image.width();
        }
        
        this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
        
        // get size of icon layer
        int icon_size = size;
        foreach (var layer in layers) {
            if (layer.image != null && layer.layer_type == SliceLayer.Type.ICON)
                icon_size = layer.image.width();
        }
    
        Image icon;
        if (icon_name.contains("/"))
            icon = new Image.from_file_at_size(icon_name, icon_size, icon_size);
        else
            icon = new Icon(icon_name, icon_size);
        
        var color = new Color.from_icon(icon);
        var ctx = this.context();
        
        ctx.translate(size/2, size/2);
        ctx.set_operator(Cairo.Operator.OVER);
        
        // now render all layers on top of each other
        foreach (var layer in layers) {
        
            if (layer.visibility == SliceLayer.Visibility.ANY || 
                (Config.global.show_captions == (layer.visibility == SliceLayer.Visibility.WITH_CAPTION))) {
            
                if (layer.colorize) {
                    ctx.push_group();
                }
                        
                if (layer.layer_type == SliceLayer.Type.ICON) {
                    ctx.push_group();
                    
                    layer.image.paint_on(ctx);
                    
                    ctx.set_operator(Cairo.Operator.IN);
                    
                    if (layer.image.width() != icon_size) {
                        if (icon_name.contains("/"))
                            icon = new Image.from_file_at_size(icon_name, layer.image.width(), layer.image.width());
                        else
                            icon = new Icon(icon_name,layer.image.width());
                    }
                    
                    icon.paint_on(ctx);

                    ctx.pop_group_to_source();
                    ctx.paint();
                    ctx.set_operator(Cairo.Operator.OVER);
                    
                } else if (layer.layer_type == SliceLayer.Type.CAPTION) {
                    Image text = new RenderedText(caption, layer.width, layer.height, layer.font, layer.color, Config.global.global_scale);
                    ctx.translate(0, layer.position);
                    text.paint_on(ctx);
                    ctx.translate(0, -layer.position);
                } else if (layer.layer_type == SliceLayer.Type.FILE) {
                    layer.image.paint_on(ctx);
                }
                
                // colorize the whole layer if neccasary
                if (layer.colorize) {
                    ctx.set_operator(Cairo.Operator.ATOP);
                    ctx.set_source_rgb(color.r, color.g, color.b);
                    ctx.paint();
                    
                    ctx.set_operator(Cairo.Operator.OVER);
                    ctx.pop_group_to_source();
                    ctx.paint();
                }
            }
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Returns the size of the icon in pixels. Greetings to Liskov.
    /////////////////////////////////////////////////////////////////////
    
    public int size() {
        return base.width();
    }
}

}
