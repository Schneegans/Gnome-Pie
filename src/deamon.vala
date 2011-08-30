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
/// This class runs in the background. It has an Indicator sitting in the
/// user's panel. It initializes everything and guarantees that there is
/// only one instance of Gnome-Pie running.
/////////////////////////////////////////////////////////////////////////
	
public class Deamon : GLib.Application {

    /////////////////////////////////////////////////////////////////////
    /// The beginning of everything.
    /////////////////////////////////////////////////////////////////////

    public static int main(string[] args) {
        // create the Deamon and run it
        var deamon = new GnomePie.Deamon(args);
        deamon.run(args);
        
        return 0;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// The AppIndicator of Gnome-Pie.
    /////////////////////////////////////////////////////////////////////

    private Indicator indicator = null;
    
    
    /////////////////////////////////////////////////////////////////////
    /// Only true when the first instance of Gnome-Pie is launched.
    /////////////////////////////////////////////////////////////////////
    
    private bool need_init = true;


    /////////////////////////////////////////////////////////////////////
    /// C'tor of the Deamon. It checks whether it's the firts running
    /// instance of Gnome-Pie --- if so, start() is called, else the
    /// start() method of the running instance is called.
    /////////////////////////////////////////////////////////////////////

    public Deamon(string[] args) {
        GLib.Object(application_id : "org.gnome.gnomepie", 
                             flags : GLib.ApplicationFlags.HANDLES_COMMAND_LINE);
        // init gtk
        Gtk.init(ref args);

        this.command_line.connect(this.start);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// This method of the running instance is called when it is launched
    /// and everytime when another instance of Gnome-Pie is started.
    /////////////////////////////////////////////////////////////////////
    
    private int start(GLib.ApplicationCommandLine line) {
        // if this is called for the first instance
        if (this.need_init) {
            this.need_init = false;
            this.init();
            
            // check for flags
            this.evaluate_commandline(line, true);
		
		    // finished loading... so run the prog!
		    message("Started happily...");
		    Gtk.main();
		} else {
		     this.evaluate_commandline(line, false);
		}
		
		return 0;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Initializes everything which needs to be initialized.
    /////////////////////////////////////////////////////////////////////
    
    private void init() {
        // init toolkits and static stuff
        Logger.init();
        Paths.init();
        Gdk.threads_init();
        ActionRegistry.init();
        GroupRegistry.init();
        PieManager.init();
    
        // init locale support
        Intl.bindtextdomain ("gnomepie", Paths.locales);
        Intl.textdomain ("gnomepie");
        
        // launch the indicator
        this.indicator = new Indicator();

        // connect SigHandlers
        Posix.signal(Posix.SIGINT, sig_handler);
	    Posix.signal(Posix.SIGTERM, sig_handler);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Opens the desired Pie if one is passed by a flag. If not but an
    /// instance is already running, the preferences dialog is opened.
    /////////////////////////////////////////////////////////////////////
    
    private void evaluate_commandline(GLib.ApplicationCommandLine line, bool is_first_launch) {
        var args = line.get_arguments();
	    
	    if (args.length == 3) {
	        if (args[1] == "-o" || args[1] == "--open")
	            PieManager.open_pie(args[2]);
	        else
	            warning("Unknown flag \"" + args[1] + "\" passed!");
	    } else if (!is_first_launch) {
	        this.indicator.show_preferences();
	    }
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
