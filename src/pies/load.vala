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

using GLib.Math;

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// A helper method which loads pies according to the configuration file.
/////////////////////////////////////////////////////////////////////////

namespace Pies {

    /////////////////////////////////////////////////////////////////////
    /// Loads all Pies from the pies.conf file.
    /////////////////////////////////////////////////////////////////////

    public void load() {
        // check whether the config file exists
        if (!GLib.File.new_for_path(Paths.pie_config).query_exists()) {
            message("Creating new configuration file in \"" + Paths.pie_config + "\".");
            Pies.create_default_config();
            return;
        }

        message("Loading Pies from \"" + Paths.pie_config + "\".");

        // load the settings file
        Xml.Parser.init();
        Xml.Doc* piesXML = Xml.Parser.parse_file(Paths.pie_config);

        if (piesXML != null) {
            // begin parsing at the root element
            Xml.Node* root = piesXML->get_root_element();
            if (root != null) {
                for (Xml.Node* node = root->children; node != null; node = node->next) {
                    if (node->type == Xml.ElementType.ELEMENT_NODE) {
                        string node_name = node->name.down();
                        switch (node_name) {
                            case "pie":
                                parse_pie(node);
                                break;
                            default:
                                warning("Invalid child element <" + node_name + "> in <pies> element pies.conf!");
                                break;
                        }
                    }
                }
            } else {
                warning("Error loading pies: pies.conf is empty! The cake is a lie...");
            }

            delete piesXML;

        } else {
            warning("Error loading pies: pies.conf not found! The cake is a lie...");
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Parses a <pie> element from the pies.conf file.
    /////////////////////////////////////////////////////////////////////

    private static void parse_pie(Xml.Node* node) {
        string hotkey = "";
        string name = "";
        string icon = "";
        string id = "";
        int quickaction = -1;

        // parse all attributes of this node
        for (Xml.Attr* attribute = node->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;

            switch (attr_name) {
                case "hotkey":
                    hotkey = attr_content;
                    break;
                case "quickaction":
                    quickaction = int.parse(attr_content);
                    break;
                case "name":
                    name = attr_content;
                    break;
                case "icon":
                    icon = attr_content;
                    break;
                case "id":
                    id = attr_content;
                    break;
                default:
                    warning("Invalid setting \"" + attr_name + "\" in pies.conf!");
                    break;
            }
        }

        if (name == "") {
            warning("Invalid <pie> element in pies.conf: No name specified!");
            return;
        }

        // add a new Pie with the loaded properties
        var pie = PieManager.create_persistent_pie(name, icon, new Trigger.from_string(hotkey), id);

        // and parse all child elements
        for (Xml.Node* slice = node->children; slice != null; slice = slice->next) {
            if (slice->type == Xml.ElementType.ELEMENT_NODE) {
                string node_name = slice->name.down();
                switch (node_name) {
                    case "slice":
                        parse_slice(slice, pie);
                        break;
                    case "group":
                        parse_group(slice, pie);
                        break;
                    default:
                        warning("Invalid child element <" + node_name + "> in <pie> element in pies.conf!");
                        break;
                }
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Parses a <slice> element from the pies.conf file.
    /////////////////////////////////////////////////////////////////////

    private static void parse_slice(Xml.Node* slice, Pie pie) {
        string name="";
        string icon="";
        string command="";
        string type="";
        bool quickaction = false;

        // parse all attributes of this node
        for (Xml.Attr* attribute = slice->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;

            switch (attr_name) {
                case "name":
                    name = attr_content;
                    break;
                case "icon":
                    icon = attr_content;
                    break;
                case "command":
                    command = attr_content;
                    break;
                case "type":
                    type = attr_content;
                    break;
                case "quickaction":
                    quickaction = bool.parse(attr_content);
                    break;
                default:
                    warning("Invalid attribute \"" + attr_name + "\" in <slice> element in pies.conf!");
                    break;
            }
        }

        // create a new Action according to the loaded type
        Action action = ActionRegistry.create_action(type, name, icon, command, quickaction);

        if (action != null) pie.add_action(action);
    }

    /////////////////////////////////////////////////////////////////////
    /// Parses a <group> element from the pies.conf file.
    /////////////////////////////////////////////////////////////////////

    private static void parse_group(Xml.Node* slice, Pie pie) {
        string type="";

        // parse all attributes of this node
        for (Xml.Attr* attribute = slice->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;

            if (attr_name == "type") {
                type = attr_content;
                break;
            }
        }

        ActionGroup group = GroupRegistry.create_group(type, pie.id);

        if (group != null) {
            group.on_load(slice);
            pie.add_group(group);
        }
    }
}

}
