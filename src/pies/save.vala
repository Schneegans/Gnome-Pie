/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2021 Simon Schneegans
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
        message("Saving Pies to \"" + Paths.pie_config + "\".");

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
                int slice_count = 0;

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
                            writer.write_attribute("type", ActionRegistry.descriptions[action.get_type().name()].id);
                            if (ActionRegistry.descriptions[action.get_type().name()].icon_name_editable) {
                                writer.write_attribute("name", action.name);
                                writer.write_attribute("icon", action.icon);
                            }
                            writer.write_attribute("command", action.real_command);
                            writer.write_attribute("quickAction", action.is_quickaction ? "true" : "false");
                            writer.end_element();

                            ++ slice_count;
                        }
                    } else {
                        writer.start_element("group");
                            group.on_save(writer);
                        writer.end_element();

                        slice_count += group.actions.size;
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
