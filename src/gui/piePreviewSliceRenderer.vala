/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2017 by Simon Schneegans
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
/// Displays the preview of a Slice.
/////////////////////////////////////////////////////////////////////////

public class PiePreviewSliceRenderer : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Called when the user clicked on this Slice.
    /////////////////////////////////////////////////////////////////////

    public signal void on_clicked(int position);

    /////////////////////////////////////////////////////////////////////
    /// Called when the user clicked on the delete sign.
    /////////////////////////////////////////////////////////////////////

    public signal void on_remove(int position);

    /////////////////////////////////////////////////////////////////////
    /// The image used to display this oject.
    /////////////////////////////////////////////////////////////////////

    public Icon icon { get; private set; }
    public ActionGroup action_group { get; private set; }
    public string name { get; private set; default=""; }
    public bool delete_hovered { get; private set; default=false; }

    /////////////////////////////////////////////////////////////////////
    /// The parent renderer.
    /////////////////////////////////////////////////////////////////////

    private unowned PiePreviewRenderer parent;

    /////////////////////////////////////////////////////////////////////
    /// The delete sign, displayed in the upper right corner of each
    /// Slice.
    /////////////////////////////////////////////////////////////////////

    private PiePreviewDeleteSign delete_sign = null;

    /////////////////////////////////////////////////////////////////////
    /// Some AnimatedValues for smooth transitions.
    /////////////////////////////////////////////////////////////////////

    private AnimatedValue angle;
    private AnimatedValue size;
    private AnimatedValue activity;
    private AnimatedValue clicked;

    /////////////////////////////////////////////////////////////////////
    /// Some constants determining the look and behaviour of this Slice.
    /////////////////////////////////////////////////////////////////////

    private const double pie_radius = 126;
    private const double radius = 24;
    private const double delete_x = 13;
    private const double delete_y = -13;
    private const double click_cancel_treshold = 5;

    /////////////////////////////////////////////////////////////////////
    /// Storing the position where a mouse click was executed. Useful for
    /// canceling the click when the mouse moves some pixels.
    /////////////////////////////////////////////////////////////////////

    private double clicked_x = 0.0;
    private double clicked_y = 0.0;

    /////////////////////////////////////////////////////////////////////
    /// The index of this slice in a pie. Clockwise assigned, starting
    /// from the right-most slice.
    /////////////////////////////////////////////////////////////////////

    private int position;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, sets everything up.
    /////////////////////////////////////////////////////////////////////

    public PiePreviewSliceRenderer(PiePreviewRenderer parent) {
        this.delete_sign = new PiePreviewDeleteSign();
        this.delete_sign.load();
        this.delete_sign.on_clicked.connect(() => {
            this.on_remove(this.position);
        });

        this.parent = parent;
        this.angle = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 0.5);
        this.size = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 1.0);
        this.activity = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 0.0);
        this.clicked = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 1, 1, 0, 1.0);
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads an Action. All members are initialized accordingly.
    /////////////////////////////////////////////////////////////////////

    public void load(ActionGroup group) {
        this.action_group = group;

        // if it's a custom ActionGroup
        if (group.get_type().depth() == 2 && group.actions.size > 0) {
            this.icon = new Icon(group.actions[0].icon, (int)(PiePreviewSliceRenderer.radius*2));
            this.name = group.actions[0].name;
        } else {
            this.icon = new Icon(GroupRegistry.descriptions[group.get_type().name()].icon, (int)(PiePreviewSliceRenderer.radius*2));
            this.name = GroupRegistry.descriptions[group.get_type().name()].name;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Updates the position where this object should be displayed.
    /////////////////////////////////////////////////////////////////////

    public void set_position(int position, bool smoothly = true) {
        double direction = 2.0 * PI * position/parent.slice_count();

        if (direction != this.angle.end) {
            this.position = position;
            this.angle.reset_target(direction, smoothly ? 0.5 : 0.0);

            if (!smoothly)
                this.angle.update(1.0);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Updates the size of this object. All transitions will be smooth.
    /////////////////////////////////////////////////////////////////////

    public void set_size(double size) {
        this.size.reset_target(size, 0.5);
        this.delete_sign.set_size(size);
    }

    /////////////////////////////////////////////////////////////////////
    /// Notifies that all quick actions should be disabled.
    /////////////////////////////////////////////////////////////////////

    public void disable_quickactions() {
        this.action_group.disable_quickactions();
    }

    /////////////////////////////////////////////////////////////////////
    /// Draws the slice to the given context.
    /////////////////////////////////////////////////////////////////////

    public void draw(double frame_time, Cairo.Context ctx) {
        this.size.update(frame_time);
        this.angle.update(frame_time);
        this.activity.update(frame_time);
        this.clicked.update(frame_time);

        ctx.save();

            // transform the context
            ctx.translate(cos(this.angle.val)*PiePreviewSliceRenderer.pie_radius, sin(this.angle.val)*PiePreviewSliceRenderer.pie_radius);

            double scale = this.size.val*this.clicked.val
                         + this.activity.val*0.1 - 0.1;
            ctx.save();

                ctx.scale(scale, scale);

                // paint the image
                icon.paint_on(ctx);

            ctx.restore();

            ctx.translate(PiePreviewSliceRenderer.delete_x*this.size.val, PiePreviewSliceRenderer.delete_y*this.size.val);
            this.delete_sign.draw(frame_time, ctx);

        ctx.restore();
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the mouse moves to another position.
    /////////////////////////////////////////////////////////////////////

    public bool on_mouse_move(double angle, double x, double y) {
        double direction = 2.0 * PI * position/parent.slice_count();
        double diff = fabs(angle-direction);

        if (diff > PI)
            diff = 2 * PI - diff;

        bool active = diff < 0.5*PI/parent.slice_count();

        if (active) {
            this.activity.reset_target(1.0, 0.3);
            this.delete_sign.show();
        } else {
            this.activity.reset_target(0.0, 0.3);
            this.delete_sign.hide();
        }

        if (this.clicked.end == 0.9) {
            double dist = GLib.Math.pow(x-this.clicked_x, 2) + GLib.Math.pow(y-this.clicked_y, 2);
            if (dist > PiePreviewSliceRenderer.click_cancel_treshold*PiePreviewSliceRenderer.click_cancel_treshold)
                this.clicked.reset_target(1.0, 0.1);
        }

        double own_x = cos(this.angle.val)*PiePreviewSliceRenderer.pie_radius;
        double own_y = sin(this.angle.val)*PiePreviewSliceRenderer.pie_radius;
        this.delete_hovered = this.delete_sign.on_mouse_move(x - own_x - PiePreviewSliceRenderer.delete_x*this.size.val,
                                                             y - own_y - PiePreviewSliceRenderer.delete_y*this.size.val);

        return active;
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the mouse leaves the area of this widget.
    /////////////////////////////////////////////////////////////////////

    public void on_mouse_leave() {
        this.activity.reset_target(0.0, 0.3);
        this.delete_sign.hide();
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when a button of the mouse is pressed.
    /////////////////////////////////////////////////////////////////////

    public void on_button_press(double x, double y) {
        bool delete_pressed = false;
        if (this.activity.end == 1.0) {
            double own_x = cos(this.angle.val)*PiePreviewSliceRenderer.pie_radius;
            double own_y = sin(this.angle.val)*PiePreviewSliceRenderer.pie_radius;
            delete_pressed = this.delete_sign.on_button_press(x - own_x - PiePreviewSliceRenderer.delete_x*this.size.val,
                                                              y - own_y - PiePreviewSliceRenderer.delete_y*this.size.val);
        }

        if (!delete_pressed && this.activity.end == 1.0) {
            this.clicked.reset_target(0.9, 0.1);
            this.clicked_x = x;
            this.clicked_y = y;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when a button of the mouse is released.
    /////////////////////////////////////////////////////////////////////

    public void on_button_release(double x, double y) {
        bool deleted = false;
        if (this.activity.end == 1.0)
            deleted = this.delete_sign.on_button_release(x, y);

        if (!deleted && this.clicked.end == 0.9) {
            this.clicked.reset_target(1.0, 0.1);
            this.on_clicked(this.position);
        }
    }
}

}
