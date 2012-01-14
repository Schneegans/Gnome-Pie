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

    public signal void on_select(ActionGroup action, bool as_new_slice, int at_position); 

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
    private Gtk.HBox quickaction_box = null;
    private Gtk.Image icon = null;
    private Gtk.Entry name_entry = null;
    private Gtk.Entry command_entry = null;
    private Gtk.Entry uri_entry = null;
    private Gtk.CheckButton quickaction_checkbutton = null;
    
    private PieComboList pie_select = null;
    private HotkeySelectButton key_select = null;
    
    private string current_type = "";
    private string current_icon = "";
    private string current_id = "";
    private string current_custom_icon = "";
    private string current_hotkey = "";
    private string current_pie_to_open = "";
    
    private int slice_position = 0;
    private bool add_as_new_slice = true;
 
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
                this.quickaction_box.hide();
                
                this.current_type = type;
                
                switch (type) {
                    case "bookmarks": case "clipboard": case "devices":
                    case "menu": case "session": case "window_list":
                        this.no_options_box.show();
                        this.set_icon(icon);
                        break;
                    case "app":
                        this.name_box.show();
                        this.command_box.show();
                        this.quickaction_box.show();
                        this.icon_button.sensitive = true;
                        if (this.current_custom_icon == "") this.set_icon(icon);
                        else                                this.set_icon(this.current_custom_icon);
                        break;
                    case "key":
                        this.name_box.show();
                        this.hotkey_box.show();
                        this.quickaction_box.show();
                        this.icon_button.sensitive = true;
                        if (this.current_custom_icon == "") this.set_icon(icon);
                        else                                this.set_icon(this.current_custom_icon);
                        break;
                    case "pie":
                        this.pie_box.show();
                        this.quickaction_box.show();
                        this.set_icon(icon);
                        break;
                    case "uri":
                        this.name_box.show();
                        this.uri_box.show();
                        this.quickaction_box.show();
                        this.icon_button.sensitive = true;
                        if (this.current_custom_icon == "") this.set_icon(icon);
                        else                                this.set_icon(this.current_custom_icon);
                        break;
                }
            });
            
            this.name_box = builder.get_object("name-box") as Gtk.HBox;
            this.command_box = builder.get_object("command-box") as Gtk.HBox;
            this.icon_button = builder.get_object("icon-button") as Gtk.Button;
            this.no_options_box = builder.get_object("no-options-box") as Gtk.VBox;
            this.pie_box = builder.get_object("pie-box") as Gtk.HBox;
            this.pie_select = new PieComboList();
            this.pie_select.on_select.connect((id) => {
                this.current_pie_to_open = id;
            });
            
            this.pie_box.pack_start(this.pie_select, false, true);
                
            this.hotkey_box = builder.get_object("hotkey-box") as Gtk.HBox;
            this.key_select = new HotkeySelectButton();
            this.hotkey_box.pack_start(this.key_select, false, true);
            this.key_select.on_select.connect((key) => {
                this.current_hotkey = key.accelerator;
            });
            
            this.uri_box = builder.get_object("uri-box") as Gtk.HBox;
            
            this.name_entry = builder.get_object("name-entry") as Gtk.Entry;
            this.uri_entry = builder.get_object("uri-entry") as Gtk.Entry;
            this.command_entry = builder.get_object("command-entry") as Gtk.Entry;
            this.quickaction_checkbutton = builder.get_object("quick-action-checkbutton") as Gtk.CheckButton;
            
            this.quickaction_box = builder.get_object("quickaction-box") as Gtk.HBox;
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
        this.slice_type_list.select_first();
        this.pie_select.select_first();
        this.key_select.set_key(new Key());
    }
    
    public void reload() {
        this.pie_select.reload();
    }
    
    public void set_action(ActionGroup group, int position) {
        this.set_default(group.parent_id, position);
        
        this.add_as_new_slice = false;
        string type = "";
        
        if (group.get_type().depth() == 2) {
            var action = group.actions[0];
            type = ActionRegistry.descriptions[action.get_type()].id;
            this.select_type(type);
            
            this.set_icon(action.icon);
            this.quickaction_checkbutton.active = action.is_quickaction;
            this.name_entry.text = action.name;
            
            switch (type) {
                case "app":
                    this.current_custom_icon = action.icon;
                    this.command_entry.text = action.real_command;
                    break;
                case "key":
                    this.current_custom_icon = action.icon;
                    this.key_select.set_key(new Key.from_string(action.real_command));
                    break;
                case "pie":
                    this.pie_select.select(action.real_command);
                    break;
                case "uri":
                    this.current_custom_icon = action.icon;
                    this.uri_entry.text = action.real_command;
                    break;
            }
            
        } else {
            type = GroupRegistry.descriptions[group.get_type()].id;
            this.select_type(type);
        }
    }
    
    public void set_default(string pie_id, int position) {
        this.slice_position = position;
        this.add_as_new_slice = true;
        this.current_custom_icon = "";
        this.select_type("app");
        this.current_id = pie_id;
        this.key_select.set_key(new Key());
        this.pie_select.select_first();
        this.name_entry.text = _("Rename me!");
        this.command_entry.text = "";
        this.uri_entry.text = "";
    }
    
    private void select_type(string type) {
        this.current_type = type;
        this.slice_type_list.select(type);
    }
    
    private void on_ok_button_clicked() {
        this.window.hide();
        
        ActionGroup group = null;
        
        switch (this.current_type) {
            case "bookmarks":   group = new BookmarkGroup(this.current_id);      break;
            case "clipboard":   group = new ClipboardGroup(this.current_id);     break;
            case "devices":     group = new DevicesGroup(this.current_id);       break;
            case "menu":        group = new MenuGroup(this.current_id);          break;
            case "session":     group = new SessionGroup(this.current_id);       break;
            case "window_list": group = new WindowListGroup(this.current_id);    break;

            case "app":
                group = new ActionGroup(this.current_id);
                group.add_action(new AppAction(this.name_entry.text, this.current_icon, 
                                               this.command_entry.text, 
                                               this.quickaction_checkbutton.active));
                break;
            case "key":
                group = new ActionGroup(this.current_id);
                group.add_action(new KeyAction(this.name_entry.text, this.current_icon, 
                                               this.current_hotkey, 
                                               this.quickaction_checkbutton.active));
                break;
            case "pie":
                group = new ActionGroup(this.current_id);
                group.add_action(new PieAction(this.current_pie_to_open, 
                                               this.quickaction_checkbutton.active));
                break;
            case "uri":
                group = new ActionGroup(this.current_id);
                group.add_action(new UriAction(this.name_entry.text, this.current_icon, 
                                               this.uri_entry.text, 
                                               this.quickaction_checkbutton.active));
                break;
        }
        
        this.on_select(group, this.add_as_new_slice, this.slice_position);
    }
    
    private void on_cancel_button_clicked() {
        this.window.hide();
    }   
    
    private void on_icon_button_clicked(Gtk.Button button) {
        if (icon_window == null) {
            icon_window = new IconSelectWindow();
            icon_window.on_ok.connect((icon) => {
                this.current_custom_icon = icon;
                this.set_icon(icon);
            });
        }
        
        icon_window.set_parent(window);
        icon_window.show();
    }
    
    private void set_icon(string icon) {
        if (icon.contains("/"))
            this.icon.pixbuf = new Gdk.Pixbuf.from_file_at_scale(icon, this.icon.get_pixel_size(), 
                                                                       this.icon.get_pixel_size(), true);
        else
            this.icon.icon_name = icon;
            
        this.current_icon = icon;
    } 
}

}
