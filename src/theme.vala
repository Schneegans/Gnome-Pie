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

    public class Theme : GLib.Object {
        
            public static Cairo.ImageSurface ring{get; private set;}
	        public static Cairo.ImageSurface arrow{get; private set;}
        
        public static void load () {
            _ring  = new Cairo.ImageSurface.from_png("data/ring.png");
		    _arrow = new Cairo.ImageSurface.from_png("data/arrow.png");
        }
    
    }

}
