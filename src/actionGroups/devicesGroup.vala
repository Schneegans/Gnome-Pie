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

public class DevicesGroup : ActionGroup {
    
    public static void register(out string name, out string icon, out string settings_name) {
        name = _("Devices");
        icon = "harddrive";
        settings_name = "devices";
    }

    private bool changing = false;
    private bool changed_again = false;
    private GLib.VolumeMonitor monitor;
    
    public DevicesGroup(string parent_id) {
        GLib.Object(parent_id : parent_id);
    }
    
    construct {
        this.monitor = GLib.VolumeMonitor.get();
        
        this.load();

        // add monitor
        this.monitor.mount_added.connect(this.reload);
        this.monitor.mount_removed.connect(this.reload);
    }
    
    private void load() {
    
        this.add_action(new UriAction(_("Root"), "harddrive", "file:///"));
    
        foreach(var mount in this.monitor.get_mounts()) {
            // get icon
            var icon_names = mount.get_icon().to_string().split(" ");
            
            string icon = "";
            foreach (var icon_name in icon_names) {
                if (Gtk.IconTheme.get_default().has_icon(icon_name)) {
                    icon = icon_name;
                    break;
                }
            }
            
            this.add_action(new UriAction(mount.get_name(), icon, mount.get_root().get_uri()));
        }
    }
    
    private void reload() {
        // avoid too frequent changes...
        if (!this.changing) {
            this.changing = true;
            Timeout.add(200, () => {
                if (this.changed_again) {
                    this.changed_again = false;
                    return true;
                }

                message("Devices changed...");
                this.delete_all();
                this.load();
                
                this.changing = false;
                return false;
            });
        } else {
            this.changed_again = true;
        }    
    }
}

}
