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
/// This class runs in the background. It has an Indicator sitting in the
/// user's panel. It initializes everything and guarantees that there is
/// only one instance of Gnome-Pie running.
/////////////////////////////////////////////////////////////////////////

public class Daemon : GLib.Application {

    /////////////////////////////////////////////////////////////////////
    /// The current version of Gnome-Pie.
    /////////////////////////////////////////////////////////////////////

    public static string version;

    /////////////////////////////////////////////////////////////////////
    /// Variables set by the command line parser.
    /////////////////////////////////////////////////////////////////////

    public static bool disable_header_bar     = false;
    public static bool disable_stack_switcher = false;


    /////////////////////////////////////////////////////////////////////
    /// true if init_pies() has been called already.
    /////////////////////////////////////////////////////////////////////
    private bool initialized = false;

    /////////////////////////////////////////////////////////////////////
    /// The beginning of everything.
    /////////////////////////////////////////////////////////////////////

    public static int main(string[] args) {
        version = "0.7.2";

        // try using X11/Xwayland display server by default
        GLib.Environment.set_variable("GDK_BACKEND", "x11", true);

        // disable overlay scrollbar --- hacky workaround for black /
        // transparent background
        GLib.Environment.set_variable("LIBOVERLAY_SCROLLBAR", "0", true);

        Wnck.set_client_type(Wnck.ClientType.PAGER);

        Logger.init();
        Gtk.init(ref args);
        var display = Gdk.Display.get_default();
        if (display is Gdk.X11.Display) {
            // 'x11' GDK backend is available, running with full support
            GLib.Environment.set_variable("GNOME_PIE_DISPLAY_SERVER", "x11", true);
        }
        else {
            // 'x11' GDK backend is NOT available, fallback to run on Wayland with limited support
            GLib.Environment.set_variable("GDK_BACKEND", "wayland", true);
            GLib.Environment.set_variable("GNOME_PIE_DISPLAY_SERVER", "wayland", true);
        }
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
    /// Variables set by the command line parser.
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

            if (GLib.Environment.get_variable("GNOME_PIE_DISPLAY_SERVER") != "wayland") {
                message("Using X11/Xwayland display server - running with full support.");
            }
            else {
                warning("Using Wayland display server - running with limited support.");
            }

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
