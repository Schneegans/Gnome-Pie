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

/////////////////////////////////////////////////////////////////////
/// TODO-List (need comments):
/// PieList
/////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////    
/// This class runs in the background. It has an Indicator sitting in the
/// user's panel. It initializes everything and guarantees that there is
/// only one instance of Gnome-Pie running.
/////////////////////////////////////////////////////////////////////////
	
public class Deamon : GLib.Object {
    
    /////////////////////////////////////////////////////////////////////
    /// The beginning of everything.
    /////////////////////////////////////////////////////////////////////

    public static int main(string[] args) {
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
        
        if (this.reset) {
            if (GLib.FileUtils.remove(Paths.pie_config) == 0)
                message("Removed file \"%s\"", Paths.pie_config);
            if (GLib.FileUtils.remove(Paths.settings) == 0)
                message("Removed file \"%s\"", Paths.settings);
            return;
        }
    
        // create unique application
        var app = new Unique.App("org.gnome.gnomepie", null);

        #if HAVE_GTK_3
            if (app.is_running()) {
        #else
            if (app.is_running) {
        #endif
            // inform the running instance of the pie to be opened
            if (open_pie != null) {
            	message("Gnome-Pie is already running. Sending request to open pie " + open_pie + ".");
                var data = new Unique.MessageData();
                data.set_text(open_pie, open_pie.length);
                app.send_message(Unique.Command.ACTIVATE, data);
                return;
            } 
           
            message("Gnome-Pie is already running. Sending request to open config menu.");
            app.send_message(Unique.Command.ACTIVATE, null);
            return;
        }
        
        // wait for incoming messages
        app.message_received.connect((cmd, data, event_time) => {
            if (cmd == Unique.Command.ACTIVATE) {
                var pie = data.get_text();
                
                if (pie != null && pie != "") PieManager.open_pie(pie);
                else                          this.indicator.show_preferences();

                return Unique.Response.OK;
            }

            return Unique.Response.PASSTHROUGH;
        });
    
        // init toolkits and static stuff
        Gdk.threads_init();
        
        // init locale support
        Intl.bindtextdomain ("gnomepie", Paths.locales);
        Intl.textdomain ("gnomepie");
        
        ActionRegistry.init();
        GroupRegistry.init();
        
        PieManager.init();
        Icon.init();
        ThemedIcon.init();
        RenderedText.init();
        
        // launch the indicator
        this.indicator = new Indicator();

        // connect SigHandlers
        Posix.signal(Posix.SIGINT, sig_handler);
	    Posix.signal(Posix.SIGTERM, sig_handler);
	
	    // finished loading... so run the prog!
	    message("Started happily...");
	    
	    // open pie if neccessary
	    if (open_pie != null) PieManager.open_pie(open_pie);
	    
	    Gtk.main();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Print a nifty message when the prog is killed.
    /////////////////////////////////////////////////////////////////////
    
    private static void sig_handler(int sig) {
        stdout.printf("\n");
		message("Caught signal (%d), bye!".printf(sig));
		Gtk.main_quit();
	}
}

}
