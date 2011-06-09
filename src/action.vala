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

    public class Action : GLib.Object {

	    public Cairo.ImageSurface icon {get; private set;}
	    public Color              color{get; private set;}
	    	
	    private string _command;
	    
	    public Action(string command, string icon) {
	        _command = command;
	
            var icon_theme = Gtk.IconTheme.get_default();
            var file = icon_theme.lookup_icon(icon, 48, Gtk.IconLookupFlags.NO_SVG);
            
	        _icon = new Cairo.ImageSurface.from_png(file.get_filename());
		    _color = new Color.from_icon(_icon);
	    }

	    public void execute() {
            try{
                GLib.DesktopAppInfo item = new GLib.DesktopAppInfo(_command);
            	item.launch (null, new AppLaunchContext());
            	debug("launched " + _command);
        	} catch (Error e) {
		        warning (e.message);
	        }
        }
    }

}
