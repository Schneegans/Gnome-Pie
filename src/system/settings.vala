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

    public class Settings : GLib.Object {
    
        private static Settings _get = null;
        
        public static Settings global {
            get {
                if (_get == null) {
                    _get = new Settings();
                    _get.load();
                }
                return _get;
            }
            private set {
                _get = value;
            }
        }

        public Theme  theme             {get; set;}
        public double refresh_rate      {get; private set; default = 60.0;}
        public double frame_time        {get; set; default = 0.1;}
        public double global_scale      {get; set; default = 1.0;}
        public bool   show_indicator    {get; set; default = true;}
        public bool   open_at_mouse     {get; set; default = true;}
        public bool   click_to_activate {get; set; default = true;}
        
        public Gee.ArrayList<Theme?> themes {get; private set;}
        
        public void save() {
            var writer = new Xml.TextWriter.filename("gnome-pie.conf");
            writer.start_document("1.0");
                writer.start_element("settings");
                    writer.write_attribute("theme", theme.name);
                    writer.write_attribute("refresh_rate", refresh_rate.to_string());
                    writer.write_attribute("global_scale", global_scale.to_string());
                    writer.write_attribute("show_indicator", show_indicator ? "true" : "false");
                    writer.write_attribute("open_at_mouse", open_at_mouse ? "true" : "false");
                    writer.write_attribute("click_to_activate", click_to_activate ? "true" : "false");
                writer.end_element();
            writer.end_document();
        }
        
        private void load() {
            Xml.Parser.init();
            Xml.Doc* settingsXML = Xml.Parser.parse_file("gnome-pie.conf");
            bool   error_occrured = false;
            string theme_name = "";
            
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
                            case "global_scale":
                                global_scale = double.parse(attr_content);
                                global_scale.clamp(0.5, 2.0);
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
            
            load_themes(theme_name);

            if (error_occrured) save();
        }
        
        public void load_themes(string current) {
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
                if (current == "") {
                    current = "O-Pie";
                    warning("No theme specified! Using default...");
                }
                foreach (var t in themes) {
                    if (t.name == current) {
                        theme = t;
                        break;
                    }
                }
                if (theme == null) {
                    theme = themes[0];
                    warning("Theme \"" + current + "\" not found! Using fallback...");
                }
            }
            else error("No theme found!");
        }
        
    }
}
