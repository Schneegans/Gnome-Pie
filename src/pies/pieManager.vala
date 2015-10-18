/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2015 by Simon Schneegans
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// A static class which stores all Pies. It can be used to add, delete
/// and open Pies.
/////////////////////////////////////////////////////////////////////////

public class PieManager : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// A map of all Pies. It contains both, dynamic and persistent Pies.
    /// They are associated to their ID's.
    /////////////////////////////////////////////////////////////////////

    public static Gee.HashMap<string, Pie?> all_pies { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Stores all PieWindows which are currently opened. Should be
    /// rarely more than two...
    /////////////////////////////////////////////////////////////////////

    public static Gee.HashSet<PieWindow?> opened_windows { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Stores all global hotkeys.
    /////////////////////////////////////////////////////////////////////

    public static BindingManager bindings;

    /////////////////////////////////////////////////////////////////////
    /// True, if any pie has the current focus. If it is closing this
    /// will be false already.
    /////////////////////////////////////////////////////////////////////

    private static bool a_pie_is_active = false;

    /////////////////////////////////////////////////////////////////////
    /// Storing the position of the last Pie. Used for subpies, which are
    /// opened at their parents location.
    /////////////////////////////////////////////////////////////////////

    private static int last_x = 0;
    private static int last_y = 0;

    /////////////////////////////////////////////////////////////////////
    /// Initializes all Pies. They are loaded from the pies.conf file.
    /////////////////////////////////////////////////////////////////////

    public static void init() {
        all_pies = new Gee.HashMap<string, Pie?>();
        opened_windows = new Gee.HashSet<PieWindow?>();
        bindings = new BindingManager();

        // load all Pies from th pies.conf file
        Pies.load();

        // open the according pie if it's hotkey is pressed
        bindings.on_press.connect((id) => {
            open_pie(id);
        });
    }

    /////////////////////////////////////////////////////////////////////
    /// Opens the Pie with the given ID, if it exists.
    /////////////////////////////////////////////////////////////////////

    public static void open_pie(string id) {
        if (!a_pie_is_active) {
            Pie? pie = all_pies[id];

            if (pie != null) {

                a_pie_is_active = true;

                //change WM_CLASS so launchers can track windows properly
                Gdk.set_program_class("gnome-pie-" + id);

                var window = new PieWindow();
                window.load_pie(pie);

                window.on_closed.connect(() => {
                    opened_windows.remove(window);
                    if (opened_windows.size == 0) {
                        Icon.clear_cache();
                    }
                });

                window.on_closing.connect(() => {
                    window.get_center_pos(out last_x, out last_y);
                    a_pie_is_active = false;
                });

                opened_windows.add(window);

                window.open();

                //restore default WM_CLASS after window open
                Gdk.set_program_class("Gnome-pie");

            } else {
                warning("Failed to open pie with ID \"" + id + "\": ID does not exist!");
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Prints the names of all pies with their IDs.
    /////////////////////////////////////////////////////////////////////

    public static void print_ids() {
        foreach(var pie in all_pies.entries) {
            if (pie.value.id.length == 3) {
                message(pie.value.id + " " + pie.value.name);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the hotkey which the Pie with the given ID is bound to.
    /////////////////////////////////////////////////////////////////////

    public static string get_accelerator_of(string id) {
        return bindings.get_accelerator_of(id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns a human-readable version of the hotkey which the Pie
    /// with the given ID is bound to.
    /////////////////////////////////////////////////////////////////////

    public static string get_accelerator_label_of(string id) {
        return bindings.get_accelerator_label_of(id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Bind the Pie with the given ID to the given trigger.
    /////////////////////////////////////////////////////////////////////

    public static void bind_trigger(Trigger trigger, string id) {
        bindings.unbind(id);
        bindings.bind(trigger, id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns true if the pie with the given id is in turbo mode.
    /////////////////////////////////////////////////////////////////////

    public static bool get_is_turbo(string id) {
        return bindings.get_is_turbo(id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns true if the pie with the given id opens in the middle of
    /// the screen.
    /////////////////////////////////////////////////////////////////////

    public static bool get_is_centered(string id) {
        return bindings.get_is_centered(id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns true if the mouse pointer will be warped to the center of
    /// the pie.
    /////////////////////////////////////////////////////////////////////

    public static bool get_is_warp(string id) {
        return bindings.get_is_warp(id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns true if the pie with the given id is auto shaped
    /////////////////////////////////////////////////////////////////////

    public static bool get_is_auto_shape(string id) {
        return bindings.get_is_auto_shape(id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the prefered pie shape number
    /////////////////////////////////////////////////////////////////////

    public static int get_shape_number(string id) {
        return bindings.get_shape_number(id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the name of the Pie with the given ID.
    /////////////////////////////////////////////////////////////////////

    public static string get_name_of(string id) {
        Pie? pie = all_pies[id];
        if (pie == null) return "";
        else             return pie.name;
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the name ID of the Pie bound to the given Trigger.
    /// Returns "" if there is nothing bound to this trigger.
    /////////////////////////////////////////////////////////////////////

    public static string get_assigned_id(Trigger trigger) {
        return bindings.get_assigned_id(trigger);
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a new Pie which is displayed in the configuration dialog
    /// and gets saved.
    /////////////////////////////////////////////////////////////////////

    public static Pie create_persistent_pie(string name, string icon_name, Trigger? hotkey, string? desired_id = null) {
        Pie pie = create_pie(name, icon_name, 100, 999, desired_id);

        if (hotkey != null) bindings.bind(hotkey, pie.id);

        create_launcher(pie.id);

        return pie;
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a new Pie which is not displayed in the configuration
    /// dialog and is not saved.
    /////////////////////////////////////////////////////////////////////

    public static Pie create_dynamic_pie(string name, string icon_name, string? desired_id = null) {
        return create_pie(name, icon_name, 1000, 9999, desired_id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Adds a new Pie. Can't be accesd from outer scope. Use
    /// create_persistent_pie or create_dynamic_pie instead.
    /////////////////////////////////////////////////////////////////////

    private static Pie create_pie(string name, string icon_name, int min_id, int max_id, string? desired_id = null) {
         var random = new GLib.Rand();

        string final_id;

        if (desired_id == null)
            final_id = random.int_range(min_id, max_id).to_string();
        else {
            final_id = desired_id;
            final_id.canon("0123456789", '_');
            final_id = final_id.replace("_", "");

            int id = int.parse(final_id);

            if (id < min_id || id > max_id) {
                final_id = random.int_range(min_id, max_id).to_string();
                warning("The ID for pie \"" + name + "\" should be in range %u - %u! Using \"" + final_id + "\" instead of \"" + desired_id + "\"...", min_id, max_id);
            }
        }

        if (all_pies.has_key(final_id)) {
            var tmp = final_id;
            var id_number = int.parse(final_id) + 1;
            if (id_number == max_id+1) id_number = min_id;
            final_id = id_number.to_string();
            warning("Trying to add pie \"" + name + "\": ID \"" + tmp + "\" already exists! Using \"" + final_id + "\" instead...");
            return create_pie(name, icon_name, min_id, max_id, final_id);
        }

        Pie pie = new Pie(final_id, name, icon_name);
        all_pies.set(final_id, pie);

        return pie;
    }

    /////////////////////////////////////////////////////////////////////
    /// Removes the Pie with the given ID if it exists. Additionally it
    /// unbinds it's global hotkey.
    /////////////////////////////////////////////////////////////////////

    public static void remove_pie(string id) {
        if (all_pies.has_key(id)) {
            all_pies[id].on_remove();
            all_pies.unset(id);
            bindings.unbind(id);

            if (id.length == 3)
                remove_launcher(id);
        }
        else {
            warning("Failed to remove pie with ID \"" + id + "\": ID does not exist!");
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates a desktop file for which opens the Pie with given ID.
    /////////////////////////////////////////////////////////////////////

    public static void create_launcher(string id) {
        if (all_pies.has_key(id)) {
            Pie? pie = all_pies[id];

            string launcher_entry =
                "#!/usr/bin/env xdg-open\n" +
                "[Desktop Entry]\n" +
                "Name=%s\n".printf(pie.name) +
                "Exec=%s -o %s\n".printf(Paths.executable, pie.id) +
                "Encoding=UTF-8\n" +
                "Type=Application\n" +
                "Icon=%s\n".printf(pie.icon) +
                "StartupWMClass=gnome-pie-%s\n".printf(pie.id);

            // create the launcher file
            string launcher = Paths.launchers + "/%s.desktop".printf(pie.id);

            try {
                FileUtils.set_contents(launcher, launcher_entry);
                FileUtils.chmod(launcher, 0755);
            } catch (Error e) {
                warning(e.message);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Deletes the desktop file for the Pie with the given ID.
    /////////////////////////////////////////////////////////////////////

    private static void remove_launcher(string id) {
        string launcher = Paths.launchers + "/%s.desktop".printf(id);
        if (FileUtils.test(launcher, FileTest.EXISTS)) {
            FileUtils.remove(launcher);
        }
    }
}

}
