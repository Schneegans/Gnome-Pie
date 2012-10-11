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

[DBus (name = "org.openpie.main")]
interface DBusInterface : Object {
    public abstract int open_menu(string menu) throws IOError;   
    public signal void on_selection(int menu_id, string selected_item); 
}

public class Test : GLib.Object {

    private DBusInterface open_pie = null;

    public void run() {

        try {
            open_pie = Bus.get_proxy_sync(BusType.SESSION, "org.openpie.main",
                                                           "/org/openpie/main");

            open_pie.on_selection.connect((menu_id, selected_item) => {
                message("Got selection confirmation! ID: %d Item: %s", 
                        menu_id, selected_item);
            });

            open_pie.open_menu("open!");
            message("Sent open request.");

        } catch (IOError e) {
            error(e.message);
        }
        
    }
}

}
