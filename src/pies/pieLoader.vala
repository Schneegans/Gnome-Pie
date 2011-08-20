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

// A helper class which loads pies according to the configuration file.
// It has got it's own class in order to keep other files clean.

public class PieLoader : GLib.Object {

    public void load_pies() {
        
        Xml.Parser.init();
        Xml.Doc* piesXML = Xml.Parser.parse_file(Paths.pie_config);
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
        string icon = "";
        string id = "";
        int quick_action = -1;
        
    
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
        
        if (id == "")
            id = name;
        
        var pie = PieManager.add_pie(id, out id, name, icon, hotkey, quick_action, true);
        
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
        
        ActionGroup group = null;

        switch (type) {
            case "app":
                Action action = new AppAction(name, icon, command);
                group = new ActionGroup(pie.id);
                group.add_action(action);
                break;
            case "key":
                Action action = new KeyAction(name, icon, command);
                group = new ActionGroup(pie.id);
                group.add_action(action);
                break;
            case "pie":
                Action action = new PieAction(command);
                group = new ActionGroup(pie.id);
                group.add_action(action);
                break;
            case "uri":
                Action action = new UriAction(name, icon, command);
                group = new ActionGroup(pie.id);
                group.add_action(action);
                break;
            case "menu":
                group = new MenuGroup(pie.id);
                break;
            case "bookmarks":
                group = new BookmarkGroup(pie.id);
                break;
            case "devices":
                group = new DevicesGroup(pie.id);
                break;
            default:
                warning("Invalid type \"" + type + "\" in pies.conf!");
                break;
        }
        
        
        if (group != null) pie.add_group(group);
    }
}

}
