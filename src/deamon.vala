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
    
        private KeybindingManager keys {private get; private set;}
        private Indicator indicator    {private get; private set;}
        private Ring ring              {private get; private set;}            

        public Deamon() {
            Rsvg.init();
            Settings.load();
        
            ring =      new Ring();
            indicator = new Indicator();
            keys =      new KeybindingManager();
            keys.bind("<Alt>V", show_ring);
            
            Posix.signal(Posix.SIGINT, sig_handler);
			Posix.signal(Posix.SIGTERM, sig_handler);
        }
        
        public void run() {
            Gtk.main();
        }
        
        private void show_ring() {
            ring.show();
        }
        
        private static void sig_handler(int sig) {
			stdout.printf("\nCaught signal (%d), bye!\n", sig);
			Gtk.main_quit();
		}

    }

}
