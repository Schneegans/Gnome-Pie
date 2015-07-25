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

public class Deamon : GLib.Application {

    /////////////////////////////////////////////////////////////////////
    /// The current version of Gnome-Pie
    /////////////////////////////////////////////////////////////////////

    public static string version;

    /////////////////////////////////////////////////////////////////////
    /// Varaibles set by the commend line parser.
    /////////////////////////////////////////////////////////////////////

    public static bool header_bar = false;
    public static bool stack_switcher = false;

    /////////////////////////////////////////////////////////////////////
    /// The beginning of everything.
    /////////////////////////////////////////////////////////////////////

    public static int main(string[] args) {
        version = "0.6.2";

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
    private static bool print_ids = false;

    private static bool handled_local_args = false;

    /////////////////////////////////////////////////////////////////////
    /// Available command line options.
    /////////////////////////////////////////////////////////////////////

    private const GLib.OptionEntry[] options = {
        { "open", 'o', 0, GLib.OptionArg.STRING, out open_pie,
          "Open the Pie with the given ID", "ID" },
        { "reset", 'r', 0, GLib.OptionArg.NONE, out reset,
          "Reset all options to default values" },
        { "header-bar", 'b', 0, GLib.OptionArg.NONE, out header_bar,
          "Uses the new GTK.HeaderBar" },
        { "stack-switcher", 's', 0, GLib.OptionArg.NONE, out stack_switcher,
          "Uses the new GTK.StackSwitcher" },
        { "print-ids", 'p', 0, GLib.OptionArg.NONE, out print_ids,
          "Prints all Pie names with their according IDs" },
        { null }
    };

    /////////////////////////////////////////////////////////////////////
    /// C'tor of the Deamon. It checks whether it's the first running
    /// instance of Gnome-Pie.
    /////////////////////////////////////////////////////////////////////

    public Deamon() {

        GLib.Environment.set_variable("LIBOVERLAY_SCROLLBAR", "0", true);

        Object(application_id: "org.gnome.gnomepie",
               flags: GLib.ApplicationFlags.HANDLES_COMMAND_LINE);

        message("Welcome to Gnome-Pie " + version + "!");

        // init locale support
        Intl.bindtextdomain("gnomepie", Paths.locales);
        Intl.textdomain("gnomepie");

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

        this.startup.connect(()=>{
            // finished loading... so run the prog!
            message("Started happily...");
            hold();
        });
    }

    public override bool local_command_line(ref unowned string[] args, out int exit_status) {
        exit_status = 0;

        string*[] _args = new string[args.length];
        for (int i = 0; i < args.length; i++) {
            _args[i] = args[i];
        }
        return handle_command_line(_args, false);
    }

    public override int command_line(GLib.ApplicationCommandLine cmd) {
        if (handled_local_args) {
            string[] tmp = cmd.get_arguments();
            unowned string[] remote_args = tmp;
            handle_command_line(remote_args, true);
        }
        handled_local_args = true;
        return 0;
    }


    /////////////////////////////////////////////////////////////////////
    /// Print a nifty message when the prog is killed.
    /////////////////////////////////////////////////////////////////////

    private static void sig_handler(int sig) {
        stdout.printf("\n");
        message("Caught signal (%d), bye!".printf(sig));
        GLib.Application.get_default().release();
    }

    /////////////////////////////////////////////////////////////////////
    /// Handles command line parameters.
    /////////////////////////////////////////////////////////////////////

    private bool handle_command_line(string[] args, bool called_from_remote) {

        var context = new GLib.OptionContext(" - Launches the pie menu for linux.");
        context.add_main_entries(options, null);
        context.add_group(Gtk.get_option_group(false));

        try {
            context.parse(ref args);
        } catch(GLib.OptionError error) {
            warning(error.message);
            message("Run '%s' to launch Gnome-Pie or run '%s --help' to see a full list of available command line options.\n", args[0], args[0]);
        }

        if (reset) {
            if (GLib.FileUtils.remove(Paths.pie_config) == 0)
                message("Removed file \"%s\"", Paths.pie_config);
            if (GLib.FileUtils.remove(Paths.settings) == 0)
                message("Removed file \"%s\"", Paths.settings);

            return true;
        }

        if (open_pie != null && open_pie != "") {
            PieManager.open_pie(open_pie);
            open_pie = "";
        } else if (called_from_remote) {
            this.indicator.show_preferences();
        }

        if (print_ids) {
            PieManager.print_ids();
            print_ids = false;
            return true;
        }

        return false;
    }
}

}
