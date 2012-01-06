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
/// A window which allows selection of an Icon of the user's current icon 
/// theme. Custom icons/images can be selested as well. Loading of icons
/// happens in an extra thread and a spinner is displayed while loading.
/////////////////////////////////////////////////////////////////////////

public class NewSliceWindow : GLib.Object {

    public signal void on_select(ActionGroup action); 

    private SliceTypeList slice_type_list = null;
    private IconSelectWindow? icon_window = null;
    
    private Gtk.Window window = null;
    private Gtk.HBox name_box = null;
    private Gtk.HBox command_box = null;
    private Gtk.Button icon_button = null;
    private Gtk.VBox no_options_box = null;
    private Gtk.HBox pie_box = null;
    private Gtk.HBox hotkey_box = null;
    private Gtk.HBox uri_box = null;
    private Gtk.Image icon = null;
    
    public NewSliceWindow() {
        try {
        
            Gtk.Builder builder = new Gtk.Builder();

            builder.add_from_file (Paths.ui_files + "/slice_select.ui");
            
            this.slice_type_list = new SliceTypeList();
            this.slice_type_list.on_select.connect((type, icon) => {
                
                this.name_box.hide();
                this.command_box.hide();
                this.icon_button.sensitive = false;
                this.no_options_box.hide();
                this.pie_box.hide();
                this.hotkey_box.hide();
                this.uri_box.hide();
                
                this.icon.icon_name = icon;
                
                switch (type) {
                    case "bookmarks": case "clipboard": case "devices":
                    case "menu": case "session": case "window_list":
                        this.no_options_box.show();
                        break;
                    case "app":
                        this.name_box.show();
                        this.command_box.show();
                        this.icon_button.sensitive = true;
                        break;
                    case "key":
                        this.name_box.show();
                        this.hotkey_box.show();
                        this.icon_button.sensitive = true;
                        break;
                    case "pie":
                        this.pie_box.show();
                        break;
                    case "uri":
                        this.name_box.show();
                        this.uri_box.show();
                        this.icon_button.sensitive = true;
                        break;
                }
            });
            
            this.name_box = builder.get_object("name-box") as Gtk.HBox;
            this.command_box = builder.get_object("command-box") as Gtk.HBox;
            this.icon_button = builder.get_object("icon-button") as Gtk.Button;
            this.no_options_box = builder.get_object("no-options-box") as Gtk.VBox;
            this.pie_box = builder.get_object("pie-box") as Gtk.HBox;
            this.hotkey_box = builder.get_object("hotkey-box") as Gtk.HBox;
            this.uri_box = builder.get_object("uri-box") as Gtk.HBox;
            this.icon = builder.get_object("icon") as Gtk.Image;            
            
            this.icon_button.clicked.connect(on_icon_button_clicked);
            
            var scroll_area = builder.get_object("slice-scrolledwindow") as Gtk.ScrolledWindow;
                scroll_area.add(this.slice_type_list);

            this.window = builder.get_object("window") as Gtk.Window;
            
            (builder.get_object("ok-button") as Gtk.Button).clicked.connect(on_ok_button_clicked);
            (builder.get_object("cancel-button") as Gtk.Button).clicked.connect(on_cancel_button_clicked);
                
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
    
    public void set_action(ActionGroup action) {
    
    }
    
    private void on_ok_button_clicked() {
        this.window.hide();
    }
    
    private void on_cancel_button_clicked() {
        this.window.hide();
    }   
    
    private void on_icon_button_clicked(Gtk.Button button) {
        if (icon_window == null) {
            icon_window = new IconSelectWindow();
            
            icon_window.on_ok.connect((icon) => {
                if (icon.contains("/"))
                    this.icon.pixbuf = new Gdk.Pixbuf.from_file_at_scale(icon, this.icon.get_pixel_size(), this.icon.get_pixel_size(), true);
                else
                    this.icon.icon_name = icon;
            });
        }
        
        icon_window.set_parent(window);
        icon_window.show();
    } 
}

}
