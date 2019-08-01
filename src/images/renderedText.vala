/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2019 Simon Schneegans
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
///  A class representing string, rendered on an Image.
/////////////////////////////////////////////////////////////////////////

public class RenderedText : Image {

    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates a new image representation of a string.
    /////////////////////////////////////////////////////////////////////

    public RenderedText(string text, int width, int height, string font,
                        Color color, double scale) {

        this.render_text(text, width, height, font, color, scale);
    }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates a new image representation of a string. This
    /// string may contain markup information.
    /////////////////////////////////////////////////////////////////////

    public RenderedText.with_markup(string text, int width, int height, string font,
                        Color color, double scale) {

        this.render_markup(text, width, height, font, color, scale);
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a new transparent image, with text written onto.
    /////////////////////////////////////////////////////////////////////

    public void render_text(string text, int width, int height, string font,
                            Color color, double scale) {

        this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);

        if (text != "") {

            var ctx = this.context();

            // set the color
            ctx.set_source_rgb(color.r, color.g, color.g);

            var layout = Pango.cairo_create_layout(ctx);
            layout.set_width(Pango.units_from_double(width));

            var font_description = Pango.FontDescription.from_string(font);
            font_description.set_size((int)(font_description.get_size() * scale));

            layout.set_font_description(font_description);
            layout.set_text(text, -1);

            // add newlines at the end of each line, in order to allow ellipsizing
            string broken_string = "";

            for (int i=0; i<layout.get_line_count(); ++i) {

                string next_line = "";
                if (i == layout.get_line_count() -1)
                    next_line = text.substring(layout.get_line(i).start_index, -1);
                else
                    next_line = text.substring(layout.get_line(i).start_index, layout.get_line(i).length);

                if (broken_string == "") {
                    broken_string = next_line;
                } else if (next_line != "") {
                    // test whether the addition of a line would cause the height to become too large
                    string broken_string_tmp = broken_string + "\n" + next_line;

                    var layout_tmp = Pango.cairo_create_layout(ctx);
                    layout_tmp.set_width(Pango.units_from_double(width));

                    layout_tmp.set_font_description(font_description);

                    layout_tmp.set_text(broken_string_tmp, -1);
                    Pango.Rectangle extents;
                    layout_tmp.get_pixel_extents(null, out extents);

                    if (extents.height > height) broken_string = broken_string + next_line;
                    else                         broken_string = broken_string_tmp;
                }
            }

            layout.set_text(broken_string, -1);

            layout.set_ellipsize(Pango.EllipsizeMode.END);
            layout.set_alignment(Pango.Alignment.CENTER);

            Pango.Rectangle extents;
            layout.get_pixel_extents(null, out extents);
            ctx.move_to(0, (int)(0.5*(height - extents.height)));

            Pango.cairo_update_layout(ctx, layout);
            Pango.cairo_show_layout(ctx, layout);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a new transparent image, with text written onto.
    /////////////////////////////////////////////////////////////////////

    public void render_markup(string text, int width, int height, string font,
                            Color color, double scale) {

        this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);

        var ctx = this.context();

        // set the color
        ctx.set_source_rgb(color.r, color.g, color.g);

        var layout = Pango.cairo_create_layout(ctx);
        layout.set_width(Pango.units_from_double(width));

        var font_description = Pango.FontDescription.from_string(font);
        font_description.set_size((int)(font_description.get_size() * scale));

        layout.set_font_description(font_description);
        layout.set_markup(text, -1);

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
