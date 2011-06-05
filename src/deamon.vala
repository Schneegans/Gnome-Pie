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
    
        private KeybindingManager keys_;
        private AppIndicator.Indicator _indicator;
        
        private Ring ring_;
        
        private void showRing() {
            ring_.show();
            Utils.present_window(ring_);

	        Timeout.add ((uint)(1000.0/Utils.refresh_rate), () => {
	            ring_.queue_draw ();
	            return true;
	        });
        }

        public Deamon() {
            ring_ = new Ring();
            keys_ = new KeybindingManager();
            keys_.bind("<Alt>V", showRing);
            
            _indicator = new AppIndicator.Indicator("Gnome-Pie", "gnome-do-icon", AppIndicator.IndicatorCategory.APPLICATION_STATUS);
            
            _indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
            
            var menu = new Gtk.Menu();

            var item = new Gtk.MenuItem.with_label("Preferences...");
            item.activate.connect(() => {
                    debug("Preferences...");
            });
            item.show();
            menu.append(item);

            item = new Gtk.MenuItem.with_label("About...");
            item.show();
            item.activate.connect(() => {
                    debug("About...");
            });
            menu.append(item);

            _indicator.set_menu(menu);
        }
        
        public void run() {
            Gtk.main();
        }

    }

}
