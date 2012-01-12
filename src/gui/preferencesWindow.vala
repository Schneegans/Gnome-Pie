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

    private Gtk.Builder builder = null;

    private string selected_id = "";
    
    private PiePreview? preview = null;
    private PieList? pie_list = null;
    
    private Gtk.Window? window = null;
    private Gtk.Label? id_label = null;
    private Gtk.Label? name_label = null;
    private Gtk.Label? hotkey_label = null;
    private Gtk.Label? no_pie_label = null;
    private Gtk.VBox? no_slice_box = null;
    private Gtk.VBox? preview_box = null;
    private Gtk.Image? icon = null;
    
    private AppearanceWindow? appearance_window = null;
    private TriggerSelectWindow? trigger_window = null;
    private IconSelectWindow? icon_window = null;
    private RenameWindow? rename_window = null;
    
    public PreferencesWindow() {
        try {
            this.builder = new Gtk.Builder();

            builder.add_from_file (Paths.ui_files + "/preferences.ui");

            this.window = builder.get_object("window") as Gtk.Window;
            
            #if HAVE_GTK_3
                var toolbar = builder.get_object ("toolbar") as Gtk.Widget;
                toolbar.get_style_context().add_class("primary-toolbar");
                
                var inline_toolbar = builder.get_object ("pies-toolbar") as Gtk.Widget;
                inline_toolbar.get_style_context().add_class("inline-toolbar");
            #endif
            
            pie_list = new PieList();
            pie_list.on_select.connect(on_pie_select);
            
            var scroll_area = builder.get_object("pies-scrolledwindow") as Gtk.ScrolledWindow;
            scroll_area.add(pie_list);
            
            preview = new PiePreview();
            
            preview_box = builder.get_object("preview-box") as Gtk.VBox;
            preview_box.pack_start(preview, true, true);
            

            var tips_box = builder.get_object("tips-box") as Gtk.HBox;
            
                // info image
                var info_image = new Gtk.Image.from_stock (Gtk.Stock.INFO, Gtk.IconSize.MENU);
                    tips_box.pack_start (info_image, false, false);

                // info label
                var info_label = new TipViewer({
                        _("You can right-click in the list for adding or removing entries."),
                        _("You can reset Gnome-Pie to its default options with the terminal command \"gnome-pie --reset\"."),
                        _("The radiobutton at the beginning of each slice-line indicates the QuickAction of the pie."),
                        _("Pies can be opened with the terminal command \"gnome-pie --open=ID\"."),
                        _("Feel free to visit Gnome-Pie's homepage at %s!").printf("<a href='http://gnome-pie.simonschneegans.de'>gnome-pie.simonschneegans.de</a>"),
                        _("You can drag'n'drop applications from your main menu to the list above."),
                        _("If you want to give some feedback, please write an e-mail to %s!").printf("<a href='mailto:code@simonschneegans.de'>code@simonschneegans.de</a>"),
                        _("You may drag'n'drop URLs and bookmarks from your internet browser to the list above."),
                        _("Bugs can be reported at %s!").printf("<a href='https://github.com/Simmesimme/Gnome-Pie'>Github</a>"),
                        _("It's possible to drag'n'drop files and folders from your file browser to the list above."),
                        _("It's recommended to keep your Pies small (at most 6-8 Slices). Else they will become hard to navigate."),
                        _("In order to create a launcher for a Pie, drag the Pie from the list to your desktop!")
                    });
                    this.window.show.connect(info_label.start_slide_show);
                    this.window.hide.connect(info_label.stop_slide_show);
                    
                tips_box.pack_start(info_label, true, true);
            
            id_label = builder.get_object("id-label") as Gtk.Label;
            name_label = builder.get_object("pie-name-label") as Gtk.Label;
            hotkey_label = builder.get_object("hotkey-label") as Gtk.Label;
            no_pie_label = builder.get_object("no-pie-label") as Gtk.Label;
            no_slice_box = builder.get_object("no-slice-box") as Gtk.VBox;
            icon = builder.get_object("icon") as Gtk.Image;
                    
            (builder.get_object("theme-button") as Gtk.Button).clicked.connect(on_theme_button_clicked);
            (builder.get_object("key-button") as Gtk.Button).clicked.connect(on_key_button_clicked);
            (builder.get_object("icon-button") as Gtk.Button).clicked.connect(on_icon_button_clicked);
            (builder.get_object("rename-button") as Gtk.Button).clicked.connect(on_rename_button_clicked);
            (builder.get_object("add-pie-button") as Gtk.ToolButton).clicked.connect(on_add_pie_button_clicked);
            (builder.get_object("remove-pie-button") as Gtk.ToolButton).clicked.connect(on_remove_pie_button_clicked);
            
            window.hide.connect(() => {
                // save settings on close
                Config.global.save();
                Pies.save();
            });
            
            this.window.delete_event.connect(this.window.hide_on_delete);
                
        } catch (GLib.Error e) {
            error("Could not load UI: %s\n", e.message);
        }
    }
    
    public void show() {
        preview.draw_loop();
        window.show_all();
        pie_list.select_first();
    }
    
    private void on_pie_select(string id) {
        selected_id = id;
        
        no_slice_box.hide();
        no_pie_label.hide();
        preview_box.hide();
        
        if (id == "") {
            id_label.label = "";
            name_label.label = _("No Pie selected.");
            hotkey_label.set_markup("");
            icon.icon_name = "application-default-icon";

            no_pie_label.show();
        } else {
            var pie = PieManager.all_pies[selected_id];
            id_label.label = _("ID: %s").printf(pie.id);
            name_label.label = PieManager.get_name_of(pie.id);
            hotkey_label.set_markup(PieManager.get_accelerator_label_of(pie.id));
            
            if (pie.icon.contains("/"))
                this.icon.pixbuf = new Gdk.Pixbuf.from_file_at_scale(pie.icon, this.icon.get_pixel_size(), this.icon.get_pixel_size(), true);
            else
                this.icon.icon_name = pie.icon;
            
            if (pie.action_groups.size > 0) {
                preview.set_pie(id);
                preview_box.show();
            } else {
                no_slice_box.show();
                preview.set_pie(id);
            }
        }
    }
    
    private void on_add_pie_button_clicked(Gtk.ToolButton button) {
        var new_pie = PieManager.create_persistent_pie(_("New Pie"), "application-default-icon", null);
        pie_list.reload_all();
        pie_list.select(new_pie.id);
    }
    
    private void on_remove_pie_button_clicked(Gtk.ToolButton button) {
        if (selected_id != "") {
            var dialog = new Gtk.MessageDialog((Gtk.Window)this.window.get_toplevel(), Gtk.DialogFlags.MODAL,
                         Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO,
                         _("Do you really want to delete the selected Pie with all contained Slices?"));
                                                     
            dialog.response.connect((response) => {
                if (response == Gtk.ResponseType.YES) {
                    PieManager.remove_pie(selected_id);
                    pie_list.reload_all();
                    pie_list.select_first();
                }
            });
            
            dialog.run();
            dialog.destroy();
        }
    }
    
    private void on_rename_button_clicked(Gtk.Button button) {
        if (rename_window == null) {
            rename_window = new RenameWindow();
            rename_window.on_ok.connect((name) => {
                var pie = PieManager.all_pies[selected_id];
                pie.name = name;
                PieManager.create_launcher(pie.id);
                name_label.label = name;
                pie_list.reload_all();
            });
        }
        
        rename_window.set_parent(window);
        rename_window.set_pie(selected_id);
        rename_window.show();
    }
    
    private void on_key_button_clicked(Gtk.Button button) {
        if (trigger_window == null) {
            trigger_window = new TriggerSelectWindow();
            trigger_window.on_ok.connect((trigger) => {
                PieManager.bind_trigger(trigger, selected_id);
                hotkey_label.set_markup(trigger.label_with_specials);
            });
        }
        
        trigger_window.set_parent(window);
        trigger_window.set_pie(selected_id);
        trigger_window.show();
    }
    
    private void on_theme_button_clicked(Gtk.Button button) {
        if (appearance_window == null)
            appearance_window = new AppearanceWindow();
        
        this.appearance_window.set_parent(this.window);
        this.appearance_window.show();
    }
    
    private void on_icon_button_clicked(Gtk.Button button) {
        if (icon_window == null) {
            icon_window = new IconSelectWindow();
            
            icon_window.on_ok.connect((icon) => {
                var pie = PieManager.all_pies[selected_id];
                pie.icon = icon;
                PieManager.create_launcher(pie.id);
                pie_list.reload_all();
            });
        }
        
        icon_window.set_parent(window);
        icon_window.show();
    }
}

}
