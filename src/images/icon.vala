/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2017 by Simon Schneegans
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
///  A class representing a square-shaped icon, loaded from the users
/// icon theme.
/////////////////////////////////////////////////////////////////////////

public class Icon : Image {

    /////////////////////////////////////////////////////////////////////
    /// A cache which stores loaded icon. It is cleared when the icon
    /// theme of the user changes. The key is in form <filename>@<size>.
    /////////////////////////////////////////////////////////////////////

    private static Gee.HashMap<string, Cairo.ImageSurface?> cache { private get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Initializes the cache.
    /////////////////////////////////////////////////////////////////////

    public static void init() {
        clear_cache();

        Gtk.IconTheme.get_default().changed.connect(() => {
            clear_cache();
        });
    }

    /////////////////////////////////////////////////////////////////////
    /// Clears the cache.
    /////////////////////////////////////////////////////////////////////

    public static void clear_cache() {
        cache = new Gee.HashMap<string, Cairo.ImageSurface?>();
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads an icon from the current icon theme of the user.
    /////////////////////////////////////////////////////////////////////

    public Icon(string icon_name, int size) {
        var cached = Icon.cache.get("%s@%u".printf(icon_name, size));

        if (cached == null) {
            this.load_file_at_size(Icon.get_icon_file(icon_name, size), size, size);
            Icon.cache.set("%s@%u".printf(icon_name, size), this.surface);
        } else {
            this.surface = cached;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the size of the icon in pixels. Greetings to Liskov.
    /////////////////////////////////////////////////////////////////////

    public int size() {
        return base.width();
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the filename for a given system icon.
    /////////////////////////////////////////////////////////////////////

    public static string get_icon_file(string icon_name, int size) {
        if (icon_name.contains("/")) {
            var file = GLib.File.new_for_path(icon_name);
            if(file.query_exists()) {
                return icon_name;
            }
        }

        var icon_theme = Gtk.IconTheme.get_default();
        var file = icon_theme.lookup_icon(icon_name, size, 0);
        if (file != null) {
            return file.get_filename();
        }

        try {
            file = icon_theme.lookup_by_gicon(GLib.Icon.new_for_string(icon_name), size, 0);
            if (file != null) {
                return file.get_filename();
            }
        } catch(GLib.Error e) {}

        warning("Icon \"" + icon_name + "\" not found! Using default icon...");

        string[] default_icons = {"image-missing", "application-default-icon"};
        foreach (var icon in default_icons) {
            file = icon_theme.lookup_icon(icon, size, 0);
            if (file != null) {
                return file.get_filename();
            }
        }

        warning("No default icon found! Will be ugly...");

        return "";
    }
}

}
