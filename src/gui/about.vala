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
/// A simple about Dialog.
/////////////////////////////////////////////////////////////////////////

public class GnomePieAboutDialog: Gtk.AboutDialog {

    public GnomePieAboutDialog () {
        string[] devs = {"Simon Schneegans <code@simonschneegans.de>", 
                         "Francesco Piccinno"};
        string[] artists = {"Simon Schneegans <code@simonschneegans.de>"};
        GLib.Object (
            artists : artists,
            authors : devs,
            copyright : "Copyright (C) 2011 Simon Schneegans <code@simonschneegans.de>",
            program_name: "Gnome-Pie",
            logo_icon_name: "gnome-pie",
            website: "http://www.simonschneegans.de/?page_id=12",
            website_label: "www.gnome-pie.simonschneegans.de",
            version: "0.3"
        );
    }
}

}
