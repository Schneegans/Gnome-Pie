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

    // stores all pies
    public class PieManager : GLib.Object {
    
        private static Gee.HashMap<string, Pie?> all_pies;
	    
	    public PieManager() {}
	    
	    public void load_all() {
            all_pies = new Gee.HashMap<string, Pie?>();
            var loader = new PieLoader();
            loader.load_pies();
        }
        
        public void open_pie(string name) {
            var pie = all_pies[name];
	        
            if (pie == null) {
                warning("Can't open Pie named \"" + name + "\": No such Pie defined!");
            } else {
                pie.fade_in();
            }
        }
        
        public void add_pie(string name, Pie pie) {
            if (name in all_pies)
                warning("Failed to add pie \"" + name + "\": Name already exists!");
            else
                all_pies.set(name, pie);
        }
    }

}
