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

    // a base class for actions, which are executed when the user
    // activates a pie's slice
    public abstract class Action : GLib.Object {

	    public Image  active_icon   {get; private set;}
	    public Image  inactive_icon {get; private set;}
	    public Color  color         {get; private set;}
	    public string name          {get; private set;}
	    	
	    private string icon_name;

	    public Action(string name, string icon_name) {
	        this.name      = name;
	        this.icon_name = icon_name;

	        this.reload_icon();
		    
		    Settings.global.notify["theme"].connect(this.reload_icon);
		    Gtk.IconTheme.get_default().changed.connect(this.reload_icon);
	    }

	    public abstract void execute();
        
        private void reload_icon() {
            int size = (int)(2*Settings.global.theme.slice_radius*Settings.global.theme.max_zoom);
            this.color =         new Color();
		    this.active_icon =   new Image.themed_icon(this.icon_name, size, true,  
		                                               Settings.global.theme);
		    this.inactive_icon = new Image.themed_icon(this.icon_name, size, false, 
		                                               Settings.global.theme);
		    this.active_icon.on_finished_loading.connect(()=> {
		        this.color = new Color.from_icon(this.active_icon);
		    });         
        }
        
    }

}
