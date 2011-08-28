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

using GLib.Math;

namespace GnomePie {

// A helper class which saves pies in a configuration file.
// It has got it's own class in order to keep other files clean.

public class PieSaver : GLib.Object {

    public static void save_pies() {
        var writer = new Xml.TextWriter.filename(Paths.pie_config);
        writer.set_indent(true);
        writer.start_document("1.0");
        writer.start_element("pies");
            
        foreach (var pie_entry in PieManager.all_pies.entries) {
            var pie = pie_entry.value;
            if (pie.is_custom) {
                writer.start_element("pie");
                writer.write_attribute("name", pie.name);
                writer.write_attribute("id", pie.id);
                writer.write_attribute("icon", pie.icon);
                writer.write_attribute("hotkey", PieManager.get_accelerator_of(pie.id));
                
                foreach (var group in pie.action_groups) {
                    // if it's a custom ActionGroup
                    if (group.get_type().depth() == 2) {
                        foreach (var action in group.actions) {
                            writer.start_element("slice");
                            writer.write_attribute("type", ActionRegistry.settings_names[action.get_type()]);
                            if (ActionRegistry.icon_name_editables[action.get_type()]) {
                                writer.write_attribute("name", action.name);
                                writer.write_attribute("icon", action.icon);
                            }
                            writer.write_attribute("command", action.real_command);
                            writer.write_attribute("quickAction", action.is_quick_action ? "true" : "false");
                            writer.end_element();
                        }
                    } else {
                        writer.start_element("group");
                            writer.write_attribute("type", GroupRegistry.settings_names[group.get_type()]);
                        writer.end_element();
                    }
                }
                writer.end_element();
            }
        }
        writer.end_element();
        writer.end_document();
    }
}

}
