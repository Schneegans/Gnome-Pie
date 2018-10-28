/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2018 Simon Schneegans
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
