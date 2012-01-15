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

namespace GnomePie {	

/////////////////////////////////////////////////////////////////////////    
/// A class which interpolates smoothly between to given values.
/// Duration and interpolation mode can be specified.
/////////////////////////////////////////////////////////////////////////

public class AnimatedValue : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// The direction of the interpolation.
    /////////////////////////////////////////////////////////////////////

    public enum Direction { IN, OUT, IN_OUT, OUT_IN }
    
    /////////////////////////////////////////////////////////////////////
    /// Type of the interpolation, linear or cubic.
    /////////////////////////////////////////////////////////////////////
    
    private enum Type { LINEAR, CUBIC }
    
    /////////////////////////////////////////////////////////////////////
    /// Current value, interpolated.
    /////////////////////////////////////////////////////////////////////
    
    public double val { get; private set; }
    
    /////////////////////////////////////////////////////////////////////
    /// Starting value of the interpolation.
    /////////////////////////////////////////////////////////////////////
    
    public double start { get; private set; default=0.0; }
    
    /////////////////////////////////////////////////////////////////////
    /// Final value of the interpolation.
    /////////////////////////////////////////////////////////////////////
    
    public double end { get; private set; default=0.0; } 
    
    /////////////////////////////////////////////////////////////////////
    /// The current state. In range 0 .. 1
    /////////////////////////////////////////////////////////////////////
    
    private double state = 0.0;
    
    /////////////////////////////////////////////////////////////////////
    /// Duration of the interpolation. Should be in the same unit as 
    /// taken for the update() method.
    /////////////////////////////////////////////////////////////////////
    
    private double duration = 0.0;
    
    /////////////////////////////////////////////////////////////////////
    /// The amount of over-shooting of the cubicly interpolated value.
    /////////////////////////////////////////////////////////////////////
    
    private double multiplier = 0.0;
    
    /////////////////////////////////////////////////////////////////////
    /// Type of the interpolation, linear or cubic.
    /////////////////////////////////////////////////////////////////////
    
    private Type type = Type.LINEAR;
    
    /////////////////////////////////////////////////////////////////////
    /// The direction of the interpolation.
    /////////////////////////////////////////////////////////////////////
    
    private Direction direction = Direction.IN;
    
    /////////////////////////////////////////////////////////////////////
    /// Creates a new linearly interpolated value.
    /////////////////////////////////////////////////////////////////////
    
    public AnimatedValue.linear(double start, double end, double duration) {
        this.val = start;
        this.start = start;
        this.end = end;
        this.duration = duration;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Creates a new cubicly interpolated value.
    /////////////////////////////////////////////////////////////////////
    
    public AnimatedValue.cubic(Direction direction, double start, double end, double duration, double multiplier = 0) {
        this.val = start;
        this.start = start;
        this.end = end;
        this.duration = duration;
        this.direction = direction;
        this.type = Type.CUBIC;
        this.multiplier = multiplier;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Resets the final value of the interpolation to a new value. The
    /// current state is taken for the beginning from now.
    /////////////////////////////////////////////////////////////////////
    
    public void reset_target(double end, double duration) {
        this.end = end;
        this.duration = duration;
        this.start = this.val;
        
        if (duration == 0.0) {
            this.val = end;
            this.state = 1.0;
        } else {
            this.state = 0.0;
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Updates the interpolated value according to it's type.
    /////////////////////////////////////////////////////////////////////
    
    public void update(double time) {
        this.state += time/this.duration;
        
        if (this.state < 1) {
        
            switch (this.type) {
                case Type.LINEAR:
                    this.val = update_linear();
                    break;
                case Type.CUBIC:
                    switch (this.direction) {
                        case Direction.IN:
                            this.val = update_ease_in();
                            return;
                        case Direction.OUT:
                            this.val = update_ease_out();
                            return;
                        case Direction.IN_OUT:
                            this.val = update_ease_in_out();
                            return;
                        case Direction.OUT_IN:
                            this.val = update_ease_out_in();
                            return;
                }
                break;
            }
            
        } else if (this.val != this.end) {
             this.val = this.end;
        }  
    }

    /////////////////////////////////////////////////////////////////////
    /// The following equations are based on Robert Penner's easing 
    /// equations. See (http://www.robertpenner.com/easing/) and their 
    /// adaption by Zeh Fernando, Nate Chatellier and Arthur Debert for
    /// the Tweener class. See (http://code.google.com/p/tweener/).
    /////////////////////////////////////////////////////////////////////
    
    private double update_linear(double t = this.state, double s = this.start, double e = this.end) {
        return (s + t*(e - s));
    }
    
    private double update_ease_in(double t = this.state, double s = this.start, double e = this.end) {
        return (s + (t*t*((multiplier+1)*t-multiplier))*(e - s));
    }
    
    private double update_ease_out(double t = this.state, double s = this.start, double e = this.end) {
        return (s + ((t-1) * (t-1) * ((multiplier+1)*(t-1)+multiplier) + 1) * (e - s));
    }
    
    private double update_ease_in_out(double t = this.state, double s = this.start, double e = this.end) {
        if (this.state < 0.5) return update_ease_in(t*2, s, e - (e-s)*0.5);
        else                  return update_ease_out(t*2-1, s + (e-s)*0.5, e);
    }
    
    private double update_ease_out_in(double t = this.state, double s = this.start, double e = this.end) {
        if (this.state < 0.5) return update_ease_out(t*2, s, e - (e-s)*0.5);
        else                  return update_ease_in(t*2-1, s + (e-s)*0.5, e);
    }
}

}
