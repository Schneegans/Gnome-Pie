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

/////////////////////////////////////////////////////////////////////////    
/// A helper method which saves pies in a configuration file.
/////////////////////////////////////////////////////////////////////////

namespace Pies {

    /////////////////////////////////////////////////////////////////////
    /// Saves all Pies of the PieManager to the pies.conf file.
    /////////////////////////////////////////////////////////////////////
    
    public void save() {
        // initializes the XML-Writer
        var writer = new Xml.TextWriter.filename(Paths.pie_config);
        writer.set_indent(true);
        writer.start_document("1.0");
        writer.start_element("pies");
        
        // iterate through all Pies
        foreach (var pie_entry in PieManager.all_pies.entries) {
            var pie = pie_entry.value;
            
            // if it's no dynamically created Pie
            if (pie.id.length == 3) {
                // write all attributes of the Pie
                writer.start_element("pie");
                writer.write_attribute("name", pie.name);
                writer.write_attribute("id", pie.id);
                writer.write_attribute("icon", pie.icon);
                writer.write_attribute("hotkey", PieManager.get_accelerator_of(pie.id));
                
                // and all of it's Actions
                foreach (var group in pie.action_groups) {
                    // if it's a custom ActionGroup
                    if (group.get_type().depth() == 2) {
                        foreach (var action in group.actions) {
                            writer.start_element("slice");
                            writer.write_attribute("type", ActionRegistry.descriptions[action.get_type()].id);
                            if (ActionRegistry.descriptions[action.get_type()].icon_name_editable) {
                                writer.write_attribute("name", action.name);
                                writer.write_attribute("icon", action.icon);
                            }
                            writer.write_attribute("command", action.real_command);
                            writer.write_attribute("quickAction", action.is_quickaction ? "true" : "false");
                            writer.end_element();
                        }
                    } else {
                        writer.start_element("group");
                            writer.write_attribute("type", GroupRegistry.descriptions[group.get_type()].id);
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
