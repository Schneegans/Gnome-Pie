/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2015 by Simon Schneegans
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
/// A liitle plus-sign displayed on the preview widget to indicate where
/// the user may add a new Slice.
/////////////////////////////////////////////////////////////////////////

public class PiePreviewAddSign : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Gets emitted, when the users clicks on this object.
    /////////////////////////////////////////////////////////////////////

    public signal void on_clicked(int position);

    /////////////////////////////////////////////////////////////////////
    /// The image used to display this oject.
    /////////////////////////////////////////////////////////////////////

    public Image icon { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// True, when the add sign is currently visible.
    /////////////////////////////////////////////////////////////////////

    public bool visible { get; private set; default=false; }

    /////////////////////////////////////////////////////////////////////
    /// The position of the sign in its parent Pie. May be 2.5 for
    /// example.
    /////////////////////////////////////////////////////////////////////

    private double position = 0;

    /////////////////////////////////////////////////////////////////////
    /// The parent renderer.
    /////////////////////////////////////////////////////////////////////

    private unowned PiePreviewRenderer parent;

    /////////////////////////////////////////////////////////////////////
    /// Some values used for displaying this sign.
    /////////////////////////////////////////////////////////////////////

    private double time = 0;
    private double max_size = 0;
    private double angle = 0;
    private AnimatedValue size;
    private AnimatedValue alpha;
    private AnimatedValue activity;
    private AnimatedValue clicked;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, sets everything up.
    /////////////////////////////////////////////////////////////////////

    public PiePreviewAddSign(PiePreviewRenderer parent) {
        this.parent = parent;

        this.size = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 2.0);
        this.alpha = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 0.0);
        this.activity = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, -3, -3, 0, 0.0);
        this.clicked = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 1, 1, 0, 0.0);
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads the desired icon for this sign.
    /////////////////////////////////////////////////////////////////////

    public void load() {
        this.icon = new Icon("list-add", 36);
    }

    /////////////////////////////////////////////////////////////////////
    /// Updates the position where this object should be displayed.
    /////////////////////////////////////////////////////////////////////

    public void set_position(int position) {
        double new_position = position;

        if (!this.parent.drag_n_drop_mode)
            new_position += 0.5;

        this.position = new_position;
        this.angle = 2.0 * PI * new_position/parent.slice_count();
    }

    /////////////////////////////////////////////////////////////////////
    /// Makes this object visible.
    /////////////////////////////////////////////////////////////////////

    public void show() {
        this.visible = true;
        this.size.reset_target(this.max_size, 0.3);
        this.alpha.reset_target(1.0, 0.3);
    }

    /////////////////////////////////////////////////////////////////////
    /// Makes this object invisible.
    /////////////////////////////////////////////////////////////////////

    public void hide() {
        this.visible = false;
        this.size.reset_target(0.0, 0.3);
        this.alpha.reset_target(0.0, 0.3);
    }

    /////////////////////////////////////////////////////////////////////
    /// Updates the size of this object. All transitions will be smooth.
    /////////////////////////////////////////////////////////////////////

    public void set_size(double size) {
        this.max_size = size;
        this.size.reset_target(size, 0.5);
    }

    /////////////////////////////////////////////////////////////////////
    /// Draws the sign to the given context.
    /////////////////////////////////////////////////////////////////////

    public void draw(double frame_time, Cairo.Context ctx) {

        this.time += frame_time;

        this.size.update(frame_time);
        this.alpha.update(frame_time);
        this.activity.update(frame_time);
        this.clicked.update(frame_time);

        if (this.parent.slice_count() == 0) {
            ctx.save();

            double scale = this.clicked.val
                         + GLib.Math.sin(this.time*10)*0.02*this.alpha.val
                         + this.alpha.val*0.08 - 0.1;
            ctx.scale(scale, scale);

            // paint the image
            icon.paint_on(ctx);

            ctx.restore();

        } else if (this.alpha.val*this.activity.val > 0) {
            ctx.save();

            // distance from the center
            double radius = 120;

            // transform the context
            ctx.translate(cos(this.angle)*radius, sin(this.angle)*radius);
            double scale = this.size.val*this.clicked.val
                         + this.activity.val*0.07
                         + GLib.Math.sin(this.time*10)*0.03*this.activity.val
                         - 0.1;
            ctx.scale(scale, scale);

            // paint the image
            icon.paint_on(ctx, this.alpha.val*this.activity.val);

            ctx.restore();
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the mouse moves to another position.
    /////////////////////////////////////////////////////////////////////

    public void on_mouse_move(double angle) {
        if (parent.slice_count() > 0) {
            double direction = 2.0 * PI * position/parent.slice_count();
            double diff = fabs(angle-direction);

            if (diff > PI)
                diff = 2 * PI - diff;

            if (diff < 0.5*PI/parent.slice_count()) this.activity.reset_target(1.0, 1.0);
            else                                    this.activity.reset_target(-3.0, 1.5);
        } else {
            this.activity.reset_target(1.0, 1.0);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when a button of the mouse is pressed.
    /////////////////////////////////////////////////////////////////////

    public void on_button_press(double x, double y) {
        if (this.activity.end == 1.0) {
            this.clicked.reset_target(0.9, 0.1);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when a button of the mouse is released.
    /////////////////////////////////////////////////////////////////////

    public void on_button_release(double x, double y) {
        if (this.clicked.end == 0.9) {
            this.on_clicked((int)this.position);
            this.clicked.reset_target(1.0, 0.1);
        }
    }
}

}
