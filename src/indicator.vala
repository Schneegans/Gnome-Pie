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

    public class Indicator : GLib.Object {
    
        private AppIndicator.Indicator indicator {private get; private set;}
        
        public  bool active {
            get {
                return indicator.get_status() == AppIndicator.IndicatorStatus.ACTIVE;
            }
            set {
                if (value) indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
                else       indicator.set_status(AppIndicator.IndicatorStatus.PASSIVE);
            }
        }
        
        public Indicator(Gtk.Window prefs) {
            indicator = new AppIndicator.Indicator("Gnome-Pie", "indicator-applet", AppIndicator.IndicatorCategory.APPLICATION_STATUS);
            
            var menu = new Gtk.Menu();

            var item = new Gtk.ImageMenuItem.from_stock (Gtk.Stock.PREFERENCES, null);
            item.activate.connect(() => {
                prefs.show();
            });
            
            item.show();
            menu.append(item);

            item = new Gtk.ImageMenuItem.from_stock (Gtk.Stock.ABOUT, null);
            item.show();
            item.activate.connect(() => {
                var about = new GnomePieAboutDialog();
                about.run();
                about.destroy();
            });
            menu.append(item);
            
            var sepa = new Gtk.SeparatorMenuItem();
            sepa.show();
            menu.append(sepa);

            item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.QUIT, null);
            item.activate.connect(Gtk.main_quit);
            item.show();
            menu.append(item);

            indicator.set_menu(menu);
        }

    }
}
