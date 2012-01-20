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

using GLib.Math;

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////    
/// Renders a Slice of a Pie. According to the current theme.
/////////////////////////////////////////////////////////////////////////

public class SliceRenderer : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Whether this slice is active (hovered) or not.
    /////////////////////////////////////////////////////////////////////

    public bool active {get; private set; default = false;}
    
    /////////////////////////////////////////////////////////////////////
    /// The Image which should be displayed as center caption when this
    /// slice is active.
    /////////////////////////////////////////////////////////////////////
    
    public Image caption {get; private set;}
    
    /////////////////////////////////////////////////////////////////////
    /// The color which should be used for colorizing center layers when
    /// this slice is active.
    /////////////////////////////////////////////////////////////////////
    
    public Color color {get; private set;}
    
    /////////////////////////////////////////////////////////////////////
    /// The two Images used, when this slice is active or not.
    /////////////////////////////////////////////////////////////////////
    
    private Image active_icon;
    private Image inactive_icon;
    
    /////////////////////////////////////////////////////////////////////
    /// The Image displaying the associated hot key of this slice.
    /////////////////////////////////////////////////////////////////////
    
    private Image hotkey;
    
    /////////////////////////////////////////////////////////////////////
    /// The Action which is rendered by this SliceRenderer.
    /////////////////////////////////////////////////////////////////////
    
    private Action action;
    
    /////////////////////////////////////////////////////////////////////
    /// The PieRenderer which owns this SliceRenderer.
    /////////////////////////////////////////////////////////////////////

    private unowned PieRenderer parent;    
    
    /////////////////////////////////////////////////////////////////////
    /// The index of this slice in a pie. Clockwise assigned, starting
    /// from the right-most slice.
    /////////////////////////////////////////////////////////////////////
    
    private int position;
    
    /////////////////////////////////////////////////////////////////////
    /// AnimatedValues needed for a slice.
    /////////////////////////////////////////////////////////////////////
    
    private AnimatedValue fade;             // for transitions from active to inactive
    private AnimatedValue scale;            // for zoom effect
    private AnimatedValue alpha;            // for fading in/out
    private AnimatedValue fade_rotation;    // for fading in/out
    private AnimatedValue fade_scale;       // for fading in/out

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all AnimatedValues.
    /////////////////////////////////////////////////////////////////////

    public SliceRenderer(PieRenderer parent) {
        this.parent = parent;
       
        this.fade =  new AnimatedValue.linear(0.0, 0.0, Config.global.theme.transition_time);
        this.alpha = new AnimatedValue.linear(0.0, 1.0, Config.global.theme.fade_in_time);
        this.scale = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 
                                                 1.0/Config.global.theme.max_zoom, 
                                                 1.0/Config.global.theme.max_zoom, 
                                                 Config.global.theme.transition_time, 
                                                 Config.global.theme.springiness);
        this.fade_scale = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 
                                                 Config.global.theme.fade_in_zoom, 1.0, 
                                                 Config.global.theme.fade_in_time, 
                                                 Config.global.theme.springiness);
        this.fade_rotation = new AnimatedValue.cubic(AnimatedValue.Direction.OUT, 
                                                 Config.global.theme.fade_in_rotation, 0.0, 
                                                 Config.global.theme.fade_in_time);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads an Action. All members are initialized accordingly.
    /////////////////////////////////////////////////////////////////////

    public void load(Action action, int position) {
        this.position = position;
        this.action = action;
        
    
        if (Config.global.theme.caption)
            this.caption = new RenderedText(action.name, 
                                            Config.global.theme.caption_width,
                                            Config.global.theme.caption_height,
                                            Config.global.theme.caption_font,
                                            Config.global.theme.caption_color,
                                            Config.global.global_scale);
            
        this.active_icon = new ThemedIcon(action.icon, true);
        this.inactive_icon = new ThemedIcon(action.icon, false);
        
        this.color = new Color.from_icon(this.active_icon);
        
        string hotkey_label = "";
        if (position < 10) {
            hotkey_label = "%u".printf(position);
        } else if (position < 36) {
            hotkey_label = "%c".printf((char)(55 + position));
        }
        
        this.hotkey = new RenderedText(hotkey_label, (int)Config.global.theme.slice_radius*2,
                         (int)Config.global.theme.slice_radius*2, "sans 20",
                         Config.global.theme.caption_color, Config.global.global_scale);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Activaes the Action of this slice.
    /////////////////////////////////////////////////////////////////////
    
    public void activate() {
        action.activate();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Initiates the fade-out animation by resetting the targets of the
    /// AnimatedValues to 0.0.
    /////////////////////////////////////////////////////////////////////
    
    public void fade_out() {
        this.alpha.reset_target(0.0, Config.global.theme.fade_out_time);
        this.fade_scale = new AnimatedValue.cubic(AnimatedValue.Direction.IN, 
                                             this.fade_scale.val, 
                                             Config.global.theme.fade_out_zoom, 
                                             Config.global.theme.fade_out_time, 
                                             Config.global.theme.springiness);
        this.fade_rotation = new AnimatedValue.cubic(AnimatedValue.Direction.IN, 
                                             this.fade_rotation.val, 
                                             Config.global.theme.fade_out_rotation, 
                                             Config.global.theme.fade_out_time);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Should be called if the active slice of the PieRenderer changes.
    /// The members activity, caption and color are set accordingly.
    /////////////////////////////////////////////////////////////////////
    
    public void set_active_slice(SliceRenderer? active_slice) {
       if (active_slice == this) {
            this.fade.reset_target(1.0, Config.global.theme.transition_time);
        } else {
            this.fade.reset_target(0.0, Config.global.theme.transition_time);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Draws all layers of the slice.
    /////////////////////////////////////////////////////////////////////

    public void draw(double frame_time, Cairo.Context ctx, double angle, double distance) {
    
        // update the AnimatedValues
        this.scale.update(frame_time);
        this.alpha.update(frame_time);
        this.fade.update(frame_time);
        this.fade_scale.update(frame_time);
        this.fade_rotation.update(frame_time);
	    
	    double direction = 2.0 * PI * position/parent.slice_count() + this.fade_rotation.val;
	    double max_scale = 1.0/Config.global.theme.max_zoom;
        double diff = fabs(angle-direction);
        
        if (diff > PI)
	        diff = 2 * PI - diff;

        if (diff < 2 * PI * Config.global.theme.zoom_range)
            max_scale = (Config.global.theme.max_zoom/(diff * (Config.global.theme.max_zoom - 1)
                        /(2 * PI * Config.global.theme.zoom_range) + 1))
                        /Config.global.theme.max_zoom;
	    
	    active = ((parent.active_slice >= 0) && (diff < PI/parent.slice_count()));
        
        max_scale = (parent.active_slice >= 0 ? max_scale : 1.0/Config.global.theme.max_zoom);
        
        if (fabs(this.scale.end - max_scale) > Config.global.theme.max_zoom*0.005)
            this.scale.reset_target(max_scale, Config.global.theme.transition_time);
        
        ctx.save();
        
        // distance from the center
        double radius = Config.global.theme.radius;
        
        // increase radius if there are many slices in a pie
        if (atan((Config.global.theme.slice_radius+Config.global.theme.slice_gap)
          /(radius/Config.global.theme.max_zoom)) > PI/parent.slice_count()) {
            radius = (Config.global.theme.slice_radius+Config.global.theme.slice_gap)
                     /tan(PI/parent.slice_count())*Config.global.theme.max_zoom;
        }
        
        // transform the context
        ctx.scale(scale.val*fade_scale.val, scale.val*fade_scale.val);
        ctx.translate(cos(direction)*radius, sin(direction)*radius);
        
        ctx.push_group();
        
        ctx.set_operator(Cairo.Operator.ADD);
    
        // paint the images
        if (fade.val > 0.0) active_icon.paint_on(ctx, this.alpha.val*this.fade.val);
        if (fade.val < 1.0) inactive_icon.paint_on(ctx, this.alpha.val*(1.0 - fade.val));
        
        if (this.parent.show_hotkeys) {
            ctx.set_operator(Cairo.Operator.ATOP);
            ctx.set_source_rgba(0, 0, 0, 0.5);
            ctx.paint();
        }
        
        ctx.set_operator(Cairo.Operator.OVER);
        
        
        ctx.pop_group_to_source();
        ctx.paint();
        
        // draw hotkeys if necassary
        if (this.parent.show_hotkeys)
            this.hotkey.paint_on(ctx, 1.0);
            
        ctx.restore();
    }
}

}
