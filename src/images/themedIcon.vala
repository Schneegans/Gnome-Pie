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
    /// A cache which stores loaded icon. The key is the icon name. When
    /// the users icon theme or the theme of Gnome-Pie changes, these
    /// cahces are cleared.
    /////////////////////////////////////////////////////////////////////

    private static Gee.HashMap<string, Cairo.ImageSurface?> active_cache { private get; private set; }
    private static Gee.HashMap<string, Cairo.ImageSurface?> inactive_cache { private get; private set; }
    
    /////////////////////////////////////////////////////////////////////
    /// Initializes the caches.
    /////////////////////////////////////////////////////////////////////
    
    public static void init() {
        clear_cache();
        
        Config.global.notify["theme"].connect(() => {
            clear_cache();
        });
        
        Gtk.IconTheme.get_default().changed.connect(() => {
            clear_cache();
        });
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Clears the cache.
    /////////////////////////////////////////////////////////////////////
    
    public static void clear_cache() {
        active_cache = new Gee.HashMap<string, Cairo.ImageSurface?>();
        inactive_cache = new Gee.HashMap<string, Cairo.ImageSurface?>();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Paint a slice icon according to the current theme.
    /////////////////////////////////////////////////////////////////////
    
    public ThemedIcon(string icon_name, bool active) {
        // check cache
        var current_cache = active ? active_cache : inactive_cache;
        var cached = current_cache.get(icon_name);
        
        if (cached != null) {
            this.surface = cached;
            return;
        }
    
        // get layers for the desired slice type
        var layers = active ? Config.global.theme.active_slice_layers : Config.global.theme.inactive_slice_layers;
        
        // get max size
        int size = 0;
        foreach (var layer in layers) {
            if (layer.image.width() > size) size = layer.image.width();
        }
        
        this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
        
        // get size of icon layer
        int icon_size = size;
        foreach (var layer in layers) {
            if (layer.is_icon) icon_size = layer.image.width();
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
        
            if (layer.colorize) {
                ctx.push_group();
            }
                    
            if (layer.is_icon) {
            
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
                
            } else {
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
        
        // store the surface in cache
        current_cache.set(icon_name, this.surface);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Returns the size of the icon in pixels. Greetings to Liskov.
    /////////////////////////////////////////////////////////////////////
    
    public int size() {
        return base.width();
    }
}

}
