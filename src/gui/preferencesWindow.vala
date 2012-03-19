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
/// The settings menu of Gnome-Pie.
/////////////////////////////////////////////////////////////////////////

public class PreferencesWindow : GLib.Object {
    
    /////////////////////////////////////////////////////////////////////
    /// The ID of the currently selected Pie.
    /////////////////////////////////////////////////////////////////////
    
    private string selected_id = "";
    
    /////////////////////////////////////////////////////////////////////
    /// Some Gtk widgets used by this window.
    /////////////////////////////////////////////////////////////////////
    
    private Gtk.Window? window = null;
    private Gtk.Label? id_label = null;
    private Gtk.Label? name_label = null;
    private Gtk.Label? hotkey_label = null;
    private Gtk.Label? no_pie_label = null;
    private Gtk.Label? no_slice_label = null;
    private Gtk.VBox? preview_box = null;
    private Gtk.Image? icon = null;
    private Gtk.EventBox? preview_background = null;
    private Gtk.Button? icon_button = null;
    private Gtk.Button? name_button = null;
    private Gtk.Button? hotkey_button = null;
    private Gtk.ToolButton? remove_pie_button = null;
    
    /////////////////////////////////////////////////////////////////////
    /// Some custom widgets and dialogs used by this window.
    /////////////////////////////////////////////////////////////////////
    
    private PiePreview? preview = null;
    private PieList? pie_list = null;
    private SettingsWindow? settings_window = null;
    private TriggerSelectWindow? trigger_window = null;
    private IconSelectWindow? icon_window = null;
    private RenameWindow? rename_window = null;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates the window.
    /////////////////////////////////////////////////////////////////////
    
    public PreferencesWindow() {
        try {
            var builder = new Gtk.Builder();

            builder.add_from_file (Paths.ui_files + "/preferences.ui");

            this.window = builder.get_object("window") as Gtk.Window;
            
            this.window.add_events(Gdk.EventMask.BUTTON_RELEASE_MASK |
                        Gdk.EventMask.KEY_RELEASE_MASK |
                        Gdk.EventMask.KEY_PRESS_MASK |
                        Gdk.EventMask.POINTER_MOTION_MASK);
            
            #if HAVE_GTK_3
                var toolbar = builder.get_object ("toolbar") as Gtk.Widget;
                toolbar.get_style_context().add_class("primary-toolbar");
                
                var inline_toolbar = builder.get_object ("pies-toolbar") as Gtk.Widget;
                inline_toolbar.get_style_context().add_class("inline-toolbar");
            #endif
            
            this.pie_list = new PieList();
            this.pie_list.on_select.connect(this.on_pie_select);
            
            var scroll_area = builder.get_object("pies-scrolledwindow") as Gtk.ScrolledWindow;
            scroll_area.add(this.pie_list);
            
            this.preview = new PiePreview();
            this.preview.on_first_slice_added.connect(() => {
                this.no_slice_label.hide();
            });
            
            this.preview.on_last_slice_removed.connect(() => {
                this.no_slice_label.show();
            });
            
            preview_box = builder.get_object("preview-box") as Gtk.VBox;
            this.preview_box.pack_start(preview, true, true);
            
            this.id_label = builder.get_object("id-label") as Gtk.Label;
            this.name_label = builder.get_object("pie-name-label") as Gtk.Label;
            this.hotkey_label = builder.get_object("hotkey-label") as Gtk.Label;
            this.no_pie_label = builder.get_object("no-pie-label") as Gtk.Label;
            this.no_slice_label = builder.get_object("no-slice-label") as Gtk.Label;
            this.icon = builder.get_object("icon") as Gtk.Image;
            this.preview_background = builder.get_object("preview-background") as Gtk.EventBox;
                    
            (builder.get_object("settings-button") as Gtk.ToolButton).clicked.connect(on_settings_button_clicked);
            
            this.hotkey_button = builder.get_object("key-button") as Gtk.Button;
            this.hotkey_button.clicked.connect(on_key_button_clicked);
            
            this.icon_button = builder.get_object("icon-button") as Gtk.Button;
            this.icon_button.clicked.connect(on_icon_button_clicked);
            
            this.name_button = builder.get_object("rename-button") as Gtk.Button;
            this.name_button.clicked.connect(on_rename_button_clicked);
            
            this.remove_pie_button = builder.get_object("remove-pie-button") as Gtk.ToolButton;
            this.remove_pie_button.clicked.connect(on_remove_pie_button_clicked);
            
            (builder.get_object("add-pie-button") as Gtk.ToolButton).clicked.connect(on_add_pie_button_clicked);
            
            this.window.hide.connect(() => {
                // save settings on close
                Config.global.save();
                Pies.save();
                
                Gdk.threads_add_timeout(100, () => {
                    IconSelectWindow.clear_icons();
                    return false;
                });
            });
            
            this.window.delete_event.connect(this.window.hide_on_delete);
                
        } catch (GLib.Error e) {
            error("Could not load UI: %s\n", e.message);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Shows the window.
    /////////////////////////////////////////////////////////////////////
    
    public void show() {
        this.preview.draw_loop();
        this.window.show_all();
        this.pie_list.select_first();
        this.preview_background.modify_bg(Gtk.StateType.NORMAL, Gtk.rc_get_style(this.window).light[0]);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when a new Pie is selected in the PieList.
    /////////////////////////////////////////////////////////////////////
    
    private void on_pie_select(string id) {
        selected_id = id;
        
        this.no_slice_label.hide();
        this.no_pie_label.hide();
        this.preview_box.hide();
        
        this.name_button.sensitive = false;
        this.hotkey_button.sensitive = false;
        this.icon_button.sensitive = false;
        this.remove_pie_button.sensitive = false;
        
        if (id == "") {
            this.id_label.label = "";
            this.name_label.label = _("No Pie selected.");
            this.hotkey_label.set_markup("");
            this.icon.icon_name = "application-default-icon";

            this.no_pie_label.show();
        } else {
            var pie = PieManager.all_pies[selected_id];
            this.id_label.label = ("ID: %s").printf(pie.id);
            this.name_label.label = PieManager.get_name_of(pie.id);
            this.hotkey_label.set_markup(PieManager.get_accelerator_label_of(pie.id));
            
            if (pie.icon.contains("/"))
                try {
                    this.icon.pixbuf = new Gdk.Pixbuf.from_file_at_scale(pie.icon, 
                                            this.icon.get_pixel_size(), this.icon.get_pixel_size(), true);
                } catch (GLib.Error error) {
                    warning(error.message);
                }
            else
                this.icon.icon_name = pie.icon;
            
            this.preview.set_pie(id);
            this.preview_box.show();
            
            if (pie.action_groups.size == 0) {
                this.no_slice_label.show();
            }
            
            this.name_button.sensitive = true;
            this.hotkey_button.sensitive = true;
            this.icon_button.sensitive = true;
            this.remove_pie_button.sensitive = true;
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the add Pie button is clicked.
    /////////////////////////////////////////////////////////////////////
    
    private void on_add_pie_button_clicked(Gtk.ToolButton button) {
        var new_pie = PieManager.create_persistent_pie(_("New Pie"), "application-default-icon", null);
        this.pie_list.reload_all();
        this.pie_list.select(new_pie.id);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the remove Pie button is clicked.
    /////////////////////////////////////////////////////////////////////
    
    private void on_remove_pie_button_clicked(Gtk.ToolButton button) {
        if (this.selected_id != "") {
            var dialog = new Gtk.MessageDialog((Gtk.Window)this.window.get_toplevel(), Gtk.DialogFlags.MODAL,
                         Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO,
                         _("Do you really want to delete the selected Pie with all contained Slices?"));
                                                     
            dialog.response.connect((response) => {
                if (response == Gtk.ResponseType.YES) {
                    PieManager.remove_pie(selected_id);
                    this.pie_list.reload_all();
                    this.pie_list.select_first();
                }
            });
            
            dialog.run();
            dialog.destroy();
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when rename Pie button is clicked.
    /////////////////////////////////////////////////////////////////////
    
    private void on_rename_button_clicked(Gtk.Button button) {
        if (this.rename_window == null) {
            this.rename_window = new RenameWindow();
            this.rename_window.set_parent(window);
            this.rename_window.on_ok.connect((name) => {
                var pie = PieManager.all_pies[selected_id];
                pie.name = name;
                PieManager.create_launcher(pie.id);
                this.name_label.label = name;
                this.pie_list.reload_all();
            });
        }
        
        this.rename_window.set_pie(selected_id);
        this.rename_window.show();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the hotkey button is clicked.
    /////////////////////////////////////////////////////////////////////
    
    private void on_key_button_clicked(Gtk.Button button) {
        if (this.trigger_window == null) {
            this.trigger_window = new TriggerSelectWindow();
            this.trigger_window.set_parent(window);
            this.trigger_window.on_ok.connect((trigger) => {
                PieManager.bind_trigger(trigger, selected_id);
                this.hotkey_label.set_markup(trigger.label_with_specials);
            });
        }
        
        this.trigger_window.set_pie(selected_id);
        this.trigger_window.show();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the general settings button is clicked.
    /////////////////////////////////////////////////////////////////////
    
    private void on_settings_button_clicked(Gtk.ToolButton button) {
        if (this.settings_window == null) {
            this.settings_window = new SettingsWindow();
            this.settings_window.set_parent(this.window.get_toplevel() as Gtk.Window);
        }
        
        this.settings_window.show();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the icon button is clicked.
    /////////////////////////////////////////////////////////////////////
    
    private void on_icon_button_clicked(Gtk.Button button) {
        if (this.icon_window == null) {
            this.icon_window = new IconSelectWindow(this.window);
            this.icon_window.on_ok.connect((icon) => {
                var pie = PieManager.all_pies[selected_id];
                pie.icon = icon;
                PieManager.create_launcher(pie.id);
                this.pie_list.reload_all();
            });
        }
        
        this.icon_window.show();
        this.icon_window.set_icon(PieManager.all_pies[selected_id].icon);
    }
}

}
