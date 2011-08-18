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

// A simple about Dialog.

public class GnomePieAboutDialog: Gtk.AboutDialog {

    public GnomePieAboutDialog () {
        string[] devs = {"Simon Schneegans <simon.schneegans@uni-weimar.de>"};
        string[] artists = devs;
        GLib.Object (
            artists : artists,
            authors : devs,
            copyright : "Copyright (C) 2011 Simon Schneegans <simon.schneegans@uni-weimar.de>",
            program_name: "Gnome-Pie",
            logo_icon_name: "gnome-pie",
            version: "0.1"
        );
    }
}

}
