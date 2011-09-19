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
///  A class representing string, rendered on an Image.
/////////////////////////////////////////////////////////////////////////

public class RenderedText : Image {

    /////////////////////////////////////////////////////////////////////
    /// A cache which stores images. It is cleared when the theme of
    /// Gnome-Pie changes.
    /// The key is in form <string>@<width>x<height>:<font>.
    /////////////////////////////////////////////////////////////////////

    private static Gee.HashMap<string, Cairo.ImageSurface?> cache { private get; private set; }
    
    /////////////////////////////////////////////////////////////////////
    /// Initializes the cache.
    /////////////////////////////////////////////////////////////////////
    
    public static void init() {
        clear_cache();
        
        Config.global.notify["theme"].connect(() => {
            clear_cache();
        });
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Clears the cache.
    /////////////////////////////////////////////////////////////////////
    
    static void clear_cache() {
        cache = new Gee.HashMap<string, Cairo.ImageSurface?>();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates a new image representation of a string.
    /////////////////////////////////////////////////////////////////////
    
    public RenderedText(string text, int width, int height, string font) {
        var cached = this.cache.get("%s@%ux%u:%s".printf(text, width, height, font));
        
        if (cached == null) {
            this.render_text(text, width, height, font);
            this.cache.set("%s@%ux%u:%s".printf(text, width, height, font), this.surface);
        } else {
            this.surface = cached;
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Creates a new transparent image, with text written onto.
    /////////////////////////////////////////////////////////////////////
    
    public void render_text(string text, int width, int height, string font) {
        this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);

        var ctx = this.context();
        Color color = Config.global.theme.caption_color;
        ctx.set_source_rgb(color.r, color.g, color.g);
        
        var layout = Pango.cairo_create_layout(ctx);        
        layout.set_width(Pango.units_from_double(width));
        
        var font_description = Pango.FontDescription.from_string(font);
        font_description.set_size((int)(font_description.get_size() * Config.global.global_scale));
        
        layout.set_font_description(font_description);
        layout.set_text(text, -1);
        
        // add newlines at the end of each line, in order to allow ellipsizing
        string broken_string = "";
        foreach (var line in layout.get_lines()) {
            broken_string = broken_string.concat(text.substring(line.start_index, line.length), "\n");
        }
        layout.set_text(broken_string, broken_string.length-1);
        
        layout.set_ellipsize(Pango.EllipsizeMode.END);
        layout.set_alignment(Pango.Alignment.CENTER);
        
        Pango.Rectangle extents;
        layout.get_pixel_extents(null, out extents);
        ctx.move_to(0, (int)(0.5*(height - extents.height)));
        
        Pango.cairo_update_layout(ctx, layout);
        Pango.cairo_show_layout(ctx, layout);
    }
}

}
