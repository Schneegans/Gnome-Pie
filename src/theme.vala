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
        
            public static Cairo.ImageSurface ring     {get; private set;}
	        public static Cairo.ImageSurface arrow    {get; private set;}
	        public static Cairo.ImageSurface icon_fg  {get; private set;}
	        public static Cairo.ImageSurface icon_bg  {get; private set;}
	        public static Cairo.ImageSurface icon_mask{get; private set;}
        
        public static void load () {
            ring  =     IconLoader.load("themes/" + Settings.theme + "/ring.svg",     100);
		    arrow =     IconLoader.load("themes/" + Settings.theme + "/arrow.svg",    100);
		    icon_fg =   IconLoader.load("themes/" + Settings.theme + "/icon_fg.svg",   (int)(Settings.icon_size*Settings.max_zoom));
		    icon_bg =   IconLoader.load("themes/" + Settings.theme + "/icon_bg.svg",   (int)(Settings.icon_size*Settings.max_zoom));
		    icon_mask = IconLoader.load("themes/" + Settings.theme + "/icon_mask.svg", (int)(Settings.icon_size*Settings.max_zoom));
        }
    
    }

}
