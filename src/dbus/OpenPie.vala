////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2013 by Simon Schneegans                                //
//                                                                            //
// This program is free software: you can redistribute it and/or modify it    //
// under the terms of the GNU General Public License as published by the Free //
// Software Foundation, either version 3 of the License, or (at your option)  //
// any later version.                                                         //
//                                                                            //
// This program is distributed in the hope that it will be useful, but        //
// WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY //
// or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License   //
// for more details.                                                          //
//                                                                            //
// You should have received a copy of the GNU General Public License along    //
// with this program.  If not, see <http://www.gnu.org/licenses/>.            //
////////////////////////////////////////////////////////////////////////////////

namespace GnomePie {

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

[DBus (name = "org.gnome.openpie")]
interface DBusInterface : Object {
  public signal   void  on_select(int id, string path);
  public abstract int   show_menu(string menu) throws IOError;
}

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

public class OpenPie : GLib.Object {

  //////////////////////////////////////////////////////////////////////////////
  //                          public interface                                //
  //////////////////////////////////////////////////////////////////////////////

  public signal void on_select(int id, string path);

  //////////////////////////// public methods //////////////////////////////////

  // ---------------------------------------------------------------------------
  public OpenPie() {
    try {
      dbus_ = Bus.get_proxy_sync(BusType.SESSION, "org.gnome.openpie",
                                                          "/org/gnome/openpie");
      dbus_.on_select.connect((id, path) => {
        on_select(id, path);
      });

    } catch (IOError e) {
      error("Failed to connect to OpenPie: " + e.message);
    }
  }

  // ---------------------------------------------------------------------------
  public int open_menu(string menu) {
    return dbus_.show_menu(menu);
  }

  //////////////////////////////////////////////////////////////////////////////
  //                          private stuff                                   //
  //////////////////////////////////////////////////////////////////////////////

  ////////////////////////// private members ///////////////////////////////////

  private DBusInterface dbus_ = null;
}

}
