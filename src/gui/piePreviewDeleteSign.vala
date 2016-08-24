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
/// The delete sign, displayed in the upper right corner of each
/// Slice.
/////////////////////////////////////////////////////////////////////////

public class PiePreviewDeleteSign : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Called when the user clicked on this sign.
    /////////////////////////////////////////////////////////////////////

    public signal void on_clicked();

    /////////////////////////////////////////////////////////////////////
    /// The image used to display this oject.
    /////////////////////////////////////////////////////////////////////

    public Image icon { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Some constants determining the look and behaviour of this Slice.
    /////////////////////////////////////////////////////////////////////

    private static const int radius = 18;
    private static const double globale_scale = 0.8;
    private static const double click_cancel_treshold = 5;

    /////////////////////////////////////////////////////////////////////
    /// True, when the add sign is currently visible.
    /////////////////////////////////////////////////////////////////////

    private bool visible = false;

    /////////////////////////////////////////////////////////////////////
    /// Some AnimatedValues for smooth transitions.
    /////////////////////////////////////////////////////////////////////

    private AnimatedValue size;
    private AnimatedValue alpha;
    private AnimatedValue activity;
    private AnimatedValue clicked;

    /////////////////////////////////////////////////////////////////////
    /// Storing the position where a mouse click was executed. Useful for
    /// canceling the click when the mouse moves some pixels.
    /////////////////////////////////////////////////////////////////////

    private double clicked_x = 0.0;
    private double clicked_y = 0.0;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, sets everything up.
    /////////////////////////////////////////////////////////////////////

    public PiePreviewDeleteSign() {
        this.size = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 2.0);
        this.alpha = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 0, 0, 0, 0.0);
        this.activity = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, -3, -3, 0, 0.0);
        this.clicked = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 1, 1, 0, 0.0);
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads an Action. All members are initialized accordingly.
    /////////////////////////////////////////////////////////////////////

    public void load() {
        this.icon = new Icon("edit-delete", PiePreviewDeleteSign.radius*2);
    }

    /////////////////////////////////////////////////////////////////////
    /// Makes this object visible.
    /////////////////////////////////////////////////////////////////////

    public void show() {
        if (!this.visible) {
            this.visible = true;
            this.alpha.reset_target(1.0, 0.3);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Makes this object invisible.
    /////////////////////////////////////////////////////////////////////

    public void hide() {
        if (this.visible) {
            this.visible = false;
            this.alpha.reset_target(0.0, 0.3);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Updates the size of this object. All transitions will be smooth.
    /////////////////////////////////////////////////////////////////////

    public void set_size(double size) {
        this.size.reset_target(size, 0.2);
    }

    /////////////////////////////////////////////////////////////////////
    /// Draws the sign to the given context.
    /////////////////////////////////////////////////////////////////////

    public void draw(double frame_time, Cairo.Context ctx) {
        this.size.update(frame_time);
        this.alpha.update(frame_time);
        this.activity.update(frame_time);
        this.clicked.update(frame_time);

        if (this.alpha.val > 0) {
            ctx.save();

            // transform the context
            double scale = (this.size.val*this.clicked.val
                         + this.activity.val*0.2 - 0.2)*PiePreviewDeleteSign.globale_scale;
            ctx.scale(scale, scale);

            // paint the image
            icon.paint_on(ctx, this.alpha.val);

            ctx.restore();
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the mouse moves to another position.
    /////////////////////////////////////////////////////////////////////

    public bool on_mouse_move(double x, double y) {
        if (this.clicked.end == 0.9) {
            double dist = GLib.Math.pow(x-this.clicked_x, 2) + GLib.Math.pow(y-this.clicked_y, 2);
            if (dist > PiePreviewDeleteSign.click_cancel_treshold*PiePreviewDeleteSign.click_cancel_treshold)
                this.clicked.reset_target(1.0, 0.1);
        }

        if (GLib.Math.fabs(x) <= PiePreviewDeleteSign.radius*PiePreviewDeleteSign.globale_scale && GLib.Math.fabs(y) <= PiePreviewDeleteSign.radius*PiePreviewDeleteSign.globale_scale) {
            this.activity.reset_target(1.0, 0.2);
            return true;
        }

        this.activity.reset_target(0.0, 0.2);
        return false;
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when a button of the mouse is pressed.
    /////////////////////////////////////////////////////////////////////

    public bool on_button_press(double x, double y) {
        if (this.activity.end == 1.0) {
            this.clicked.reset_target(0.9, 0.1);
            this.clicked_x = x;
            this.clicked_y = y;
            return true;
        }
        return false;
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when a button of the mouse is released.
    /////////////////////////////////////////////////////////////////////

    public bool on_button_release(double x, double y) {
        if (this.clicked.end == 0.9) {
            this.clicked.reset_target(1.0, 0.1);
            this.on_clicked();

            return true;
        }
        return false;
    }
}

}
