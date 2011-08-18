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

// a class which loads image files.
public class Image : GLib.Object {

    // icon cache which stores loaded images
    private static Gee.HashMap<string, Cairo.ImageSurface?> file_cache {private get; private set;}
    private static Gee.HashMap<string, Cairo.ImageSurface?> themed_active_cache {private get; private set;}
    private static Gee.HashMap<string, Cairo.ImageSurface?> themed_inactive_cache {private get; private set;}
    
    private static void init() {
        if (file_cache == null) {
            file_cache = new Gee.HashMap<string, Cairo.ImageSurface?>();
            Gtk.IconTheme.get_default().changed.connect(() => {
                file_cache.clear();
            });
        }
        
        if (themed_active_cache == null) {
            themed_active_cache = new Gee.HashMap<string, Cairo.ImageSurface?>();
            Config.global.notify["theme"].connect(() => {
                themed_active_cache.clear();
            });
        }
        
        if (themed_inactive_cache == null) {
            themed_inactive_cache = new Gee.HashMap<string, Cairo.ImageSurface?>();
            Config.global.notify["theme"].connect(() => {
                themed_inactive_cache.clear();
            });
        }
    }
    
    //public members
    public Cairo.ImageSurface surface {get; private set;}
    
    //c'tors
    public Image() {
        this.init();
        this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, 0, 0);
    }
    
    public Image.empty(int size, Color? color = null) {
        this.init();
        surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
        
        if (color != null) {
            var ctx = get_context();
            ctx.set_source_rgb(color.r, color.g, color.b);
            ctx.paint();
        }
    }
    
    // Loads an icon from the the given filename.
    public Image.from_file(string filename, int size) {
        this.init();
        this.surface = this.file_cache.get(filename);
        
        if(surface == null || surface.get_width() < size) {
            this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
            this.load_file(filename, size);
            this.file_cache.set(filename, surface);
            return;
            
        } else if (this.size() > size){
             var scaled = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
             var ctx = new Cairo.Context(scaled);
             ctx.scale((float)size/(float)this.size(), (float)size/(float)this.size());
             ctx.set_source_surface(surface, 1.0, 1.0);
             ctx.paint();
             surface = scaled;
        }
    }
    
    public Image.from_string(string text, int size, int font_size) {
        this.init();
        
        this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
        var ctx = this.get_context();
        
        string ellipsed_text = text;
        
        ctx.set_font_size(font_size);
        Cairo.TextExtents extents;
        ctx.text_extents(ellipsed_text, out extents);
        
        if (extents.width > size && ellipsed_text.length > 3) {
            ellipsed_text = ellipsed_text.substring(0, ellipsed_text.length-1) + "...";
            
            while (extents.width > size && ellipsed_text.length > 3) {
                ellipsed_text = ellipsed_text.substring(0, ellipsed_text.length-4) + "...";
                ctx.text_extents(ellipsed_text, out extents);
            }
        }
        
        ctx.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
        ctx.move_to((int)(0.5*size - 0.5*extents.width), 
                    (int)(0.5*size+0.3*Config.global.theme.font_size)); 
        Color color = Config.global.theme.caption_color;
        ctx.set_source_rgb(color.r, color.g, color.g);
        ctx.show_text(ellipsed_text);
    }
    
    // Loads an icon from the current icon theme of the user.
    public Image.themed_icon(string icon_name, bool active) {
        this.init();
        
        if (active) {
            this.surface = this.themed_active_cache.get(icon_name);
            if (this.surface == null) {
                this.paint_themed(icon_name, active);
                this.themed_active_cache.set(icon_name, this.surface);
            }
        } else {
            this.surface = this.themed_inactive_cache.get(icon_name);
            if (this.surface == null) {
                this.paint_themed(icon_name, active);
                this.themed_inactive_cache.set(icon_name, this.surface);
            } 
        }
    }
    
    public int size() {
        if (surface == null) return 0;
        else return surface.get_width();
    }
    
    public Cairo.Context get_context() {
        return new Cairo.Context(surface);
    }
    
    // Paints the image onto the given Cairo.Context
    public void paint_on(Cairo.Context ctx, double alpha = 1.0) {
        ctx.set_source_surface(surface, -0.5*this.size()-1, -0.5*this.size()-1);
        if (alpha >= 1.0) ctx.paint();
        else              ctx.paint_with_alpha(alpha);
    }
    
    private void load_file(string filename, int size) {
    
        try {
            var pixbuf = new Gdk.Pixbuf.from_file_at_size(filename, size, size);
            
            if (pixbuf == null) {
                warning("Failed to load " + filename + "!");
                return;
            }
                
            var ctx = new Cairo.Context(this.surface);
            Gdk.cairo_set_source_pixbuf(ctx, pixbuf, 1.0, 1.0);
            ctx.paint();
            
        } catch (GLib.Error e) {
            message("Error loading image file: %s", e.message);
        }
    }
    
    private void paint_themed(string icon_name, bool active) {
        // get layers for the desired slice type
        Gee.ArrayList<SliceLayer?> layers;
        if (active) layers = Config.global.theme.active_slice_layers;
		else        layers = Config.global.theme.inactive_slice_layers;
        
        // get max size
        int size = 0;
        foreach (var layer in layers) {
            if (layer.image.size() > size) size = layer.image.size();
        }
        
        this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
        
        // get size of icon layer
        int icon_size = size;
        foreach (var layer in layers) {
            if (layer.is_icon) icon_size = layer.image.size();
        }

        string icon_file = this.get_icon_file(icon_name, size);
    
        var icon =  new Image.from_file(icon_file, icon_size);
        var color = new Color.from_icon(icon);
        var ctx  =  get_context();
        
        ctx.translate(size/2, size/2);
        ctx.set_operator(Cairo.Operator.OVER);
        
        // now render all layers on top of each other
        foreach (var layer in layers) {
        
            if (layer.colorize) ctx.push_group();
                    
            if (layer.is_icon) {
            
                ctx.push_group();
                
                layer.image.paint_on(ctx);
                
                ctx.set_operator(Cairo.Operator.IN);
                
                if (layer.image.size() != icon_size) {
                    var icon_theme = Gtk.IconTheme.get_default();
                    icon_file = icon_theme.lookup_icon(icon_name, layer.image.size(), 0).get_filename();
                    icon = new Image.from_file(icon_file, layer.image.size());
                }
                
                icon.paint_on(ctx);

                ctx.pop_group_to_source();
                ctx.paint();
                ctx.set_operator(Cairo.Operator.OVER);
                
            } else layer.image.paint_on(ctx);

            
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
    
    // returns the filename for a given system icon
    private string get_icon_file(string icon_name, int size) {
        string result = "";
    
        if (!icon_name.contains("/")) {
            var icon_theme = Gtk.IconTheme.get_default();
            var file = icon_theme.lookup_icon(icon_name, size, 0);
            if (file != null) result = file.get_filename();
        } else {
            result = icon_name;
        }
        
        if (result == "") {
            warning("Icon \"" + icon_name + "\" not found! Using default icon...");
            icon_name = "application-default-icon";
            var icon_theme = Gtk.IconTheme.get_default();
            var file = icon_theme.lookup_icon(icon_name, size, 0);
            if (file != null) result = file.get_filename();
        }
        
        if (result == "")
            warning("Icon \"" + icon_name + "\" not found! Will be ugly...");
            
        return result;
    }
}

}
