/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2017 by Simon Schneegans
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

public class Daemon : GLib.Application {

    /////////////////////////////////////////////////////////////////////
    /// The current version of Gnome-Pie
    /////////////////////////////////////////////////////////////////////

    public static string version;

    /////////////////////////////////////////////////////////////////////
    /// Varaibles set by the commend line parser.
    /////////////////////////////////////////////////////////////////////

    public static bool disable_header_bar     = false;
    public static bool disable_stack_switcher = false;


    /////////////////////////////////////////////////////////////////////
    /// true if init_pies() has been called already
    /////////////////////////////////////////////////////////////////////
    private bool initialized = false;

    /////////////////////////////////////////////////////////////////////
    /// The beginning of everything.
    /////////////////////////////////////////////////////////////////////

    public static int main(string[] args) {
        version = "0.7.1";

        // disable overlay scrollbar --- hacky workaround for black /
        // transparent background
        GLib.Environment.set_variable("LIBOVERLAY_SCROLLBAR", "0", true);

        Wnck.set_client_type(Wnck.ClientType.PAGER);

        Logger.init();
        Gtk.init(ref args);
        Paths.init();

        // create the Daemon and run it
        var deamon = new GnomePie.Daemon();
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
        { "open", 'o', 0, GLib.OptionArg.STRING,
          out open_pie,
          "Open the Pie with the given ID", "ID" },
        { "reset", 'r', 0, GLib.OptionArg.NONE,
          out reset,
          "Reset all options to default values" },
        { "no-header-bar", 'b', 0, GLib.OptionArg.NONE,
          out disable_header_bar,
          "Disables the usage of GTK.HeaderBar" },
        { "no-stack-switcher", 's', 0, GLib.OptionArg.NONE,
          out disable_stack_switcher,
          "Disables the usage of GTK.StackSwitcher" },
        { "print-ids", 'p', 0, GLib.OptionArg.NONE,
          out print_ids,
          "Prints all Pie names with their according IDs" },
        { null }
    };

    /////////////////////////////////////////////////////////////////////
    /// C'tor of the Daemon. It checks whether it's the first running
    /// instance of Gnome-Pie.
    /////////////////////////////////////////////////////////////////////

    public Daemon() {
        Object(application_id: "org.gnome.gnomepie",
               flags: GLib.ApplicationFlags.HANDLES_COMMAND_LINE);

        // init locale support
        Intl.bindtextdomain("gnomepie", Paths.locales);
        Intl.textdomain("gnomepie");

        // connect SigHandlers
#if VALA_0_40
        Posix.signal(Posix.Signal.INT, sig_handler);
        Posix.signal(Posix.Signal.TERM, sig_handler);
#else
        Posix.signal(Posix.SIGINT, sig_handler);
        Posix.signal(Posix.SIGTERM, sig_handler);
#endif

        this.startup.connect(()=>{

            message("Welcome to Gnome-Pie " + version + "!");

            this.init_pies();

            // launch the indicator
            this.indicator = new Indicator();

            if (open_pie != null && open_pie != "") {
                PieManager.open_pie(open_pie);
                open_pie = "";
            }

            // finished loading... so run the prog!
            message("Started happily...");
            hold();
        });
    }

    /////////////////////////////////////////////////////////////////////
    /// Call handle_command_line on program launch.
    /////////////////////////////////////////////////////////////////////

    protected override bool local_command_line(
        ref unowned string[] args, out int exit_status) {

        exit_status = 0;

        // copy command line
        string*[] _args = new string[args.length];
        for (int i = 0; i < args.length; i++) {
            _args[i] = args[i];
        }
        return handle_command_line(_args, false);
    }

    /////////////////////////////////////////////////////////////////////
    /// Call handle_command_line when a remote instance was launched.
    /////////////////////////////////////////////////////////////////////

    protected override int command_line(GLib.ApplicationCommandLine cmd) {
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
    /// Print a nifty message when the prog is killed.
    /////////////////////////////////////////////////////////////////////

    private void init_pies() {
        if (!this.initialized) {

            // init static stuff
            ActionRegistry.init();
            GroupRegistry.init();

            // load all pies
            PieManager.init();

            // initialize icon cache
            Icon.init();

            this.initialized = true;
        }
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
            message("Run '%s' to launch Gnome-Pie or run '%s --help' to" +
                    " see a full list of available command line options.\n",
                    args[0], args[0]);
        }

        if (reset) {
            if (GLib.FileUtils.remove(Paths.pie_config) == 0) {
                message("Removed file \"%s\"", Paths.pie_config);
            }
            if (GLib.FileUtils.remove(Paths.settings) == 0) {
                message("Removed file \"%s\"", Paths.settings);
            }

            // do not notify the already running instance (if any)
            return true;
        }

        if (print_ids) {
            this.init_pies();
            PieManager.print_ids();
            print_ids = false;

            // do not notify the already running instance (if any)
            return true;
        }


        if (called_from_remote) {
            if (open_pie != null && open_pie != "") {
                PieManager.open_pie(open_pie);
                open_pie = "";
            } else {
                this.indicator.show_preferences();
            }
        }

        // notify the already running instance (if any)
        return false;
    }
}

}
