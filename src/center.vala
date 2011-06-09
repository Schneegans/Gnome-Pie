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

    public class Center {
    
        private Cairo.ImageSurface _imgRing;
	    private Cairo.ImageSurface _imgGlow;
	    private Cairo.ImageSurface _imgArrow;
	    private Ring               _parent;
	
	    private double _rot=       0.0;
	    private double _baserot =  0.0;
    
        public Center(Ring parent) {
            _parent = parent;
            _imgRing =  new Cairo.ImageSurface.from_png("data/ring.png");
		    _imgGlow =  new Cairo.ImageSurface.from_png("data/glow.png");
		    _imgArrow = new Cairo.ImageSurface.from_png("data/arrow.png");
        }
        
        public void draw(Cairo.Context ctx, double angle, double distance) {
            int win_middle = 0;
            _parent.get_size(out win_middle, null);
            win_middle /= 2;
 
		    _baserot += 0.5/Settings.refresh_rate;
		
		    ctx.set_operator(Cairo.Operator.DEST_OVER);
		
		    if (distance > 45) {
		        double diff = angle-_rot;
			    if (fabs(diff) > 0.15 && fabs(diff) < PI) {
				    if ((diff > 0 && diff < PI) || diff < -PI) _rot += 8.0/Settings.refresh_rate;
				    else		                               _rot -= 8.0/Settings.refresh_rate;
			    }
			    else _rot = angle;
		
			    _rot = fmod(_rot+2*PI, 2*PI);
		    
			    ctx.translate(win_middle, win_middle);
			    ctx.rotate(_rot);
			    
			    double alpha = distance > 65 ? 1.0 : 1.0 - 0.05*(65-distance);
			
			    ctx.set_source_surface(_imgArrow, -75, -75);
			    ctx.paint_with_alpha(alpha);
			
			    ctx.identity_matrix();
		    }
		    
            ctx.translate(win_middle, win_middle);
			ctx.rotate(_baserot);
			
		    ctx.set_source_surface(_imgRing, -75, -75);
		    ctx.paint();

		    ctx.set_source_surface(_imgGlow, -75, -75);
		    ctx.paint_with_alpha(0.7);
		    
		    ctx.set_operator(Cairo.Operator.ATOP);
		    
		    if (distance > 45)
    		    ctx.set_source_rgb(_parent.active_color().r, _parent.active_color().g, _parent.active_color().b);
	   	    else
		        ctx.set_source_rgb(0.5, 0.5, 0.5);
		        
            ctx.rectangle(-win_middle, -win_middle, win_middle*2, win_middle*2);
            ctx.fill();
            ctx.stroke();
            
            ctx.set_operator(Cairo.Operator.OVER);
        }
    }

}
