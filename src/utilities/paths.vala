/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2018 Simon Schneegans
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

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// A static class which stores all relevant paths used by Gnome-Pie.
/// These depend upon the location from which the program was launched.
/////////////////////////////////////////////////////////////////////////

public class Paths : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// The config directory,
    /// usually ~/.config/gnome-pie/.
    /////////////////////////////////////////////////////////////////////

    public static string config_directory { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// The log file,
    /// usually ~/.config/gnome-pie/gnome-pie.log.
    /////////////////////////////////////////////////////////////////////

    public static string log { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// The settings file,
    /// usually ~/.config/gnome-pie/gnome-pie.conf.
    /////////////////////////////////////////////////////////////////////

    public static string settings { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// The pie configuration file
    /// usually ~/.config/gnome-pie/pies.conf.
    /////////////////////////////////////////////////////////////////////

    public static string pie_config { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// The directory containing themes installed by the user
    /// usually ~/.config/gnome-pie/themes.
    /////////////////////////////////////////////////////////////////////

    public static string local_themes { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// The directory containing pre-installed themes
    /// usually /usr/share/gnome-pie/themes.
    /////////////////////////////////////////////////////////////////////

    public static string global_themes { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// The directory containing locale files
    /// usually /usr/share/locale.
    /////////////////////////////////////////////////////////////////////

    public static string locales { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// The directory containing UI declaration files
    /// usually /usr/share/gnome-pie/ui/.
    /////////////////////////////////////////////////////////////////////

    public static string ui_files { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// The autostart file of gnome-pie_config
    /// usually ~/.config/autostart/gnome-pie.desktop.
    /////////////////////////////////////////////////////////////////////

    public static string autostart { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// The path where all pie-launchers are stored
    /// usually ~/.config/gnome-pie/launchers.
    /////////////////////////////////////////////////////////////////////

    public static string launchers { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// The path to the executable.
    /////////////////////////////////////////////////////////////////////

    public static string executable { get; private set; default=""; }

    /////////////////////////////////////////////////////////////////////
    /// Deletes a directory recursively from disk. Use with care :)
    /////////////////////////////////////////////////////////////////////

    public static void delete_directory(string directory) {
        try {
            var d = Dir.open(directory);
            string name;
            while ((name = d.read_name()) != null) {
                string path = Path.build_filename(directory, name);
                if (FileUtils.test(path, FileTest.IS_DIR)) {
                    delete_directory(path);
                } else {
                    FileUtils.remove(path);
                }
            }
            DirUtils.remove(directory);
        } catch (Error e) {
            warning (e.message);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Initializes all values above.
    /////////////////////////////////////////////////////////////////////

    public static void init() {

        // get path of executable
        try {
            executable = GLib.File.new_for_path(GLib.FileUtils.read_link("/proc/self/exe")).get_path();
        } catch (GLib.FileError e) {
            warning("Failed to get path of executable!");
        }

        // append resources to icon search path to icon theme, if neccasary
        var icon_dir = GLib.File.new_for_path(GLib.Path.get_dirname(executable)).get_child("resources");

        if (icon_dir.query_exists()) {
            string path = icon_dir.get_path();
            Gtk.IconTheme.get_default().append_search_path(path);
        }

        Gtk.IconTheme.get_default().append_search_path(GLib.Environment.get_home_dir() + ".icons");

        // get global paths
        var default_dir = GLib.File.new_for_path("/usr/share/gnome-pie/");
        if(!default_dir.query_exists()) {
            default_dir = GLib.File.new_for_path("/usr/local/share/gnome-pie/");

            if(!default_dir.query_exists()) {
                default_dir = GLib.File.new_for_path(GLib.Path.get_dirname(
                    executable)).get_child("resources");
            }
        }

        global_themes = default_dir.get_path() + "/themes";
        ui_files = default_dir.get_path() + "/ui";

        // get locales path
        var locale_dir = GLib.File.new_for_path("/usr/share/locale/de/LC_MESSAGES/gnomepie.mo");
        if(locale_dir.query_exists()) {
            locale_dir = GLib.File.new_for_path("/usr/share/locale");
        } else {
            locale_dir = GLib.File.new_for_path("/usr/local/share/locale/de/LC_MESSAGES/gnomepie.mo");
            if(locale_dir.query_exists()) {
                locale_dir = GLib.File.new_for_path("/usr/local/share/locale");
            } else {
                locale_dir = GLib.File.new_for_path(GLib.Path.get_dirname(
                    executable)).get_child("resources/locale/de/LC_MESSAGES/gnomepie.mo");

                if(locale_dir.query_exists()) {
                    locale_dir = GLib.File.new_for_path(GLib.Path.get_dirname(
                        executable)).get_child("resources/locale");
                }
            }
        }

        locales = locale_dir.get_path();

        // get local paths
        var config_dir = GLib.File.new_for_path(
            GLib.Environment.get_user_config_dir()).get_child("gnome-pie");

        // create config_dir if neccasary
        if(!config_dir.query_exists()) {
            try {
                config_dir.make_directory();
            } catch (GLib.Error e) {
                error(e.message);
            }
        }

        config_directory = config_dir.get_path();

        // create local themes directory if neccasary
        var themes_dir = config_dir.get_child("themes");
        if(!themes_dir.query_exists()) {
            try {
                themes_dir.make_directory();
            } catch (GLib.Error e) {
                error(e.message);
            }
        }

        local_themes = themes_dir.get_path();

        // create launchers directory if neccasary
        var launchers_dir = config_dir.get_child("launchers");
        if(!launchers_dir.query_exists()) {
            try {
                launchers_dir.make_directory();
            } catch (GLib.Error e) {
                error(e.message);
            }
        }

        launchers = launchers_dir.get_path();

        // check for config file
        var config_file = config_dir.get_child("pies.conf");

        pie_config = config_file.get_path();
        settings = config_dir.get_path() + "/gnome-pie.conf";
        log = config_dir.get_path() + "/gnome-pie.log";

        if (!GLib.File.new_for_path(log).query_exists()) {
            try {
                FileUtils.set_contents(log, "");
            } catch (GLib.FileError e) {
                error(e.message);
            }
        }

        // autostart file name
        autostart = GLib.Path.build_filename(GLib.Environment.get_user_config_dir(),
                                             "autostart", "gnome-pie.desktop", null);

        // print results
        if (!GLib.File.new_for_path(pie_config).query_exists())
            warning("Failed to find pie configuration file \"pies.conf\"! (This should only happen when Gnome-Pie is started for the first time...)");

        if (!GLib.File.new_for_path(settings).query_exists())
            warning("Failed to find settings file \"gnome-pie.conf\"! (This should only happen when Gnome-Pie is started for the first time...)");

        if (!GLib.File.new_for_path(log).query_exists())
            warning("Failed to find log file \"gnome-pie.log\"!");

        if (!GLib.File.new_for_path(local_themes).query_exists())
            warning("Failed to find local themes directory!");

        if (!GLib.File.new_for_path(launchers).query_exists())
            warning("Failed to find launchers directory!");

        if (!GLib.File.new_for_path(global_themes).query_exists())
            warning("Failed to find global themes directory!");

        if (!GLib.File.new_for_path(ui_files).query_exists())
            warning("Failed to find UI files directory!");
    }
}

}
