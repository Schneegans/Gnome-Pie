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

    private Gtk.Stack? stack = null;
    private Gtk.Notebook? notebook = null;

    private Gtk.Window? window = null;
    private Gtk.Label? no_pie_label = null;
    private Gtk.Label? no_slice_label = null;
    private Gtk.Box? preview_box = null;
    private Gtk.EventBox? preview_background = null;
    private Gtk.Button? remove_pie_button = null;
    private Gtk.Button? edit_pie_button = null;

    private ThemeList? theme_list = null;
    private Gtk.ToggleButton? indicator = null;
    private Gtk.ToggleButton? search_by_string = null;
    private Gtk.ToggleButton? autostart = null;
    private Gtk.ToggleButton? captions = null;

    /////////////////////////////////////////////////////////////////////
    /// Some custom widgets and dialogs used by this window.
    /////////////////////////////////////////////////////////////////////

    private PiePreview? preview = null;
    private PieList? pie_list = null;
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

        if (!Deamon.disable_header_bar) {
            var headerbar = new Gtk.HeaderBar();
            headerbar.show_close_button = true;
            headerbar.title = _("Gnome-Pie Settings");
            headerbar.subtitle = _("bake your pies!");
            window.set_titlebar(headerbar);
        }

        this.notebook = builder.get_object("notebook") as Gtk.Notebook;

        if (!Deamon.disable_stack_switcher) {
            var main_box = builder.get_object("main-box") as Gtk.Box;
            var pie_settings = builder.get_object("pie-settings") as Gtk.Box;
            var general_settings = builder.get_object("general-settings") as Gtk.Box;

            pie_settings.parent.remove(pie_settings);
            general_settings.parent.remove(general_settings);

            main_box.remove(this.notebook);

            Gtk.StackSwitcher switcher = new Gtk.StackSwitcher();
            switcher.margin_top = 10;
            switcher.set_halign(Gtk.Align.CENTER);
            main_box.pack_start(switcher, false, true, 0);

            this.stack = new Gtk.Stack();
            this.stack.transition_duration = 500;
            this.stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            this.stack.homogeneous = true;
            this.stack.halign = Gtk.Align.FILL;
            this.stack.expand = true;
            main_box.add(stack);
            switcher.set_stack(stack);

            this.stack.add_with_properties(general_settings, "name", "1", "title", _("General Settings"), null);
            this.stack.add_with_properties(pie_settings, "name", "2", "title", _("Pie Settings"), null);
        }

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

        this.remove_pie_button = builder.get_object("remove-pie-button") as Gtk.Button;
        this.remove_pie_button.clicked.connect(on_remove_pie_button_clicked);

        this.edit_pie_button = builder.get_object("edit-pie-button") as Gtk.Button;
        this.edit_pie_button.clicked.connect(on_edit_pie_button_clicked);

        (builder.get_object("add-pie-button") as Gtk.Button).clicked.connect(on_add_pie_button_clicked);

        this.theme_list = new ThemeList();
        this.theme_list.on_select_new.connect(() => {
            this.captions.active = Config.global.show_captions;
            if (Config.global.theme.has_slice_captions) {
                this.captions.sensitive = true;
            } else {
                this.captions.sensitive = false;
            }
        });

        scroll_area = builder.get_object("theme-scrolledwindow") as Gtk.ScrolledWindow;
        scroll_area.add(this.theme_list);

        (builder.get_object("theme-help-button") as Gtk.Button).clicked.connect(() => {
            try{
                GLib.AppInfo.launch_default_for_uri("http://simmesimme.github.io/lessons/2015/04/26/themes-for-gnome-pie/", null);
            } catch (Error e) {
                warning(e.message);
            }
        });

        (builder.get_object("theme-export-button") as Gtk.Button).clicked.connect(on_export_theme_button_clicked);
        (builder.get_object("theme-import-button") as Gtk.Button).clicked.connect(on_import_theme_button_clicked);

        this.autostart = (builder.get_object("autostart-checkbox") as Gtk.ToggleButton);
        this.autostart.toggled.connect(on_autostart_toggled);

        this.indicator = (builder.get_object("indicator-checkbox") as Gtk.ToggleButton);
        this.indicator.toggled.connect(on_indicator_toggled);

        this.search_by_string = (builder.get_object("select-by-string-checkbox") as Gtk.ToggleButton);
        this.search_by_string.toggled.connect(on_search_by_string_toggled);

        this.captions = (builder.get_object("captions-checkbox") as Gtk.ToggleButton);
        this.captions.toggled.connect(on_captions_toggled);

        var scale_slider = (builder.get_object("scale-hscale") as Gtk.Scale);
            scale_slider.set_range(0.5, 2.0);
            scale_slider.set_increments(0.05, 0.25);
            scale_slider.set_value(Config.global.global_scale);

            bool changing = false;
            bool changed_again = false;

            scale_slider.value_changed.connect(() => {
                if (!changing) {
                    changing = true;
                    Timeout.add(300, () => {
                        if (changed_again) {
                            changed_again = false;
                            return true;
                        }

                        Config.global.global_scale = scale_slider.get_value();
                        Config.global.load_themes(Config.global.theme.name);
                        changing = false;
                        return false;
                    });
                } else {
                    changed_again = true;
                }
            });

        var range_slider = (builder.get_object("range-hscale") as Gtk.Scale);
            range_slider.set_range(0, 2000);
            range_slider.set_increments(10, 100);
            range_slider.set_value(Config.global.activation_range);
            range_slider.value_changed.connect(() => {
                Config.global.activation_range = (int)range_slider.get_value();
            });

        var range_slices = (builder.get_object("range-slices") as Gtk.Scale);
            range_slices.set_range(12, 96);
            range_slices.set_increments(4, 12);
            range_slices.set_value(Config.global.max_visible_slices);
            range_slices.value_changed.connect(() => {
                Config.global.max_visible_slices = (int)range_slices.get_value();
            });

        var info_box = (builder.get_object("info-box") as Gtk.Box);

        // info label
        var info_label = new TipViewer({
            _("You can right-click in the list for adding or removing entries."),
            _("The radiobutton at the beginning of each slice-line indicates the QuickAction of the pie."),
            _("Pies can be opened with the terminal command \"gnome-pie --open=ID\"."),
            _("Feel free to visit Gnome-Pie's homepage at %s!").printf("<a href='http://gnome-pie.simonschneegans.de'>gnome-pie.simonschneegans.de</a>"),
            _("You can drag'n'drop applications from your main menu to the list above."),
            _("If you want to give some feedback, please write an e-mail to %s!").printf("<a href='mailto:code@simonschneegans.de'>code@simonschneegans.de</a>"),
            _("You may drag'n'drop URLs and bookmarks from your internet browser to the list above."),
            _("Bugs can be reported at %s!").printf("<a href='https://github.com/Simmesimme/Gnome-Pie'>Github</a>"),
            _("You can drag'n'drop files and folders from your file browser to the list above.")
        });
        this.window.show.connect(info_label.start_slide_show);
        this.window.hide.connect(info_label.stop_slide_show);

        info_box.pack_end(info_label);



        this.window.hide.connect(() => {
            // save settings on close
            Config.global.save();
            Pies.save();

            Timeout.add(100, () => {
                IconSelectWindow.clear_icons();
                return false;
            });
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

        this.indicator.active = Config.global.show_indicator;
        this.autostart.active = Config.global.auto_start;
        this.captions.active = Config.global.show_captions;
        this.search_by_string.active = Config.global.search_by_string;

        if (Config.global.theme.has_slice_captions) {
            this.captions.sensitive = true;
        } else {
            this.captions.sensitive = false;
        }

        if (!Deamon.disable_stack_switcher) {
            this.stack.set_visible_child_full("2", Gtk.StackTransitionType.NONE);
        } else {
            this.notebook.set_current_page(1);
        }
        this.pie_list.has_focus = true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates or deletes the autostart file. This code is inspired
    /// by project synapse as well.
    /////////////////////////////////////////////////////////////////////

    private void on_autostart_toggled(Gtk.ToggleButton check_box) {

        bool active = check_box.active;
        if (!active && FileUtils.test(Paths.autostart, FileTest.EXISTS)) {
            Config.global.auto_start = false;
            // delete the autostart file
            FileUtils.remove (Paths.autostart);
        }
        else if (active && !FileUtils.test(Paths.autostart, FileTest.EXISTS)) {
            Config.global.auto_start = true;

            string autostart_entry =
                "#!/usr/bin/env xdg-open\n" +
                "[Desktop Entry]\n" +
                "Name=Gnome-Pie\n" +
                "Exec=" + Paths.executable + "\n" +
                "Encoding=UTF-8\n" +
                "Type=Application\n" +
                "X-GNOME-Autostart-enabled=true\n" +
                "Icon=gnome-pie\n";

            // create the autostart file
            string autostart_dir = GLib.Path.get_dirname(Paths.autostart);
            if (!FileUtils.test(autostart_dir, FileTest.EXISTS | FileTest.IS_DIR)) {
                DirUtils.create_with_parents(autostart_dir, 0755);
            }

            try {
                FileUtils.set_contents(Paths.autostart, autostart_entry);
                FileUtils.chmod(Paths.autostart, 0755);
            } catch (Error e) {
                var d = new Gtk.MessageDialog(this.window, 0, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE,
                                           "%s", e.message);
                d.run();
                d.destroy();
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Saves the current theme to an archive.
    /////////////////////////////////////////////////////////////////////

    private void on_export_theme_button_clicked(Gtk.Button button) {
        var dialog = new Gtk.FileChooserDialog("Pick a file", this.window,
                                               Gtk.FileChooserAction.SAVE,
                                               "_Cancel",
                                               Gtk.ResponseType.CANCEL,
                                               "_Save",
                                               Gtk.ResponseType.ACCEPT);

        dialog.set_do_overwrite_confirmation(true);
        dialog.set_modal(true);
        dialog.filter = new Gtk.FileFilter();
        dialog.filter.add_pattern ("*.tar.gz");
        dialog.set_current_name(Config.global.theme.name + ".tar.gz");

        dialog.response.connect((d, result) => {
            if (result == Gtk.ResponseType.ACCEPT) {
                var file = dialog.get_filename();
                if (!file.has_suffix(".tar.gz")) {
                    file = file + ".tar.gz";
                }
                Config.global.theme.export(file);
            }
            dialog.destroy();
        });
        dialog.show();
    }

    /////////////////////////////////////////////////////////////////////
    /// Imports a new theme from an archive.
    /////////////////////////////////////////////////////////////////////

    private void on_import_theme_button_clicked(Gtk.Button button) {
        var dialog = new Gtk.FileChooserDialog("Pick a file", this.window,
                                               Gtk.FileChooserAction.OPEN,
                                               "_Cancel",
                                               Gtk.ResponseType.CANCEL,
                                               "_Open",
                                               Gtk.ResponseType.ACCEPT);

        dialog.set_modal(true);
        dialog.filter = new Gtk.FileFilter();
        dialog.filter.add_pattern ("*.tar.gz");

        var result = Gtk.MessageType.INFO;
        var message = _("Sucessfully imported new theme!");

        dialog.response.connect((d, r) => {
            if (r == Gtk.ResponseType.ACCEPT) {
                var file = dialog.get_filename();

                var a = new ThemeImporter();
                if (a.open(file)) {
                    if (a.is_valid_theme) {
                        if (!Config.global.has_theme(a.theme_name)) {
                            if (a.extract_to(Paths.local_themes + "/" + a.theme_name)) {
                                Config.global.load_themes(a.theme_name);
                                this.theme_list.reload();
                            } else {
                                message = _("An error occured while importing the theme: Failed to extract theme!");
                                result = Gtk.MessageType.ERROR;
                            }
                        } else {
                            message = _("An error occured while importing the theme: A theme with this name does already exist!");
                            result = Gtk.MessageType.ERROR;
                        }
                    } else {
                        message = _("An error occured while importing the theme: Theme archive does not contain a valid theme!");
                        result = Gtk.MessageType.ERROR;
                    }
                } else {
                    message = _("An error occured while importing the theme: Failed to open theme archive!");
                    result = Gtk.MessageType.ERROR;
                }
                a.close();

                var result_dialog = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL,
                                                          result, Gtk.ButtonsType.CLOSE, message);
                result_dialog.run();
                result_dialog.destroy();
            }
            dialog.destroy();

        });
        dialog.show();
    }

    /////////////////////////////////////////////////////////////////////
    /// Shows or hides the indicator.
    /////////////////////////////////////////////////////////////////////

    private void on_indicator_toggled(Gtk.ToggleButton check_box) {
        var check = check_box as Gtk.CheckButton;
        Config.global.show_indicator = check.active;
    }

    /////////////////////////////////////////////////////////////////////
    /// Shows or hides the captions of Slices.
    /////////////////////////////////////////////////////////////////////

    private void on_captions_toggled(Gtk.ToggleButton check_box) {
        var check = check_box as Gtk.CheckButton;
        Config.global.show_captions = check.active;
    }

    /////////////////////////////////////////////////////////////////////
    /// Enables or disables Slice selection by typing.
    /////////////////////////////////////////////////////////////////////

    private void on_search_by_string_toggled(Gtk.ToggleButton check_box) {
        var check = check_box as Gtk.CheckButton;
        Config.global.search_by_string = check.active;
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

    private void on_add_pie_button_clicked(Gtk.Button button) {
        var new_pie = PieManager.create_persistent_pie(_("New Pie"), "stock_unknown", null);
        this.pie_list.reload_all();
        this.pie_list.select(new_pie.id);

        this.on_edit_pie_button_clicked();
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the remove Pie button is clicked.
    /////////////////////////////////////////////////////////////////////

    private void on_remove_pie_button_clicked(Gtk.Button button) {
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

    private void on_edit_pie_button_clicked(Gtk.Button? button = null) {
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
}

}
