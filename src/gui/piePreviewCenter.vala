/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2016 by Simon Schneegans
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
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

            this.old_text = this.text;
            this.text = new RenderedText.with_markup(
                            text, 180, 180, style.get_font(Gtk.StateFlags.NORMAL).get_family()+" 10",
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
