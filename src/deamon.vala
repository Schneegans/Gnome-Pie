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
	
    public class Deamon : GLib.Object {
    
        public static int main(string[] args) {
            Gtk.init (ref args);

            var deamon = new GnomePie.Deamon();
            deamon.run();
            
            return 0;
        }

        public Deamon() { 
        
            Logger.init();
        
            Intl.bindtextdomain ("gnomepie", "./locales");
            Intl.textdomain ("gnomepie");
            
            // append icon search path
            try {
                string path = GLib.Path.get_dirname(GLib.FileUtils.read_link("/proc/self/exe"))+"/icons/";
                Gtk.IconTheme.get_default().append_search_path(path);
            } catch (GLib.FileError e) {
                warning("Failed to get path of executable!");
            }
            
            var indicator = new Indicator();
            
            Settings.global.notify["show-indicator"].connect((s, p) => {
                indicator.active = Settings.global.show_indicator;
            });
            
            indicator.active = Settings.global.show_indicator;
            
            var manager = new PieManager();
	        manager.load_all();

            Posix.signal(Posix.SIGINT, sig_handler);
			Posix.signal(Posix.SIGTERM, sig_handler);
			
			message("Started happily...");
        }
        
        public void run() {
            Gtk.main();
        }
        
        private static void sig_handler(int sig) {
            stdout.printf("\n");
			message("Caught signal (%d), bye!".printf(sig));
			Gtk.main_quit();
		}

    }

}
