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

/////////////////////////////////////////////////////////////////////
/// An ActionGroup which contains all currently plugged-in devices, 
/// such as CD-ROM's or USB-sticks.
/////////////////////////////////////////////////////////////////////

public class DevicesGroup : ActionGroup {
    
    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of ActionGroup. It sets the display
    /// name for this ActionGroup, it's icon name and the string used in 
    /// the pies.conf file for this kind of ActionGroups.
    /////////////////////////////////////////////////////////////////////
    
    public static void register(out string name, out string icon, out string settings_name) {
        name = _("Devices");
        icon = "harddrive";
        settings_name = "devices";
    }

    /////////////////////////////////////////////////////////////////////
    /// Two members needed to avoid useless, frequent changes of the 
    /// stored Actions.
    /////////////////////////////////////////////////////////////////////

    private bool changing = false;
    private bool changed_again = false;
    
    /////////////////////////////////////////////////////////////////////
    /// The VolumeMonitor used to check for added or removed devices.
    /////////////////////////////////////////////////////////////////////
    
    private GLib.VolumeMonitor monitor;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////
    
    public DevicesGroup(string parent_id) {
        GLib.Object(parent_id : parent_id);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Construct block loads all currently plugged-in devices and
    /// connects signal handlers to the VolumeMonitor.
    /////////////////////////////////////////////////////////////////////
    
    construct {
        this.monitor = GLib.VolumeMonitor.get();
        
        this.load();

        // add monitor
        this.monitor.mount_added.connect(this.reload);
        this.monitor.mount_removed.connect(this.reload);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads all currently plugged-in devices.
    /////////////////////////////////////////////////////////////////////
    
    private void load() {
        // add root device
        this.add_action(new UriAction(_("Root"), "harddrive", "file:///"));
    
        // add all other devices
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
    
    /////////////////////////////////////////////////////////////////////
    /// Reloads all devices. Is called when the VolumeMonitor changes.
    /////////////////////////////////////////////////////////////////////
    
    private void reload() {
        // avoid too frequent changes...
        if (!this.changing) {
            this.changing = true;
            Timeout.add(200, () => {
                if (this.changed_again) {
                    this.changed_again = false;
                    return true;
                }

                // reload
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
