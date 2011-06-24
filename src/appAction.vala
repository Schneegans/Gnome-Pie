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

    public class AppAction : Action {
	    	
	    private string _command;

	    public AppAction(string name, string icon_name, string command) {
	        base(name, icon_name);
	        
	        _command   = command;
	    }

	    public override void execute() {
	    
            try{
                var item = GLib.AppInfo.create_from_commandline(_command, null, GLib.AppInfoCreateFlags.NONE);
                item.launch(null, null);
        	} catch (Error e) {
		        warning (e.message);
	        }
        } 
    }

}
