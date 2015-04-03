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

/////////////////////////////////////////////////////////////////////////
/// A singleton class for storing global settings. These settings can
/// be loaded from and saved to an XML file.
/////////////////////////////////////////////////////////////////////////

public class Config : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// The singleton instance of this class.
    /////////////////////////////////////////////////////////////////////

    private static Config _instance = null;

    /////////////////////////////////////////////////////////////////////
    /// Returns the singleton instance.
    /////////////////////////////////////////////////////////////////////

    public static Config global {
        get {
            if (_instance == null) {
                _instance = new Config();
                _instance.load();
            }
            return _instance;
        }
        private set {
            _instance = value;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// All settings variables.
    /////////////////////////////////////////////////////////////////////

    public Theme theme { get; set; }
    public double refresh_rate { get; set; default = 60.0; }
    public double global_scale { get; set; default = 1.0; }
    public int  activation_range { get; set; default = 200; }
    public int  max_visible_slices { get; set; default = 24; }
    public bool show_indicator { get; set; default = true; }
    public bool show_captions { get; set; default = true; }
    public bool auto_start { get; set; default = false; }
    public int showed_news { get; set; default = 0; }
    public Gee.ArrayList<Theme?> themes { get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Saves all above variables to a file.
    /////////////////////////////////////////////////////////////////////

    public void save() {
        var writer = new Xml.TextWriter.filename(Paths.settings);
        writer.start_document("1.0");
            writer.start_element("settings");
                writer.write_attribute("theme", theme.name);
                writer.write_attribute("refresh_rate", refresh_rate.to_string());
                writer.write_attribute("global_scale", global_scale.to_string());
                writer.write_attribute("activation_range", activation_range.to_string());
                writer.write_attribute("max_visible_slices", max_visible_slices.to_string());
                writer.write_attribute("show_indicator", show_indicator ? "true" : "false");
                writer.write_attribute("show_captions", show_captions ? "true" : "false");
                writer.write_attribute("showed_news", showed_news.to_string());
            writer.end_element();
        writer.end_document();
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads all settings variables from a file.
    /////////////////////////////////////////////////////////////////////

    private void load() {

        // check for auto_start filename
        this.auto_start = FileUtils.test(Paths.autostart, FileTest.EXISTS);

        // parse the settings file
        Xml.Parser.init();
        Xml.Doc* settingsXML = Xml.Parser.parse_file(Paths.settings);
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
                        case "activation_range":
                            activation_range = int.parse(attr_content);
                            activation_range.clamp(0, 2000);
                            break;
                        case "max_visible_slices":
                            max_visible_slices = int.parse(attr_content);
                            max_visible_slices.clamp(10, 2000);
                            break;
                        case "show_indicator":
                            show_indicator = bool.parse(attr_content);
                            break;
                        case "show_captions":
                            show_captions = bool.parse(attr_content);
                            break;
                        case "showed_news":
                            showed_news = int.parse(attr_content);
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

    /////////////////////////////////////////////////////////////////////
    /// Registers all themes in the user's and in the global
    /// theme directory.
    /////////////////////////////////////////////////////////////////////

    public void load_themes(string current) {
        themes = new Gee.ArrayList<Theme?>();
        try {
            string name;

            // load global themes
            var d = Dir.open(Paths.global_themes);
            while ((name = d.read_name()) != null) {
                var theme = new Theme(Paths.global_themes + "/" + name);

                if (theme.load())
                    themes.add(theme);
            }

            // load local themes
            d = Dir.open(Paths.local_themes);
            while ((name = d.read_name()) != null) {
                var theme = new Theme(Paths.local_themes + "/" + name);
                if (theme.load())
                    themes.add(theme);
            }

        } catch (Error e) {
            warning (e.message);
        }

        if (themes.size > 0) {
            if (current == "") {
                current = "Unity";
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
            theme.load_images();
        }
        else error("No theme found!");
    }

}

}
