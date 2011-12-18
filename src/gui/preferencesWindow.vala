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

public class PreferencesWindow : GLib.Object {
    
    private Gtk.Window? window = null;
    private PieList? pie_list = null;
    
    private AppearanceWindow? appearance_window = null;
    private TriggerSelectWindow? trigger_window = null;
    private IconSelectWindow? icon_window = null;
    private RenameWindow? rename_window = null;
    private NewSliceWindow? new_slice_window = null;
    
    public PreferencesWindow() {
        try {
            Gtk.Builder builder = new Gtk.Builder();

            builder.add_from_file (Paths.ui_files + "/preferences.ui");

            this.window = builder.get_object("window") as Gtk.Window;
            
            #if HAVE_GTK_3
                var toolbar = builder.get_object ("toolbar") as Gtk.Widget;
                toolbar.get_style_context().add_class("primary-toolbar");
                
                var inline_toolbar = builder.get_object ("pies-toolbar") as Gtk.Widget;
                inline_toolbar.get_style_context().add_class("inline-toolbar");
            #endif
            
            this.pie_list = new PieList();
            
            var scroll_area = builder.get_object("pies-scrolledwindow") as Gtk.ScrolledWindow;
            scroll_area.add(this.pie_list);
                    
            (builder.get_object("theme-button") as Gtk.Button).clicked.connect(on_theme_button_clicked);
            (builder.get_object("key-button") as Gtk.Button).clicked.connect(on_key_button_clicked);
            (builder.get_object("icon-button") as Gtk.Button).clicked.connect(on_icon_button_clicked);
            (builder.get_object("rename-button") as Gtk.Button).clicked.connect(on_rename_button_clicked);
            (builder.get_object("add-slice-button") as Gtk.Button).clicked.connect(on_add_slice_button_clicked);
                
        } catch (GLib.Error e) {
            error("Could not load UI: %s\n", e.message);
        }
    }
    
    public void show() {
        window.show_all();
    }
    
    public void on_add_slice_button_clicked(Gtk.Button button) {
        if (this.new_slice_window == null)
            this.new_slice_window = new NewSliceWindow();
        
        this.new_slice_window.set_parent(this.window);
        this.new_slice_window.show();
    }
    
    public void on_add_pie_button_clicked(Gtk.Button button) {
        debug("add pie");
    }
    
    public void on_remove_pie_button_clicked(Gtk.Button button) {
        debug("remove pie");
    }
    
    public void on_rename_button_clicked(Gtk.Button button) {
        if (this.rename_window == null)
            this.rename_window = new RenameWindow();
        
        this.rename_window.set_parent(this.window);
        this.rename_window.show();
    }
    
    public void on_key_button_clicked(Gtk.Button button) {
        if (this.trigger_window == null)
            this.trigger_window = new TriggerSelectWindow();
        
        this.trigger_window.set_parent(this.window);
        this.trigger_window.show();
    }
    
    private void on_theme_button_clicked(Gtk.Button button) {
        if (this.appearance_window == null)
            this.appearance_window = new AppearanceWindow();
        
        this.appearance_window.set_parent(this.window);
        this.appearance_window.show();
    }
    
    public void on_icon_button_clicked(Gtk.Button button) {
        if (this.icon_window == null)
            this.icon_window = new IconSelectWindow();
        
        this.icon_window.set_parent(this.window);
        this.icon_window.show();
    }
}

}
