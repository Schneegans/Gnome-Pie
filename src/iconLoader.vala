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
            string file_type = parts[parts.length-1].up();
            if (file_type == "SVG")
                return load_svg(filename, size);
            else if (file_type == "PNG")
                return load_png(filename, size);

            warning("Unrecognized image type: " + filename + "!");
            return null;
        }
        
        private static Cairo.ImageSurface? load_svg(string filename, int size) {
        
            try {
                var pixbuf = Rsvg.pixbuf_from_file_at_size(filename, size, size);
                if (pixbuf == null) {
                    warning("Failed to load " + filename + "!");
                    return null;
                }
                    
                var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, pixbuf.get_width(), pixbuf.get_height());
                var ctx = new Cairo.Context(surface);
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
                 ctx.set_source_surface(surface, 0,0);
                 ctx.paint();
                 return scaled;
            } else {
                return surface;
            }
            
        }
    
    }

}
