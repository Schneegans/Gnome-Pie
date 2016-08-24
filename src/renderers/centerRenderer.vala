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
///  Renders the center of a Pie.
/////////////////////////////////////////////////////////////////////////

public class CenterRenderer : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// The PieRenderer which owns this CenterRenderer.
    /////////////////////////////////////////////////////////////////////

    private unowned PieRenderer parent;

    /////////////////////////////////////////////////////////////////////
    /// The caption drawn in the center. Changes when the active slice
    /// changes.
    /////////////////////////////////////////////////////////////////////

    private unowned Image? caption;

    /////////////////////////////////////////////////////////////////////
    /// The color of the currently active slice. Used to colorize layers.
    /////////////////////////////////////////////////////////////////////

    private Color color;

    /////////////////////////////////////////////////////////////////////
    /// Two AnimatedValues: alpha is for global transparency (when
    /// fading in/out), activity is 1.0 if there is an active slice and
    /// 0.0 if there is no active slice.
    /////////////////////////////////////////////////////////////////////

    private AnimatedValue activity;
    private AnimatedValue alpha;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////

    public CenterRenderer(PieRenderer parent) {
        this.parent = parent;
        this.activity = new AnimatedValue.linear(0.0, 0.0, Config.global.theme.transition_time);
        this.alpha = new AnimatedValue.linear(0.0, 1.0, Config.global.theme.fade_in_time);
        this.color = new Color();
        this.caption = null;
    }

    /////////////////////////////////////////////////////////////////////
    /// Initiates the fade-out animation by resetting the targets of the
    /// AnimatedValues to 0.0.
    /////////////////////////////////////////////////////////////////////

    public void fade_out() {
        this.activity.reset_target(0.0, Config.global.theme.fade_out_time);
        this.alpha.reset_target(0.0, Config.global.theme.fade_out_time);
    }

    /////////////////////////////////////////////////////////////////////
    /// Should be called if the active slice of the PieRenderer changes.
    /// The members activity, caption and color are set accordingly.
    /////////////////////////////////////////////////////////////////////

    public void set_active_slice(SliceRenderer? active_slice) {
        if (active_slice == null) {
            this.activity.reset_target(0.0, Config.global.theme.transition_time);
        } else {
            this.activity.reset_target(1.0, Config.global.theme.transition_time);
            this.caption = active_slice.caption;
            this.color   = active_slice.color;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Draws all center layers and the caption.
    /////////////////////////////////////////////////////////////////////

    public void draw(double frame_time, Cairo.Context ctx, double angle, int slice_track) {
        // get all center_layers
        var layers = Config.global.theme.center_layers;

        // update the AnimatedValues
        this.activity.update(frame_time);
        this.alpha.update(frame_time);

        // draw each layer
        foreach (var layer in layers) {
            ctx.save();

            // calculate all values needed for animation/drawing
            double max_scale = layer.active_scale*this.activity.val
                + layer.inactive_scale*(1.0-this.activity.val);
            double max_alpha = layer.active_alpha*this.activity.val
                + layer.inactive_alpha*(1.0-this.activity.val);
            double colorize = ((layer.active_colorize == true) ? this.activity.val : 0.0)
                + ((layer.inactive_colorize == true) ? 1.0 - this.activity.val : 0.0);
            double max_rotation_speed = layer.active_rotation_speed*this.activity.val
                + layer.inactive_rotation_speed*(1.0-this.activity.val);
            CenterLayer.RotationMode rotation_mode = ((this.activity.val > 0.5) ?
                layer.active_rotation_mode : layer.inactive_rotation_mode);

            double direction = 0;

            if (rotation_mode == CenterLayer.RotationMode.TO_MOUSE) {
                direction = angle;

            } else if (rotation_mode == CenterLayer.RotationMode.TO_ACTIVE) {
                double slice_angle = parent.total_slice_count > 0 ? 2*PI/parent.total_slice_count : 0;
                direction = (int)((angle+0.5*slice_angle) / (slice_angle))*slice_angle;

            } else if (rotation_mode == CenterLayer.RotationMode.TO_SECOND) {
                var now = new DateTime.now_local();
                direction = 2*PI*(now.get_second()+60-15)/60;

            } else if (rotation_mode == CenterLayer.RotationMode.TO_MINUTE) {
                var now = new DateTime.now_local();
                direction = 2*PI*(now.get_minute()+60-15)/60;

            } else if (rotation_mode == CenterLayer.RotationMode.TO_HOUR_24) {
                var now = new DateTime.now_local();
                direction = 2*PI*(now.get_hour()+24-6)/24 + 2*PI*(now.get_minute())/(60*24);

            } else if (rotation_mode == CenterLayer.RotationMode.TO_HOUR_12) {
                var now = new DateTime.now_local();
                direction = 2*PI*(now.get_hour()+12-3)/12 + 2*PI*(now.get_minute())/(60*12);
            }

            if (rotation_mode == CenterLayer.RotationMode.AUTO) {
                layer.rotation += max_rotation_speed*frame_time;
            } else {
                direction = Math.fmod(direction, 2*PI);
                double diff = direction-layer.rotation;
                double smoothy = fabs(diff) < 0.9 ? fabs(diff) + 0.1 : 1.0;
                double step = max_rotation_speed*frame_time*smoothy;

                if (fabs(diff) <= step || fabs(diff) >= 2.0*PI - step)
                    layer.rotation = direction;
                else {
                    if ((diff > 0 && diff < PI) || diff < -PI) layer.rotation += step;
                    else                                       layer.rotation -= step;
                }
            }

            layer.rotation = fmod(layer.rotation+2*PI, 2*PI);

            if (colorize > 0.0) ctx.push_group();

            // transform the context
            ctx.rotate(layer.rotation);
            ctx.scale(max_scale, max_scale);

            // paint the layer
            layer.image.paint_on(ctx, this.alpha.val*max_alpha);

            // colorize it, if necessary
            if (colorize > 0.0) {
                ctx.set_operator(Cairo.Operator.ATOP);
                ctx.set_source_rgb(this.color.r, this.color.g, this.color.b);
                ctx.paint_with_alpha(colorize);

                ctx.set_operator(Cairo.Operator.OVER);
                ctx.pop_group_to_source();
                ctx.paint();
            }

            ctx.restore();
        }

        // draw caption
        if (Config.global.theme.caption && caption != null && this.activity.val > 0) {
            ctx.save();
            ctx.identity_matrix();
            ctx.translate(this.parent.center_x, (int)(Config.global.theme.caption_position) + this.parent.center_y);
            caption.paint_on(ctx, this.activity.val*this.alpha.val);
            ctx.restore();
        }

        //scroll pie
        if (this.alpha.val > 0.1
            && this.parent.original_visible_slice_count < this.parent.slice_count()
            && this.parent.original_visible_slice_count > 0) {
            int np= (this.parent.slice_count()+this.parent.original_visible_slice_count -1)/this.parent.original_visible_slice_count;
            int cp= this.parent.first_slice_idx / this.parent.original_visible_slice_count;
            int r= 8;       //circle radious
            int dy= 20;     //distance between circles
            double a= 0.8 * this.alpha.val;
            int dx= (int)Config.global.theme.center_radius + r + 10;
            if (this.parent.center_x + dx > this.parent.size_w)
                dx= -dx;    //no right side, put scroll in the left size
            ctx.save();
            ctx.identity_matrix();
            ctx.translate(this.parent.center_x + dx, this.parent.center_y - (np-1)*dy/2);
            for (int i=0; i<np; i++) {
                ctx.arc( 0, 0, r, 0, 2*PI );
                if (i == cp){
                    ctx.set_source_rgba(0.3,0.3,0.3, a);    //light gray stroke
                    ctx.stroke_preserve();
                    ctx.set_source_rgba(1,1,1, a);          //white fill
                    ctx.fill(); //current
                } else {
                    ctx.set_source_rgba(1,1,1, a);          //white stroke
                    ctx.stroke_preserve();
                    ctx.set_source_rgba(0.3,0.3,0.3, a/4);  //light gray fill
                    ctx.fill(); //current
                }
                ctx.translate(0, dy);
            }
            ctx.restore();
        }
    }
}

}
