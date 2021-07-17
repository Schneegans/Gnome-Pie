/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2021 Simon Schneegans
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// A class which loads image files. It can load image files in various
/// formats, including jpeg, png and svg.
/////////////////////////////////////////////////////////////////////////

public class Image : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// The internally used surface.
    /////////////////////////////////////////////////////////////////////

    public Cairo.ImageSurface surface { public get; protected set; default=null; }

    /////////////////////////////////////////////////////////////////////
    /// Creates an empty Image.
    /////////////////////////////////////////////////////////////////////

    public Image.empty(int width, int height, Color? color = null) {
        this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);

        if (color != null) {
            var ctx = this.context();
            ctx.set_source_rgb(color.r, color.g, color.b);
            ctx.paint();
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates an image from the the given filename.
    /////////////////////////////////////////////////////////////////////

    public Image.from_file(string filename) {
        this.load_file(filename);
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates an image from the the given filename at a given size.
    /////////////////////////////////////////////////////////////////////

    public Image.from_file_at_size(string filename, int width, int height) {
        this.load_file_at_size(filename, width, height);
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates an image from the the given Gdk.Pixbuf.
    /////////////////////////////////////////////////////////////////////

    public Image.from_pixbuf(Gdk.Pixbuf pixbuf) {
        if (pixbuf != null) this.load_pixbuf(pixbuf);
        else                this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, 1, 1);
    }

    /////////////////////////////////////////////////////////////////////
    /// Captures a part of the screen.
    /////////////////////////////////////////////////////////////////////

    public Image.capture_screen(int posx, int posy, int width, int height, bool hide_pies = true) {
        Gdk.Window root = Gdk.get_default_root_window();
        Gdk.Pixbuf pixbuf = Gdk.pixbuf_get_from_window(root, posx, posy, width, height);

        this.load_pixbuf(pixbuf);

        if (hide_pies) {
            // check for opened pies
            foreach (var window in PieManager.opened_windows) {
                if (window.background != null) {
                    int x=0, y=0, dx=0, dy=0;
                    window.get_position(out x, out y);
                    window.get_size(out dx, out dy);

                    var ctx = this.context();
                    ctx.translate((int)(x-posx + (dx+3)/2), (int)(y-posy + (dy+3)/2));
                    window.background.paint_on(ctx);
                }
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads an image from the the given filename.
    /////////////////////////////////////////////////////////////////////

    public void load_file(string filename) {
        try {
            var pixbuf = new Gdk.Pixbuf.from_file(filename);

            if (pixbuf != null) {
                this.load_pixbuf(pixbuf);
            } else {
                warning("Failed to load " + filename + "!");
                this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, 1, 1);
            }
        } catch (GLib.Error e) {
            message("Error loading image file: %s", e.message);
            this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, 1, 1);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads an image from the the given filename at a given size.
    /////////////////////////////////////////////////////////////////////

    public void load_file_at_size(string filename, int width, int height) {
        try {
            var pixbuf = new Gdk.Pixbuf.from_file_at_size(filename, width, height);

            if (pixbuf != null) {
                this.load_pixbuf(pixbuf);
            } else {
                warning("Failed to load " + filename + "!");
                this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);
            }

        } catch (GLib.Error e) {
            message("Error loading image file: %s", e.message);
            this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads an image from the the given Gdk.Pixbuf.
    /////////////////////////////////////////////////////////////////////

    public void load_pixbuf(Gdk.Pixbuf pixbuf) {
        this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, pixbuf.width, pixbuf.height);

        var ctx = this.context();
        Gdk.cairo_set_source_pixbuf(ctx, pixbuf, 1.0, 1.0);
        ctx.paint();
    }

    /////////////////////////////////////////////////////////////////////
    /// Paints the image onto the given Cairo.Context
    /////////////////////////////////////////////////////////////////////

    public void paint_on(Cairo.Context ctx, double alpha = 1.0) {
        ctx.set_source_surface(this.surface, (int)(-0.5*this.width()-1), (int)(-0.5*this.height()-1));
        if (alpha >= 1.0) ctx.paint();
        else              ctx.paint_with_alpha(alpha);
    }

    /////////////////////////////////////////////////////////////////////
    /// Converts the image to a Gdk.Pixbuf.
    /////////////////////////////////////////////////////////////////////

    public Gdk.Pixbuf to_pixbuf() {
        if (this.surface == null || this.surface.get_data() == null)
            return new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, 1, 1);

        var pixbuf = new Gdk.Pixbuf.with_unowned_data(this.surface.get_data(), Gdk.Colorspace.RGB, true, 8,
                                              width(), height(), this.surface.get_stride(), null);

        pixbuf = pixbuf.copy();

        // funny stuff here --- need to swap Red end Blue because Cairo
        // and Gdk are different...
        uint8* p = pixbuf.pixels;
        for (int i=0; i<width()*height()*4-4; i+=4) {
            var tmp = *(p + i);
            *(p + i) = *(p + i + 2);
            *(p + i + 2) = tmp;
        }

        return pixbuf;
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns a Cairo.Context for the Image.
    /////////////////////////////////////////////////////////////////////

    public Cairo.Context context() {
        return new Cairo.Context(this.surface);
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the width of the image in pixels.
    /////////////////////////////////////////////////////////////////////

    public int width() {
        if (this.surface != null)
            return this.surface.get_width();
        return 0;
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the height of the image in pixels.
    /////////////////////////////////////////////////////////////////////

    public int height() {
        if (this.surface != null)
            return this.surface.get_height();
        return 0;
    }
}

}
