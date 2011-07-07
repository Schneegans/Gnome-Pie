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

    public class Image : GLib.Object {
    
        // icon cache which stores loaded images
        private static Gee.HashMap<string, Cairo.ImageSurface?> cache {private get; private set;}
        
        private static void init() {
            if (cache == null)
                this.cache = new Gee.HashMap<string, Cairo.ImageSurface?>();
        }
        
        //public mambers
        public Cairo.ImageSurface surface {get; private set;}
        
        //c'tors
        public Image() {
            this.init();
            this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, 0, 0);
        }
        
        public Image.from_file(string filename, int size) {
            this.init();
            Cairo.ImageSurface icon = this.cache.get(filename);
            
            if(icon == null || icon.get_width() < size) {
                this.load_file(filename, size);
                this.cache.set(filename, icon);
                return;
                
            } else if (icon.get_width() > size){
                 var scaled = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
                 var ctx = new Cairo.Context(scaled);
                 ctx.scale((float)size/(float)icon.get_width(), (float)size/(float)icon.get_height());
                 ctx.set_source_surface(icon, 1.0, 1.0);
                 ctx.paint();
                 icon = scaled;
            }
            this.surface = icon;
        }
        
        public Image.themed_icon(string icon_name, int size, bool active, Theme theme) {
            this.init();
            // initialize the surface
            this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
            
            // get layers for the desired slice type
            Gee.ArrayList<SliceLayer?> layers;
	        if (active) layers = theme.active_slice_layers;
    		else        layers = theme.inactive_slice_layers;
            
            // get size of icon layer
            int icon_size = size;
            foreach (var layer in layers) {
                if (layer.is_icon) 
                    icon_size = layer.image.width();
            }
        
            string icon_file = this.get_icon_file(icon_name, size);
        
            var icon =  new Image.from_file(icon_file, icon_size);
            var color = new Color.from_icon(icon);
            var ctx  =  new Cairo.Context(this.surface);
            
            ctx.translate(size/2, size/2);
            ctx.set_operator(Cairo.Operator.OVER);
            
            // now render all layers on top of each other
	        foreach (var layer in layers) {
	        
	            if (layer.colorize)
	                    ctx.push_group();
	                    
	            if (layer.is_icon) {
	            
                    ctx.push_group();
                    ctx.set_source_surface(layer.image.surface, -0.5*layer.image.width()-1, -0.5*layer.image.height()-1);
                    ctx.paint();
                    ctx.set_operator(Cairo.Operator.IN);
	                
	                if (layer.image.width() != icon_size) {
	                    var icon_theme = Gtk.IconTheme.get_default();
	                    icon_file = icon_theme.lookup_icon(icon_name, layer.image.width(), 0).get_filename();
	                    icon = new Image.from_file(icon_file, layer.image.width());
	                }
	                
	                ctx.set_source_surface(icon.surface, -0.5*icon.width()-1, -0.5*icon.height()-1);
	                ctx.paint();

	                if (layer.image != null) {
	                    ctx.pop_group_to_source();
	                    ctx.paint();
	                    ctx.set_operator(Cairo.Operator.OVER);
	                }
	                
	            } else {
	                ctx.set_source_surface(layer.image, -0.5*layer.image.width()-1, -0.5*layer.image.height()-1);
	                ctx.paint();
	            }
	            
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
        
        public int width() {
            return surface.get_width();
        }

        public int height() {
            return surface.get_height();
        }
        
        public void load_file(string filename, int size) {
        
            try {
                var pixbuf = new Gdk.Pixbuf.from_file_at_size(filename, size, size);
                
                if (pixbuf == null) {
                    warning("Failed to load " + filename + "!");
                    return;
                }
                    
                this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, pixbuf.get_width(), pixbuf.get_height());
                var ctx = new Cairo.Context(this.surface);
                Gdk.cairo_set_source_pixbuf(ctx, pixbuf, 1.0, 1.0);
                ctx.paint();
                
            } catch (GLib.Error e) {
                message("Error loading image file: %s", e.message);
            }
        }
        
        private string get_icon_file(string icon_name, int size) {
            string icon_file = icon_name;
        
            if (!icon_name.contains("/")) {
                var icon_theme = Gtk.IconTheme.get_default();
                var file = icon_theme.lookup_icon(icon_name, icon_size, 0);
                if (file != null) icon_file = file.get_filename();
            }
            
            if (icon_file == "") {
                warning("Icon \"" + icon_name + "\" not found! Using default icon...");
                icon_name = "application-default-icon";
                var icon_theme = Gtk.IconTheme.get_default();
                var file = icon_theme.lookup_icon(icon_name, size, 0);
                if (file != null) icon_file = file.get_filename();
            }
            
            if (icon_file == "")
                warning("Icon \"" + icon_name + "\" not found! Will be ugly...");
                
            return icon_file;
        }
    }

}
