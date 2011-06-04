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

    public class Color : GLib.Object {
    
        private float _r;
        private float _g;
        private float _b;
        private float _a;
    
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

        public Color() {
            _r = 1.0f;
            _g = 1.0f;
            _b = 1.0f;
            _a = 1.0f;
        }

        public Color.from_rgb(float red, float green, float blue) {
            Color.from_rgba(red, green, blue, 1.0f);
        }
        
        public Color.from_rgba(float red, float green, float blue, float alpha) {
            _r = red;
            _g = green;
            _b = blue;
            _a = alpha;
        }

        private void setHSV(float hue, float saturation, float val) {
            if(saturation == 0) {
		        _r = val;
		        _g = val;
		        _b = val;
		        return;
	        }
            hue = fmodf(hue, 360);
	        hue /= 60;
	        int i = (int) floorf(hue);
	        float f = hue - i;

	        switch(i) {
		        case 0:
			        _r = val;
			        _g = val * (1.0f - saturation * (1.0f - f));
			        _b = val * (1.0f - saturation);
			        break;
		        case 1:
			        _r = val * (1.0f - saturation * f);
			        _g = val;
			        _b = val * (1.0f - saturation);
			        break;
		        case 2:
			        _r = val * (1.0f - saturation);
			        _g = val;
			        _b = val * (1.0f - saturation * (1.0f - f));
			        break;
		        case 3:
			        _r = val * (1.0f - saturation);
			        _g = val * (1.0f - saturation * f);
			        _b = val;
			        break;
		        case 4:
			        _r = val * (1.0f - saturation * (1.0f - f));
			        _g = val * (1.0f - saturation);
			        _b = val;
			        break;
		        default:
			        _r = val;
			        _g = val * (1.0f - saturation);
			        _b = val * (1.0f - saturation * f);
			        break;
	        }
        }

        public void invert() {
            h += 180.0f;
            v = 1.0f - v;
        }

    }

}
