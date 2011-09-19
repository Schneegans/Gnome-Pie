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
    /// Stores all global hotkeys.
    /////////////////////////////////////////////////////////////////////
    
    private static BindingManager bindings;
    
    /////////////////////////////////////////////////////////////////////
    /// Initializes all Pies. They are loaded from the pies.conf file.
    /////////////////////////////////////////////////////////////////////
    
    public static void init() {
        all_pies = new Gee.HashMap<string, Pie?>();
        bindings = new BindingManager();
        
        // load all Pies from th pies.conf file
        PieLoader.load_pies();
        
        // open the according pie if it's hotkey is pressed
        bindings.on_press.connect((id) => {
            open_pie(id);
        });
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Opens the Pie with the given ID, if it exists.
    /////////////////////////////////////////////////////////////////////
    
    public static void open_pie(string id) {
        Pie? pie = all_pies[id];
        
        if (pie != null) {
            var window = new PieWindow();
            window.load_pie(pie);
            window.open();
        } else {
            warning("Failed to open pie with ID \"" + id + "\": ID does not exist!");
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
    /// Returns the name of the Pie with the given ID.
    /////////////////////////////////////////////////////////////////////
    
    public static string get_name_of(string id) {
        Pie? pie = all_pies[id];
        if (pie == null) return "";
        else             return pie.name;
    }
    
    public static Pie create_persistent_pie(string name, string icon_name, string hotkey, string? desired_id = null) {
        
        var random = new GLib.Rand();
        
        string final_id;
        
        if (desired_id == null) final_id = random.int_range(100, 999).to_string();
        else                    final_id = desired_id;
        
        final_id.canon("0123456789", '_');
        final_id = final_id.replace("_", "");
        
        if (desired_id != null && final_id.length != 3) {
            final_id = random.int_range(100, 999).to_string();
            warning("A static ID should be a three digit number! Using \"" + final_id + "\" instead of \"" + desired_id + "\" for static pie \"" + name + "\"...");
        }
    
        if (all_pies.has_key(final_id)) {
            var tmp = final_id;
            var id_number = int.parse(final_id) + 1;
            if (id_number == 1000) id_number = 100;
            final_id = id_number.to_string();
            warning("Trying to add static pie \"" + name + "\": ID \"" + tmp + "\" already exists! Using \"" + final_id + "\" instead...");
            return create_persistent_pie(name, icon_name, hotkey, final_id);
        }

        Pie pie = new Pie(final_id, name, icon_name);
        all_pies.set(final_id, pie);
        
        if (hotkey != "")
            bindings.bind(hotkey, final_id);
        
        return pie;
    }
    
    public static Pie create_dynamic_pie(string name, string icon_name, string? desired_id = null) {
        
        var random = new GLib.Rand();
        
        string final_id;
        
        if (desired_id == null) final_id = random.int_range(1000, 9999).to_string();
        else                    final_id = desired_id;
        
        final_id.canon("0123456789", '_');
        final_id = final_id.replace("_", "");
        
        if (desired_id != null && final_id.length != 4) {
            final_id = random.int_range(1000, 9999).to_string();
            warning("A dynamic ID should be a four digit number! Using \"" + final_id + "\" instead of \"" + desired_id + "\" for dynamic pie \"" + name + "\"...");
        }
    
        if (all_pies.has_key(final_id)) {
            var tmp = final_id;
            var id_number = int.parse(final_id) + 1;
            if (id_number == 10000) id_number = 1000;
            final_id = id_number.to_string();
            warning("Trying to add dynamic pie \"" + name + "\": ID \"" + tmp + "\" already exists! Using \"" + final_id + "\" instead...");
            return create_dynamic_pie(name, icon_name, final_id);
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
        }
        else {
            warning("Failed to remove pie with ID \"" + id + "\": ID does not exist!");
        }
    }
}

}
