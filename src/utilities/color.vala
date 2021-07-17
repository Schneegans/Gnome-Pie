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

using GLib.Math;

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// A Color class with full rgb/hsv support
/// and some useful utility methods.
/////////////////////////////////////////////////////////////////////////

public class Color: GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Private members, storing the actual color information.
    /// In range 0 .. 1
    /////////////////////////////////////////////////////////////////////

    private float _r;
    private float _g;
    private float _b;
    private float _a;

    /////////////////////////////////////////////////////////////////////
    /// Creates a white Color.
    /////////////////////////////////////////////////////////////////////

    public Color() {
        this.from_rgb(1.0f, 1.0f, 1.0f);
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a solid color with the given RGB values.
    /////////////////////////////////////////////////////////////////////

    public Color.from_rgb(float red, float green, float blue) {
        this.from_rgba(red, green, blue, 1.0f);
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a translucient color with the given RGBA values.
    /////////////////////////////////////////////////////////////////////

    public Color.from_rgba(float red, float green, float blue, float alpha) {
        r = red;
        g = green;
        b = blue;
        a = alpha;
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a color from the given Gdk.Color
    /////////////////////////////////////////////////////////////////////

    public Color.from_gdk(Gdk.RGBA color) {
        this.from_rgba(
            (float)color.red,
            (float)color.green,
            (float)color.blue,
            (float)color.alpha
        );
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a color from a given widget style
    /////////////////////////////////////////////////////////////////////

    public Color.from_widget_style(Gtk.Widget widget, string style_name) {
        var ctx = widget.get_style_context();
        Gdk.RGBA color;
        if (!ctx.lookup_color(style_name, out color)) {
            warning("Failed to get style color for widget style \"" + style_name + "\"!");
        }
        this.from_gdk(color);
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a color, parsed from a string, such as #22EE33
    /////////////////////////////////////////////////////////////////////

    public Color.from_string(string hex_string) {
        var color = Gdk.RGBA();
        color.parse(hex_string);
        this.from_gdk(color);
    }

    /////////////////////////////////////////////////////////////////////
    /// Gets the main color from an Image. Code from Unity.
    /////////////////////////////////////////////////////////////////////

    public Color.from_icon(Image icon) {
        unowned uchar[] data = icon.surface.get_data();

        uint width = icon.surface.get_width();
        uint height = icon.surface.get_height();
        uint row_bytes = icon.surface.get_stride();

        double total = 0.0;
        double rtotal = 0.0;
        double gtotal = 0.0;
        double btotal = 0.0;

        for (uint i = 0; i < width; ++i) {
            for (uint j = 0; j < height; ++j) {
                uint pixel = j * row_bytes + i * 4;
                double b = data[pixel + 0]/255.0;
                double g = data[pixel + 1]/255.0;
                double r = data[pixel + 2]/255.0;
                double a = data[pixel + 3]/255.0;

                double saturation = (fmax (r, fmax (g, b)) - fmin (r, fmin (g, b)));
                double relevance = 0.1 + 0.9 * a * saturation;

                rtotal +=  (r * relevance);
                gtotal +=  (g * relevance);
                btotal +=  (b * relevance);

                total += relevance;
            }
        }

        this.from_rgb((float)(rtotal/total), (float)(gtotal/total), (float)(btotal/total));

        if (s > 0.15f) s = 0.65f;

        v = 1.0f;
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns this color as its hex representation.
    /////////////////////////////////////////////////////////////////////

    public string to_hex_string() {
        return "#%02X%02X%02X".printf((int)(_r*255), (int)(_g*255), (int)(_b*255));
    }

    /////////////////////////////////////////////////////////////////////
    /// The reddish part of the color.
    /////////////////////////////////////////////////////////////////////

    public float r {
        get {
            return _r;
        }
        set {
            if (value > 1.0f) _r = 1.0f;
            else if (value < 0.0f) _r = 0.0f;
            else _r = value;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// The greenish part of the color.
    /////////////////////////////////////////////////////////////////////

    public float g {
        get {
            return _g;
        }
        set {
            if (value > 1.0f) _g = 1.0f;
            else if (value < 0.0f) _g = 0.0f;
            else _g = value;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// The blueish part of the color.
    /////////////////////////////////////////////////////////////////////

    public float b {
        get {
            return _b;
        }
        set {
            if (value > 1.0f) _b = 1.0f;
            else if (value < 0.0f) _b = 0.0f;
            else _b = value;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// The transparency of the color.
    /////////////////////////////////////////////////////////////////////

    public float a {
        get {
            return _a;
        }
        set {
            if (value > 1.0f) _a = 1.0f;
            else if (value < 0.0f) _a = 0.0f;
            else _a = value;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// The hue of the color.
    /////////////////////////////////////////////////////////////////////

    public float h {
        get {
            if (s > 0.0f) {
                float maxi = fmaxf(fmaxf(r, g), b);
                float mini = fminf(fminf(r, g), b);

                if (maxi == r)
                    return fmodf(60.0f*((g-b)/(maxi-mini))+360.0f, 360.0f);
                else if (maxi == g)
                    return fmodf(60.0f*(2.0f + (b-r)/(maxi-mini))+360.0f, 360.0f);
                else
                    return fmodf(60.0f*(4.0f + (r-g)/(maxi-mini))+360.0f, 360.0f);
            }
            else return 0.0f;
        }
        set {
            setHSV(value, s, v);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// The saturation of the color.
    /////////////////////////////////////////////////////////////////////

    public float s {
        get {
            if (v == 0.0f) return 0.0f;
            else return ((v-fminf(fminf(r, g), b)) / v);
        }
        set {
            if (value > 1.0f) setHSV(h, 1.0f, v);
            else if (value < 0.0f) setHSV(h, 0.0f, v);
            else setHSV(h, value, v);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// The value of the color.
    /////////////////////////////////////////////////////////////////////

    public float v {
        get {
            return fmaxf(fmaxf(r, g), b);
        }
        set {
            if (value > 1) setHSV(h, s, 1.0f);
            else if (value < 0) setHSV(h, s, 0.0f);
            else setHSV(h, s, value);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Inverts the color.
    /////////////////////////////////////////////////////////////////////

    public void invert() {
        h += 180.0f;
        v = 1.0f - v;
    }

    /////////////////////////////////////////////////////////////////////
    /// Private member, used to apply color changes.
    /////////////////////////////////////////////////////////////////////

    private void setHSV(float hue, float saturation, float val) {
        if(saturation == 0) {
            r = val;
            g = val;
            b = val;
            return;
        }
        hue = fmodf(hue, 360);
        hue /= 60;
        int i = (int) floorf(hue);
        float f = hue - i;

        switch(i) {
            case 0:
                r = val;
                g = val * (1.0f - saturation * (1.0f - f));
                b = val * (1.0f - saturation);
                break;
            case 1:
                r = val * (1.0f - saturation * f);
                g = val;
                b = val * (1.0f - saturation);
                break;
            case 2:
                r = val * (1.0f - saturation);
                g = val;
                b = val * (1.0f - saturation * (1.0f - f));
                break;
            case 3:
                r = val * (1.0f - saturation);
                g = val * (1.0f - saturation * f);
                b = val;
                break;
            case 4:
                r = val * (1.0f - saturation * (1.0f - f));
                g = val * (1.0f - saturation);
                b = val;
                break;
            default:
                r = val;
                g = val * (1.0f - saturation);
                b = val * (1.0f - saturation * f);
                break;
        }
    }
}

}
