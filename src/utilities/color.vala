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
        Color.from_rgb(1.0f, 1.0f, 1.0f);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Creates a solid color with the given RGB values.
    /////////////////////////////////////////////////////////////////////

    public Color.from_rgb(float red, float green, float blue) {
        Color.from_rgba(red, green, blue, 1.0f);
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
    
    public Color.from_gdk(Gdk.Color color) {
        Color.from_rgb(
            (float)color.red/65535.0f,
            (float)color.green/65535.0f,
            (float)color.blue/65535.0f
        );
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Creates a color, parsed from a string, such as #22EE33
    /////////////////////////////////////////////////////////////////////
    
    public Color.from_string(string hex_string) {
        Gdk.Color color;
        Gdk.Color.parse(hex_string, out color);
        Color.from_gdk(color);
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

        Color.from_rgb((float)(rtotal/total), (float)(gtotal/total), (float)(btotal/total));

        if (s > 0.15f) s = 0.65f;

        v = 1.0f;
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
