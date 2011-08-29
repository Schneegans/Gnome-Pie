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

public class ClipboardGroup : ActionGroup {
    
    public static void register(out string name, out string icon, out string settings_name) {
        name = _("Clipboard");
        icon = "gnome-logout";
        settings_name = "clipboard";
    }
    
    public ClipboardGroup(string parent_id) {
        GLib.Object(parent_id : parent_id);
    }
    
    construct {
        
    }
    
    public static void test() {
        var clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
        
        clipboard.owner_change.connect(() => {
            debug("change!");
        });
    }
}

}
