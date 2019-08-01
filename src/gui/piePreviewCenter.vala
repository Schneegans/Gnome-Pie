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

using GLib.Math;

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
///
/////////////////////////////////////////////////////////////////////////

public class PiePreviewCenter : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// THe Images displayed. When the displayed text changes the
    /// currently displayed text becomes the old_text. So it's possible
    /// to create a smooth transitions.
    /////////////////////////////////////////////////////////////////////

    private RenderedText text = null;
    private RenderedText old_text = null;

    /////////////////////////////////////////////////////////////////////
    /// Stores the currently displayed text in order to avoid frequent
    /// and useless updates.
    /////////////////////////////////////////////////////////////////////

    private string current_text = null;

    /////////////////////////////////////////////////////////////////////
    /// An AnimatedValue for smooth transitions.
    /////////////////////////////////////////////////////////////////////

    private AnimatedValue blend;

    /////////////////////////////////////////////////////////////////////
    /// The parent renderer.
    /////////////////////////////////////////////////////////////////////

    private unowned PiePreviewRenderer parent;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, sets everything up.
    /////////////////////////////////////////////////////////////////////

    public PiePreviewCenter(PiePreviewRenderer parent) {
        this.parent = parent;
        this.blend = new AnimatedValue.linear(0, 0, 0);

        this.text = new RenderedText("", 1, 1, "", new Color(), 1.0);
        this.old_text = text;
    }

    /////////////////////////////////////////////////////////////////////
    /// Updates the currently displayed text. It will be smoothly
    /// blended and may contain pango markup.
    /////////////////////////////////////////////////////////////////////

    public void set_text(string text) {
        if (text != this.current_text) {

            var style = parent.parent.get_style_context();
            Pango.FontDescription font;
            style.get(Gtk.StateFlags.NORMAL, "font", out font);

            this.old_text = this.text;
            this.text = new RenderedText.with_markup(
                            text, 180, 180, font.get_family()+" 10",
                            new Color.from_gdk(style.get_color(Gtk.StateFlags.NORMAL)), 1.0);
            this.current_text = text;

            this.blend.reset_target(0.0, 0.0);
            this.blend.reset_target(1.0, 0.1);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Draws the center to the given context.
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
