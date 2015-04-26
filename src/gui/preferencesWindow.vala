/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2015 by Simon Schneegans
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
    private Gtk.Label? no_pie_label = null;
    private Gtk.Label? no_slice_label = null;
    private Gtk.Box? preview_box = null;
    private Gtk.EventBox? preview_background = null;
    private Gtk.ToolButton? remove_pie_button = null;
    private Gtk.ToolButton? edit_pie_button = null;

    /////////////////////////////////////////////////////////////////////
    /// Some custom widgets and dialogs used by this window.
    /////////////////////////////////////////////////////////////////////

    private PiePreview? preview = null;
    private PieList? pie_list = null;
    private SettingsWindow? settings_window = null;
    private PieOptionsWindow? pie_options_window = null;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates the window.
    /////////////////////////////////////////////////////////////////////

    public PreferencesWindow() {
        var builder = new Gtk.Builder.from_file(Paths.ui_files + "/preferences.ui");

        this.window = builder.get_object("window") as Gtk.Window;
        this.window.add_events(Gdk.EventMask.BUTTON_RELEASE_MASK |
                    Gdk.EventMask.KEY_RELEASE_MASK |
                    Gdk.EventMask.KEY_PRESS_MASK |
                    Gdk.EventMask.POINTER_MOTION_MASK);

        var toolbar = builder.get_object ("toolbar") as Gtk.Widget;
        toolbar.get_style_context().add_class("primary-toolbar");

        var inline_toolbar = builder.get_object ("pies-toolbar") as Gtk.Widget;
        inline_toolbar.get_style_context().add_class("inline-toolbar");

        this.pie_list = new PieList();
        this.pie_list.on_select.connect(this.on_pie_select);
        this.pie_list.on_activate.connect(() => {
            this.on_edit_pie_button_clicked();
        });

        var scroll_area = builder.get_object("pies-scrolledwindow") as Gtk.ScrolledWindow;
        scroll_area.add(this.pie_list);

        this.preview = new PiePreview();
        this.preview.on_first_slice_added.connect(() => {
            this.no_slice_label.hide();
        });

        this.preview.on_last_slice_removed.connect(() => {
            this.no_slice_label.show();
        });

        preview_box = builder.get_object("preview-box") as Gtk.Box;
        this.preview_box.pack_start(preview, true, true);
        this.no_pie_label = builder.get_object("no-pie-label") as Gtk.Label;
        this.no_slice_label = builder.get_object("no-slice-label") as Gtk.Label;
        this.preview_background = builder.get_object("preview-background") as Gtk.EventBox;

        (builder.get_object("settings-button") as Gtk.ToolButton).clicked.connect(on_settings_button_clicked);

        this.remove_pie_button = builder.get_object("remove-pie-button") as Gtk.ToolButton;
        this.remove_pie_button.clicked.connect(on_remove_pie_button_clicked);

        this.edit_pie_button = builder.get_object("edit-pie-button") as Gtk.ToolButton;
        this.edit_pie_button.clicked.connect(on_edit_pie_button_clicked);

        (builder.get_object("add-pie-button") as Gtk.ToolButton).clicked.connect(on_add_pie_button_clicked);

        this.window.hide.connect(() => {
            // save settings on close
            Config.global.save();
            Pies.save();

            // Timeout.add(100, () => {
            //     IconSelectWindow.clear_icons();
            //     return false;
            // });
        });

        this.window.delete_event.connect(this.window.hide_on_delete);
    }

    /////////////////////////////////////////////////////////////////////
    /// Shows the window.
    /////////////////////////////////////////////////////////////////////

    public void show() {
        this.preview.draw_loop();
        this.window.show_all();
        this.pie_list.select_first();

        var style = this.preview_background.get_style_context();
        this.preview_background.override_background_color(Gtk.StateFlags.NORMAL, style.get_background_color(Gtk.StateFlags.NORMAL));
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when a new Pie is selected in the PieList.
    /////////////////////////////////////////////////////////////////////

    private void on_pie_select(string id) {
        selected_id = id;

        this.no_slice_label.hide();
        this.no_pie_label.hide();
        this.preview_box.hide();

        this.remove_pie_button.sensitive = false;
        this.edit_pie_button.sensitive = false;

        if (id == "") {
            this.no_pie_label.show();
        } else {
            var pie = PieManager.all_pies[selected_id];

            this.preview.set_pie(id);
            this.preview_box.show();

            if (pie.action_groups.size == 0) {
                this.no_slice_label.show();
            }

            this.remove_pie_button.sensitive = true;
            this.edit_pie_button.sensitive = true;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the add Pie button is clicked.
    /////////////////////////////////////////////////////////////////////

    private void on_add_pie_button_clicked(Gtk.ToolButton button) {
        var new_pie = PieManager.create_persistent_pie(_("New Pie"), "stock_unknown", null);
        this.pie_list.reload_all();
        this.pie_list.select(new_pie.id);

        this.on_edit_pie_button_clicked();
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
    /// Called when the edit pie button is clicked.
    /////////////////////////////////////////////////////////////////////

    private void on_edit_pie_button_clicked(Gtk.ToolButton? button = null) {
        if (this.pie_options_window == null) {
            this.pie_options_window = new PieOptionsWindow();
            this.pie_options_window.set_parent(window);
            this.pie_options_window.on_ok.connect((trigger, name, icon) => {
                var pie = PieManager.all_pies[selected_id];
                pie.name = name;
                pie.icon = icon;
                PieManager.bind_trigger(trigger, selected_id);
                PieManager.create_launcher(pie.id);
                this.pie_list.reload_all();
            });
        }

        this.pie_options_window.set_pie(selected_id);
        this.pie_options_window.show();
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
}

}
