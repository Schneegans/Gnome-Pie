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

// A static class which stores all pies. It can be used to open pies.

public class PieManager : GLib.Object {

    private static Gee.HashMap<string, Pie?> all_pies;
    private static BindingManager bindings;
    
    public static void load_config() {
        all_pies = new Gee.HashMap<string, Pie?>();
        bindings = new BindingManager();
        
        var loader = new PieLoader();
        loader.load_pies();
        
        foreach (var pie in all_pies.entries)
            pie.value.on_all_loaded();
        
        bindings.on_press.connect((id) => {
            open_pie(id);
        });
    }
    
    public static Pie? get_pie(string id) {
        if (all_pies.has_key(id))
            return all_pies[id];

        return null;
    }
    
    public static void open_pie(string id) {
        if (all_pies.has_key(id)) {
            var window = new PieWindow();
            window.load_pie(all_pies[id]);
            window.open();
        } else {
            warning("Failed to open pie with ID \"" + id + "\": ID does not exist!");
        }
    }
    
    public static Pie add_pie(string desired_id, out string final_id, string name, string icon_name, string hotkey, int quick_action) {
        if (all_pies.has_key(desired_id)) {
            final_id = desired_id + "0";
            warning("Trying to add pie \"" + name + "\": ID \"" + desired_id + "\" already exists! Using \"" + final_id + "\" instead...");
            return add_pie(final_id, out final_id, name, icon_name, hotkey, quick_action);
        }

        final_id = desired_id;

        Pie pie = new Pie(desired_id, name, icon_name, quick_action);
        all_pies.set(desired_id, pie);
        
        if (hotkey != "")
            bindings.bind(hotkey, desired_id);
        
        return pie;
    }
    
    public static void remove_pie(string id) {
        if (all_pies.has_key(id)) {
            all_pies.remove(id);
            bindings.unbind(id);
        }
        else {
            warning("Failed to remove pie with ID \"" + id + "\": ID does not exist!");
        }
    }
}

}
