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

    private string selected_id = "";
    
    private PiePreview? preview = null;
    private PieList? pie_list = null;
    
    private Gtk.Window? window = null;
    private Gtk.Label? id_label = null;
    private Gtk.Label? name_label = null;
    private Gtk.Label? hotkey_label = null;
    private Gtk.Image? icon = null;
    
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
            
            pie_list = new PieList();
            pie_list.on_select.connect(on_pie_select);
            
            var scroll_area = builder.get_object("pies-scrolledwindow") as Gtk.ScrolledWindow;
            scroll_area.add(pie_list);
            
            preview = new PiePreview();
            
            var preview_box = builder.get_object("preview") as Gtk.VBox;
            preview_box.pack_start(preview, true, true);
            
            id_label = builder.get_object("id-label") as Gtk.Label;
            name_label = builder.get_object("pie-name-label") as Gtk.Label;
            hotkey_label = builder.get_object("hotkey-label") as Gtk.Label;
            icon = builder.get_object("icon") as Gtk.Image;
                    
            (builder.get_object("theme-button") as Gtk.Button).clicked.connect(on_theme_button_clicked);
            (builder.get_object("key-button") as Gtk.Button).clicked.connect(on_key_button_clicked);
            (builder.get_object("icon-button") as Gtk.Button).clicked.connect(on_icon_button_clicked);
            (builder.get_object("rename-button") as Gtk.Button).clicked.connect(on_rename_button_clicked);
            (builder.get_object("add-slice-button") as Gtk.Button).clicked.connect(on_add_slice_button_clicked);
            
            window.hide.connect(() => {
                // save settings on close
                Config.global.save();
                Pies.save();
            });
                
        } catch (GLib.Error e) {
            error("Could not load UI: %s\n", e.message);
        }
    }
    
    public void show() {
        window.show_all();
    }
    
    private void on_pie_select(string id) {
        selected_id = id;
        var pie = PieManager.all_pies[selected_id];
        
        id_label.label = _("ID: %s").printf(pie.id);
        name_label.label = PieManager.get_name_of(pie.id);
        hotkey_label.set_markup(PieManager.get_accelerator_label_of(pie.id));
        icon.icon_name = pie.icon;
        preview.set_pie(id);
    }
    
    private void on_add_slice_button_clicked(Gtk.Button button) {
        if (new_slice_window == null)
            new_slice_window = new NewSliceWindow();
        
        new_slice_window.set_parent(this.window);
        new_slice_window.show();
    }
    
    private void on_add_pie_button_clicked(Gtk.Button button) {
        debug("add pie");
    }
    
    private void on_remove_pie_button_clicked(Gtk.Button button) {
        debug("remove pie");
    }
    
    private void on_rename_button_clicked(Gtk.Button button) {
        if (rename_window == null) {
            rename_window = new RenameWindow();
            rename_window.on_ok.connect((name) => {
                var pie = PieManager.all_pies[selected_id];
                pie.name = name;
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
        if (icon_window == null)
            icon_window = new IconSelectWindow();
        
        icon_window.set_parent(window);
        icon_window.show();
    }
}

}
