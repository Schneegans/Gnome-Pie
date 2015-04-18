/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2015 by Simon Schneegans
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// This class runs in the background. It has an Indicator sitting in the
/// user's panel. It initializes everything and guarantees that there is
/// only one instance of Gnome-Pie running.
/////////////////////////////////////////////////////////////////////////

public class Deamon : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// The current version of Gnome-Pie
    /////////////////////////////////////////////////////////////////////

    public static string version;

    /////////////////////////////////////////////////////////////////////
    /// The beginning of everything.
    /////////////////////////////////////////////////////////////////////

    public static int main(string[] args) {
        version = "0.6.1";

        Logger.init();
        Gtk.init(ref args);
        Paths.init();

        // create the Deamon and run it
        var deamon = new GnomePie.Deamon();
        deamon.run(args);

        return 0;
    }

    /////////////////////////////////////////////////////////////////////
    /// The AppIndicator of Gnome-Pie.
    /////////////////////////////////////////////////////////////////////

    private Indicator indicator = null;

    /////////////////////////////////////////////////////////////////////
    /// Varaibles set by the commend line parser.
    /////////////////////////////////////////////////////////////////////

    private static string open_pie = null;
    private static bool reset = false;

    /////////////////////////////////////////////////////////////////////
    /// Available command line options.
    /////////////////////////////////////////////////////////////////////

    private const GLib.OptionEntry[] options = {
        { "open", 'o', 0, GLib.OptionArg.STRING, out open_pie,
          "Open the Pie with the given ID", "ID" },
        { "reset", 'r', 0, GLib.OptionArg.NONE, out reset,
          "Reset all options to default values" },
        { null }
    };

    /////////////////////////////////////////////////////////////////////
    /// C'tor of the Deamon. It checks whether it's the firts running
    /// instance of Gnome-Pie.
    /////////////////////////////////////////////////////////////////////

    public void run(string[] args) {

        // create unique application
        var app = new GLib.Application("org.gnome.gnomepie", GLib.ApplicationFlags.HANDLES_COMMAND_LINE);

        app.command_line.connect((cmd) => {
            string[] tmp = cmd.get_arguments();
            unowned string[] remote_args = tmp;
            if (!handle_command_line(remote_args, true)) {
                Gtk.main_quit();
            }

            return 0;
        });

        app.startup.connect(() => {

            message("Welcome to Gnome-Pie " + version + "!");

            // init locale support
            Intl.bindtextdomain ("gnomepie", Paths.locales);
            Intl.textdomain ("gnomepie");

            // init toolkits and static stuff
            ActionRegistry.init();
            GroupRegistry.init();

            PieManager.init();
            Icon.init();

            // launch the indicator
            this.indicator = new Indicator();

            // connect SigHandlers
            Posix.signal(Posix.SIGINT, sig_handler);
            Posix.signal(Posix.SIGTERM, sig_handler);

            // finished loading... so run the prog!
            message("Started happily...");

            if (handle_command_line(args, false)) {
                Gtk.main();
            }
        });

        app.run(args);
    }

    /////////////////////////////////////////////////////////////////////
    /// Print a nifty message when the prog is killed.
    /////////////////////////////////////////////////////////////////////

    private static void sig_handler(int sig) {
        stdout.printf("\n");
        message("Caught signal (%d), bye!".printf(sig));
        Gtk.main_quit();
    }

    /////////////////////////////////////////////////////////////////////
    /// Handles command line parameters.
    /////////////////////////////////////////////////////////////////////

    private bool handle_command_line(string[] args, bool show_preferences) {
        // create command line options
        var context = new GLib.OptionContext("");
        context.set_help_enabled(true);
        context.add_main_entries(options, null);
        context.add_group(Gtk.get_option_group (false));

        try {
            context.parse(ref args);
        } catch(GLib.OptionError error) {
            warning(error.message);
        }

        if (reset) {
            if (GLib.FileUtils.remove(Paths.pie_config) == 0)
                message("Removed file \"%s\"", Paths.pie_config);
            if (GLib.FileUtils.remove(Paths.settings) == 0)
                message("Removed file \"%s\"", Paths.settings);

            return false;
        }

        if (open_pie != null && open_pie != "") {
            PieManager.open_pie(open_pie);
            open_pie = "";
        } else if (show_preferences) {
            this.indicator.show_preferences();
        }

        return true;
    }
}

}
