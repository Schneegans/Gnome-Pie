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
/// The Gtk settings menu of Gnome-Pie.
/////////////////////////////////////////////////////////////////////////

public class AppearanceWindow : GLib.Object {
    
    private Gtk.Window window = null;
    private ThemeList theme_list = null;
    
    public AppearanceWindow() {
        try {
        
            Gtk.Builder builder = new Gtk.Builder();

            builder.add_from_file (Paths.ui_files + "/appearance.ui");

            this.window = builder.get_object("window") as Gtk.Window;
            
            this.theme_list = new ThemeList();
            
            var scroll_area = builder.get_object("theme-scrolledwindow") as Gtk.ScrolledWindow;
                scroll_area.add(this.theme_list);
                
            (builder.get_object("close-button") as Gtk.Button).clicked.connect(on_close_button_clicked);
                
        } catch (GLib.Error e) {
            error("Could not load UI: %s\n", e.message);
        }
    }
    
    public void set_parent(Gtk.Window parent) {
        this.window.set_transient_for(parent);
    }
    
    public void show() {
        this.window.show_all();
    }
    
    private void on_close_button_clicked() {
        this.window.hide();
    }
}

}
