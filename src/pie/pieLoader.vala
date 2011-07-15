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

    public class PieLoader : GLib.Object {
    
        public void load_pies() {
            
            Xml.Parser.init();
            Xml.Doc* piesXML = Xml.Parser.parse_file("pies.conf");
            bool   error_occrured = false;
            
            if (piesXML != null) {

                Xml.Node* root = piesXML->get_root_element();
                if (root != null) {
                    for (Xml.Node* node = root->children; node != null; node = node->next) {
                        if (node->type == Xml.ElementType.ELEMENT_NODE) {
                            string node_name = node->name.down();
                            switch (node_name) {
                                case "pie":
                                    parse_pie(node);
                                    break;
                                case "plugin":
                                    parse_plugin(node);
                                    break;
                                default:
                                    warning("Invalid child element <" + node_name + "> in <pies> element pies.conf!");
                                    break;
                            } 
                        }
                    }
                   
                    Xml.Parser.cleanup();
                    
                } else {
                    warning("Error loading pies: pies.conf is empty! The cake is a lie...");
                    error_occrured = true;
                }
                
                delete piesXML;
                
            } else {
                warning("Error loading pies: pies.conf not found! The cake is a lie...");
                error_occrured = true;
            }
        }
        
        private void parse_pie(Xml.Node* node) {
            string hotkey = "";
            string name = "";
            int    quick_action = -1;
            
        
            for (Xml.Attr* attribute = node->properties; attribute != null; attribute = attribute->next) {
                string attr_name = attribute->name.down();
                string attr_content = attribute->children->content;
                
                switch (attr_name) {
                    case "hotkey":
                        hotkey = attr_content;
                        break;
                    case "quickaction":
                        quick_action = int.parse(attr_content);
                        break;
                    case "name":
                        name = attr_content;
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
            
            var pie = new Pie(hotkey, quick_action);
            
            for (Xml.Node* slice = node->children; slice != null; slice = slice->next) {
                if (slice->type == Xml.ElementType.ELEMENT_NODE) {
                    string node_name = slice->name.down();
                    switch (node_name) {
                        case "slice":
                            parse_slice(slice, pie);
                            break;
                        default:
                            warning("Invalid child element <" + node_name + "> in <pie> element in pies.conf!");
                            break;
                    } 
                }
            }
            
            var manager = new PieManager();
            manager.add_pie(name, pie);

        }
        
        private void parse_slice(Xml.Node* slice, Pie pie) {
            string name="";
            string icon="";
            string command="";
            string type="";
            
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
                    default:
                        warning("Invalid attribute \"" + attr_name + "\" in <slice> element in pies.conf!");
                        break;
                }
            }
            
            Action action=null;
            
            switch (type) {
                case "app":
                    action = new AppAction(name, icon, command);
                    break;
                case "key":
                    action = new KeyAction(name, icon, command);
                    break;
                case "pie":
                    action = new PieAction(name, icon, command);
                    break;
                default:
                    warning("Invalid type \"" + type + "\" in pies.conf!");
                    break;
            }
            
            if (action != null) pie.add_slice(action);
        }
        
        private void parse_plugin(Xml.Node* slice) {
            string type="";
            string hotkey = "";
            string name = "";
        
            for (Xml.Attr* attribute = slice->properties; attribute != null; attribute = attribute->next) {
                string attr_name = attribute->name.down();
                string attr_content = attribute->children->content;

                switch (attr_name) {
                    case "type":
                        type = attr_content;
                        break;
                    case "hotkey":
                        hotkey = attr_content;
                        break;
                    case "name":
                        name = attr_content;
                        break;
                    default:
                        warning("Invalid attribute \"" + attr_name + "\" in <plugin> element in pies.conf!");
                        break;
                }
            }
            
            switch(type) {
                case "menu":
                    Plugins.Menu.create(name, hotkey);
                    break;
                case "bookmarks":
                    Plugins.Bookmarks.create(name, hotkey);
                    break;
                default:
                    warning("Invalid type option \"" + type + "\" in <plugin> element in pies.conf!");
                    break;
            }
        }
    }
}
