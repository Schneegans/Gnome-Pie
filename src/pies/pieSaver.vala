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
                            writer.write_attribute("icon", pie.icon_name);
                            writer.write_attribute("hotkey", PieManager.get_accelerator_of(pie.id));
                            
                            foreach (var group in pie.action_groups) {
                                if (group is BookmarkGroup) {
                                    writer.start_element("group");
                                        writer.write_attribute("type", "bookmarks");
                                    writer.end_element();
                                } else if (group is DevicesGroup) {
                                    writer.start_element("group");
                                        writer.write_attribute("type", "devices");
                                    writer.end_element();
                                } else if (group is MenuGroup) {
                                    writer.start_element("group");
                                        writer.write_attribute("type", "menu");
                                    writer.end_element();
                                } else {
                                    writer.start_element("slice");
                                        foreach (var action in group.actions) {
                                            if (action is AppAction) {
                                                writer.write_attribute("type", "app");
                                                writer.write_attribute("name", action.name);
                                                writer.write_attribute("icon", action.icon_name);
                                                writer.write_attribute("command", ((AppAction)action).command);
                                                writer.write_attribute("quickAction", action.is_quick_action ? "true" : "false");
                                            } else if (action is KeyAction) {
                                                writer.write_attribute("type", "key");
                                                writer.write_attribute("name", action.name);
                                                writer.write_attribute("icon", action.icon_name);
                                                writer.write_attribute("command", ((KeyAction)action).key.accelerator);
                                                writer.write_attribute("quickAction", action.is_quick_action ? "true" : "false");
                                            } else if (action is PieAction) {
                                                writer.write_attribute("type", "pie");
                                                writer.write_attribute("command", ((PieAction)action).pie_id);
                                                writer.write_attribute("quickAction", action.is_quick_action ? "true" : "false");
                                            } else if (action is UriAction) {
                                                writer.write_attribute("type", "uri");
                                                writer.write_attribute("name", action.name);
                                                writer.write_attribute("icon", action.icon_name);
                                                writer.write_attribute("command", ((UriAction)action).uri);
                                                writer.write_attribute("quickAction", action.is_quick_action ? "true" : "false");
                                            } 
                                        }
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
