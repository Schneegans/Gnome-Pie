/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2018 Simon Schneegans
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
/// This class representing a layer of the center of a pie. Each theme
/// may have plenty of them.
/////////////////////////////////////////////////////////////////////////

public class CenterLayer : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Possible rotation modes.
    /// AUTO:       Turns the layer continously.
    /// TO_MOUSE:   Turns the layer always to the pointer.
    /// TO_ACTIVE:  Turns the layer to the active slice.
    /// TO_HOUR_12: Turns the layer to the position of the current hour.
    /// TO_HOUR_24: Turns the layer to the position of the current hour.
    /// TO_MINUTE:  Turns the layer to the position of the current minute.
    /// TO_SECOND:  Turns the layer to the position of the current second.
    /////////////////////////////////////////////////////////////////////

    public enum RotationMode {AUTO, TO_MOUSE, TO_ACTIVE, TO_HOUR_12,
                              TO_HOUR_24, TO_MINUTE, TO_SECOND}

    /////////////////////////////////////////////////////////////////////
    /// Information on the contained image.
    /////////////////////////////////////////////////////////////////////

    public Image image {get; private set;}
    public string image_file;

    /////////////////////////////////////////////////////////////////////
    /// Properties for the active state of this layer.
    /////////////////////////////////////////////////////////////////////

    public double active_scale {get; private set;}
    public double active_rotation_speed {get; private set;}
    public double active_alpha {get; private set;}
    public bool active_colorize {get; private set;}
    public RotationMode active_rotation_mode {get; private set;}

    /////////////////////////////////////////////////////////////////////
    /// Properties for the inactive state of this layer.
    /////////////////////////////////////////////////////////////////////

    public double inactive_scale {get; private set;}
    public double inactive_rotation_speed {get; private set;}
    public double inactive_alpha {get; private set;}
    public bool inactive_colorize {get; private set;}
    public RotationMode inactive_rotation_mode {get; private set;}

    /////////////////////////////////////////////////////////////////////
    /// The current rotation of this layer. TODO: Remove this.
    /////////////////////////////////////////////////////////////////////

    public double rotation {get; set;}

    /////////////////////////////////////////////////////////////////////
    /// Helper variable for image loading.
    /////////////////////////////////////////////////////////////////////

    private int center_radius;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members of the layer.
    /////////////////////////////////////////////////////////////////////

    public CenterLayer(string image_file, int center_radius, double active_scale, double active_rotation_speed,
                                    double active_alpha,   bool active_colorize,   RotationMode active_rotation_mode,
                                    double inactive_scale, double inactive_rotation_speed,
                                    double inactive_alpha, bool inactive_colorize, RotationMode inactive_rotation_mode) {

        this.image_file = image_file;
        this.center_radius = center_radius;

        this.active_scale = active_scale;
        this.active_rotation_speed = active_rotation_speed;
        this.active_alpha = active_alpha;
        this.active_colorize = active_colorize;
        this.active_rotation_mode = active_rotation_mode;

        this.inactive_scale = inactive_scale;
        this.inactive_rotation_speed = inactive_rotation_speed;
        this.inactive_alpha = inactive_alpha;
        this.inactive_colorize = inactive_colorize;
        this.inactive_rotation_mode = inactive_rotation_mode;

        this.rotation = 0.0;
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads the contained image.
    /////////////////////////////////////////////////////////////////////

    public void load_image() {
        this.image = new Image.from_file_at_size(image_file, 2*center_radius, 2*center_radius);
    }
}

}
