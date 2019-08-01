/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2019 Simon Schneegans
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
/// An appindicator sitting in the panel. It owns the settings menu.
/////////////////////////////////////////////////////////////////////////

public class Indicator : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// The internally used indicator.
    /////////////////////////////////////////////////////////////////////

    #if HAVE_APPINDICATOR
        private AppIndicator.Indicator indicator { private get; private set; }
    #else
        private Gtk.StatusIcon indicator {private get; private set; }
        private Gtk.Menu menu {private get; private set; }
    #endif

    /////////////////////////////////////////////////////////////////////
    /// The Preferences Menu of Gnome-Pie.
    /////////////////////////////////////////////////////////////////////

    private PreferencesWindow prefs { private get; private set; }

    /////////////////////////////////////////////////////////////////////
    /// Returns true, when the indicator is currently visible.
    /////////////////////////////////////////////////////////////////////

    public bool active {
        get {
            #if HAVE_APPINDICATOR
                return indicator.get_status() == AppIndicator.IndicatorStatus.ACTIVE;
            #else
                return indicator.get_visible();
            #endif
        }
        set {
            #if HAVE_APPINDICATOR
                if (value) indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
                else       indicator.set_status(AppIndicator.IndicatorStatus.PASSIVE);
            #else
                indicator.set_visible(value);
            #endif
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs a new Indicator, residing in the user's panel.
    /////////////////////////////////////////////////////////////////////

    public Indicator() {
        string icon = "gnome-pie-symbolic";

        #if HAVE_APPINDICATOR

            string path = "";
            try {
                path = GLib.Path.get_dirname(GLib.FileUtils.read_link("/proc/self/exe"))+"/resources";
            } catch (GLib.FileError e) {
                warning("Failed to get path of executable!");
            }

            this.indicator = new AppIndicator.Indicator.with_path("Gnome-Pie", icon,
                                 AppIndicator.IndicatorCategory.APPLICATION_STATUS, path);

            var menu = new Gtk.Menu();
        #else
            this.indicator = new Gtk.StatusIcon();
            try {
                var file = GLib.File.new_for_path(GLib.Path.build_filename(
                    GLib.Path.get_dirname(GLib.FileUtils.read_link("/proc/self/exe"))+"/resources",
                    icon + ".svg"
                ));

                if (!file.query_exists())
                  this.indicator.set_from_icon_name(icon);
                else
                  this.indicator.set_from_file(file.get_path());
            } catch (GLib.FileError e) {
                warning("Failed to get path of executable!");
                this.indicator.set_from_icon_name(icon);
            }

            this.menu = new Gtk.Menu();
            var menu = this.menu;
        #endif

        this.prefs = new PreferencesWindow();

        // preferences item
        var item = new Gtk.MenuItem.with_mnemonic(_("_Preferences"));
        item.activate.connect(() => {
            this.prefs.show();
        });

        item.show();
        menu.append(item);

        // about item
        item = new Gtk.MenuItem.with_mnemonic(_("_About"));
        item.show();
        item.activate.connect(() => {
            var about = new AboutWindow();
            about.run();
            about.destroy();
        });
        menu.append(item);

        // separator
        var sepa = new Gtk.SeparatorMenuItem();
        sepa.show();
        menu.append(sepa);

        // quit item
        item = new Gtk.MenuItem.with_mnemonic(_("_Quit"));
        item.activate.connect(()=>{
            GLib.Application.get_default().release();
        });
        item.show();
        menu.append(item);

        #if HAVE_APPINDICATOR
            this.indicator.set_menu(menu);
        #else
            this.indicator.popup_menu.connect((btn, time) => {
                this.menu.popup(null, null, null, btn, time);
            });
        #endif

        this.active = Config.global.show_indicator;
        Config.global.notify["show-indicator"].connect((s, p) => {
            this.active = Config.global.show_indicator;
        });
    }

    /////////////////////////////////////////////////////////////////////
    /// Shows the preferences menu.
    /////////////////////////////////////////////////////////////////////

    public void show_preferences() {
        this.prefs.show();
    }
}

}
