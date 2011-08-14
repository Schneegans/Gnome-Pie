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
	
    public class Deamon : GLib.Application {
    
        private Indicator indicator = null;
    
        public static int main(string[] args) {
        
            var deamon = new GnomePie.Deamon(args);
            deamon.run(args);
            
            return 0;
        }

        public Deamon(string[] args) {
            Gtk.init(ref args);
        
            GLib.Object(application_id : "org.gnome.gnomepie", 
                        flags : GLib.ApplicationFlags.FLAGS_NONE);
            
            this.activate.connect(this.start);
        }
        
        private void start() {
        
            if (this.indicator == null) {
            
                Plugins.Bookmarks.get_bookmarks();
            
                // init toolkits and static stuff
                Logger.init();
                Paths.init();
                Gdk.threads_init();
                
                // check for thread support
                if (!Thread.supported()) {
                    error("Cannot run without thread support.");
                }
            
                // init locale support
                Intl.bindtextdomain ("gnomepie", Paths.locales);
                Intl.textdomain ("gnomepie");
                
                // append icon search path to icon theme
                try {
                    string path = GLib.Path.get_dirname(GLib.FileUtils.read_link("/proc/self/exe"))+"/ressources/";
                    Gtk.IconTheme.get_default().append_search_path(path);
                    Gtk.IconTheme.get_default().append_search_path("/usr/share/pixmaps/");
                } catch (GLib.FileError e) {
                    warning("Failed to get path of executable!");
                }
                
                // launch the indicator
                indicator = new Indicator();

                // load all Pies
                var manager = new PieManager();
	            manager.load_all();

                // connect SigHandlers
                Posix.signal(Posix.SIGINT, sig_handler);
			    Posix.signal(Posix.SIGTERM, sig_handler);
			
			    // finished loading!
			    message("Started happily...");
			
			    Gtk.main();
			    
			} else {
			    this.indicator.show_preferences();
			}
        }
        
        private static void sig_handler(int sig) {
            stdout.printf("\n");
			message("Caught signal (%d), bye!".printf(sig));
			Gtk.main_quit();
		}
    }

}
