/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2019 Simon Schneegans
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
/////////////////////////////////////////////////////////////////////////

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

    public static GroupRegistry.TypeDescription register() {
        var description = new GroupRegistry.TypeDescription();
        description.name = _("Group: Devices");
        description.icon = "drive-harddisk";
        description.description = _("Shows a Slice for each plugged in devices, like USB-Sticks.");
        description.id = "devices";
        return description;
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
        this.add_action(new UriAction(_("Root"), "drive-harddisk", "file:///"));

        // add all other devices
        foreach(var mount in this.monitor.get_mounts()) {
            // get icon
            var icon = mount.get_icon();

            this.add_action(new UriAction(mount.get_name(),
              icon.to_string(), mount.get_root().get_uri()));
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
