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

    namespace Settings {
    
        private SettingsInstance instance = null;
    
        public SettingsInstance setting() {
            if (instance == null)
                instance = new SettingsInstance(); 
            return instance;
        }
        
        public class SettingsInstance : GLib.Object {
    
            public Theme  theme             {get; set;}
            public double refresh_rate      {get; private set; default = 60.0;}
            public bool   show_indicator    {get; set; default = true;}
            public bool   open_at_mouse     {get; set; default = true;}
            public bool   click_to_activate {get; set; default = true;}
            
            public Gee.ArrayList<Theme?> themes {get; private set;}

            public SettingsInstance() {
                load();
            }
            
            public void save() {
                var writer = new Xml.TextWriter.filename("gnome-pie.conf");
                writer.start_document("1.0");
                    writer.start_element("settings");
                        writer.write_attribute("theme", theme.name);
                        writer.write_attribute("refresh_rate", refresh_rate.to_string());
                        writer.write_attribute("show_indicator", show_indicator ? "true" : "false");
                        writer.write_attribute("open_at_mouse", open_at_mouse ? "true" : "false");
                        writer.write_attribute("click_to_activate", click_to_activate ? "true" : "false");
                    writer.end_element();
                writer.end_document();
            }
            
            public void load() {
                Xml.Parser.init();
                Xml.Doc* settingsXML = Xml.Parser.parse_file("gnome-pie.conf");
                string theme_name = "";
                bool   error_occrured = false;
                
                if (settingsXML != null) {

                    Xml.Node* root = settingsXML->get_root_element();
                    if (root != null) {

                        for (Xml.Attr* attribute = root->properties; attribute != null; attribute = attribute->next) {
                            string attr_name = attribute->name.down();
                            string attr_content = attribute->children->content;
                            
                            switch (attr_name) {
                                case "theme":
                                    theme_name = attr_content;
                                    break;
                                case "refresh_rate":
                                    refresh_rate = double.parse(attr_content);
                                    break;
                                case "show_indicator":
                                    show_indicator = bool.parse(attr_content);
                                    break;
                                case "open_at_mouse":
                                    open_at_mouse = bool.parse(attr_content);
                                    break;
                                case "click_to_activate":
                                    click_to_activate = bool.parse(attr_content);
                                    break;
                                default:
                                    warning("Invalid setting \"" + attr_name + "\" in gnome-pie.conf!");
                                    break;
                            }
                        }
                       
                        Xml.Parser.cleanup();
                        
                    } else {
                        warning("Error loading settings: gnome-pie.conf is empty! Using defaults...");
                        error_occrured = true;
                    }
                    
                    delete settingsXML;
                    
                } else {
                    warning("Error loading settings: gnome-pie.conf not found! Using defaults...");
                    error_occrured = true;
                }
                
                themes = new Gee.ArrayList<Theme?>();
                try {
                    string name;
                    var d = Dir.open("themes/");
                    while ((name = d.read_name()) != null) {
                        var theme = new Theme(name);
                        if (theme != null)
                            themes.add(theme);
                    }
                } catch (Error e) {
		            warning (e.message);
	            } 
                
                if (themes.size > 0) {
                    if (theme_name == "") {
                        theme_name = "O-Pie";
                        warning("No theme specified! Using default...");
                    }
                    foreach (var t in themes) {
                        if (t.name == theme_name) {
                            theme = t;
                            break;
                        }
                    }
                    if (theme == null) {
                        theme = themes[0];
                        warning("Theme \"" + theme_name + "\" not found! Using fallback...");
                    }
                }
                else error("No theme found!");
                
                if (error_occrured) save();
            }
        }
    }
   
}
