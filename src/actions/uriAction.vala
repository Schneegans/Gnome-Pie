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
    
// This type of Action launches an application or a custom command.

public class UriAction : Action {

    public override string action_type { get {return _("Open URI");} }
    public override string label { get {return uri;} }
    public override string command { get {return uri;} }
    	
    public string uri { get; set; }

    public UriAction(string name, string icon_name, string uri, bool is_quick_action = false) {
        base(name, icon_name, is_quick_action);
        this.uri = uri;
    }

    public override void activate() {
        try{
            GLib.AppInfo.launch_default_for_uri(uri, null);
    	} catch (Error e) {
	        warning(e.message);
        }
    } 
}

}
