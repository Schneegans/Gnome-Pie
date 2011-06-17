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

    public class IconLoader : GLib.Object {
    
        public static Cairo.ImageSurface? load(string filename, int size) {
            var parts = filename.split(".");
            
            switch (parts[parts.length-1].up()) {
                case ("SVG"):
                    return load_svg(filename, size);
                case ("PNG"):
                    return load_png(filename, size);
                default:
                    warning("Unrecognized image type: \"" + filename + "\""!");
                    return null;
            }
        }
        
        public static Cairo.ImageSurface load_themed(string filename, bool active) {
            int size =   (int)(2*Settings.theme.slice_radius*Settings.theme.max_zoom);
            var icon =   IconLoader.load(filename, size);
            var color =  new Color.from_icon(icon);
            var result = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
            var ctx  =   new Cairo.Context(result);
            
            ctx.translate(size/2, size/2);
            ctx.set_operator(Cairo.Operator.OVER);
	        
	        Gee.ArrayList<SliceLayer?> layers;
		    if (active) layers = Settings.theme.active_slice_layers;
    		else        layers = Settings.theme.inactive_slice_layers;
		    
		    foreach (var layer in layers) {
		    
		        if (layer.colorize)
		                ctx.push_group();
		                
		        if (layer.is_icon) {
		        
		            if (layer.image != null) {
		                ctx.push_group();
		                ctx.set_source_surface(layer.image, -0.5*layer.image.get_width()-1, -0.5*layer.image.get_height()-1);
		                ctx.paint();
		                ctx.set_operator(Cairo.Operator.IN);
		            }
		            
		            if (layer.image.get_width() != size)
		                icon = IconLoader.load(filename, layer.image.get_width());
		            
		            ctx.set_source_surface(icon, -0.5*icon.get_width()-1, -0.5*icon.get_height()-1);
		            ctx.paint();

		            if (layer.image != null) {
		                ctx.pop_group_to_source();
		                ctx.paint();
		                ctx.set_operator(Cairo.Operator.OVER);
		            }
		            
		        } else {
		            ctx.set_source_surface(layer.image, -0.5*layer.image.get_width()-1, -0.5*layer.image.get_height()-1);
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
            return result;
        }
        
        private static Cairo.ImageSurface? load_svg(string filename, int size) {
        
            try {
            
                var pixbuf = Rsvg.pixbuf_from_file_at_size(filename, size, size);
                
                if (pixbuf == null) {
                    warning("Failed to load " + filename + "!");
                    return null;
                }
                    
                var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, pixbuf.get_width(), pixbuf.get_height());
                var ctx =     new Cairo.Context(surface);
                Gdk.cairo_set_source_pixbuf(ctx, pixbuf, 1.0, 1.0);
                ctx.paint();
                return surface;
                
            } catch (GLib.Error e) {
                message("Error loading SVG: %s", e.message);
            }

            return null;
        }
        
        private static Cairo.ImageSurface? load_png(string filename, int size) {
        
            var surface = new Cairo.ImageSurface.from_png(filename);
            
            if (surface == null) {
                warning("Failed to load " + filename + "!");
                return null;
            }
            
            if (surface.get_width() != size) {
                 var scaled = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
                 var ctx = new Cairo.Context(scaled);
                 ctx.scale((float)size/(float)surface.get_width(), (float)size/(float)surface.get_height());
                 ctx.set_source_surface(surface, 1.0, 1.0);
                 ctx.paint();
                 return scaled;
                 
            } else return surface;
        }
    }

}
