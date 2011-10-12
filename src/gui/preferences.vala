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

public class Preferences : Gtk.Window {
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs the whole dialog. Many thanks to the
    /// synapse-project, since some of this code is taken from there! 
    /////////////////////////////////////////////////////////////////////
    
    public Preferences() {
        this.title = _("Gnome-Pie - Settings");
        this.set_position(Gtk.WindowPosition.CENTER);
        this.set_size_request(550, 550);
        this.resizable = false;
        this.icon_name = "gnome-pie";
        this.delete_event.connect(hide_on_delete);
        
        // main container
        var main_vbox = new Gtk.VBox(false, 12);
            main_vbox.border_width = 12;
            add(main_vbox);

            // tab container
            var tabs = new Gtk.Notebook();
            
                // general tab
                var general_tab = new Gtk.VBox(false, 6);
                    general_tab.border_width = 12;
                    
                    // behavior frame
                    var behavior_frame = new Gtk.Frame(null);
                        behavior_frame.set_shadow_type(Gtk.ShadowType.NONE);
                        var behavior_frame_label = new Gtk.Label(null);
                        behavior_frame_label.set_markup(Markup.printf_escaped ("<b>%s</b>", _("Behavior")));
                        behavior_frame.set_label_widget(behavior_frame_label);

                        var behavior_vbox = new Gtk.VBox (false, 6);
                        var align = new Gtk.Alignment (0.5f, 0.5f, 1.0f, 1.0f);
                        align.set_padding (6, 12, 12, 12);
                        align.add (behavior_vbox);
                        behavior_frame.add (align);

                        // Autostart checkbox
                        var autostart = new Gtk.CheckButton.with_label (_("Startup on Login"));
                            autostart.tooltip_text = _("If checked, Gnome-Pie will start when you log in.");
                            autostart.active = Config.global.auto_start;
                            autostart.toggled.connect(autostart_toggled);
                            behavior_vbox.pack_start(autostart, false);

                        // Indicator icon 
                        var indicator = new Gtk.CheckButton.with_label (_("Show Indicator"));
                            indicator.tooltip_text = _("If checked, an indicator for easy access of the settings menu is shown in your panel.");
                            indicator.active = Config.global.show_indicator;
                            indicator.toggled.connect(indicator_toggled);
                            behavior_vbox.pack_start(indicator, false);
                            
                        // Open Pies at Mouse
                        var open_at_mouse = new Gtk.CheckButton.with_label (_("Open Pies at Mouse"));
                            open_at_mouse.tooltip_text = _("If checked, pies will open at your pointer. Otherwise they'll pop up in the middle of the screen.");
                            open_at_mouse.active = Config.global.open_at_mouse;
                            open_at_mouse.toggled.connect(open_at_mouse_toggled);
                            behavior_vbox.pack_start(open_at_mouse, false);
                            
                        // Click to activate
                        var click_to_activate = new Gtk.CheckButton.with_label (_("Turbo mode"));
                            click_to_activate.tooltip_text = _("If checked, the pie closes when its keystroke is released. The currently hovered slice gets executed. This allows very fast selection but disables keyboard navigation.");
                            click_to_activate.active = Config.global.turbo_mode;
                            click_to_activate.toggled.connect(turbo_mode_toggled);
                            behavior_vbox.pack_start(click_to_activate, false);
                            
                        // Slider
                        var slider_hbox = new Gtk.HBox (false, 6);
                            behavior_vbox.pack_start(slider_hbox);
                            
                            var scale_label = new Gtk.Label(_("Global Scale"));
                                slider_hbox.pack_start(scale_label, false, false);
                            
                            var scale_slider = new Gtk.HScale.with_range(0.5, 2.0, 0.05);
                                scale_slider.set_value(Config.global.global_scale);
                                scale_slider.value_pos = Gtk.PositionType.RIGHT;
                                
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
                                
                                slider_hbox.pack_end(scale_slider, true, true);

                    general_tab.pack_start (behavior_frame, false);
                    
                    // theme frame
                    var theme_frame = new Gtk.Frame(null);
                        theme_frame.set_shadow_type(Gtk.ShadowType.NONE);
                        var theme_frame_label = new Gtk.Label(null);
                        theme_frame_label.set_markup(Markup.printf_escaped("<b>%s</b>", _("Themes")));
                        theme_frame.set_label_widget(theme_frame_label);
                        
                        // scrollable frame
                        var scroll = new Gtk.ScrolledWindow (null, null);
                            align = new Gtk.Alignment(0.5f, 0.5f, 1.0f, 1.0f);
                            align.set_padding(6, 12, 12, 12);
                            align.add(scroll);
                            theme_frame.add(align);

                            scroll.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
                            scroll.set_shadow_type (Gtk.ShadowType.IN);
                            
                            // themes list
                            var theme_list = new ThemeList();
                                scroll.add(theme_list);

                general_tab.pack_start (theme_frame, true, true);
                tabs.append_page(general_tab, new Gtk.Label(_("General")));
                
                // pies tab
                var pies_tab = new Gtk.VBox(false, 6);
                    pies_tab.border_width = 12;
                    tabs.append_page(pies_tab, new Gtk.Label(_("Pies")));
                        
                    // scrollable frame
                    scroll = new Gtk.ScrolledWindow (null, null);
                        align = new Gtk.Alignment(0.5f, 0.5f, 1.0f, 1.0f);
                        align.add(scroll);
                        pies_tab.add(align);

                        scroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
                        scroll.set_shadow_type (Gtk.ShadowType.IN);
                        
                        // pies list
                        var pie_list = new PieList();
                            scroll.add(pie_list);
                        
                    // bottom box
                    var info_box = new Gtk.HBox (false, 6);
                    
                        // info image
                        var info_image = new Gtk.Image.from_stock (Gtk.Stock.INFO, Gtk.IconSize.MENU);
                            info_box.pack_start (info_image, false);

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
                                _("It's possible to drag'n'drop files and folders from your file browser to the list above.")
                            });
                            this.show.connect(info_label.start_slide_show);
                            this.hide.connect(info_label.stop_slide_show);
                            
                            info_box.pack_start (info_label);
                        
                        // down Button
                        var down_button = new Gtk.Button();
                            down_button.tooltip_text = _("Moves the selected Slice down");
                            down_button.sensitive = false;
                            var down_image = new Gtk.Image.from_stock (Gtk.Stock.GO_DOWN, Gtk.IconSize.LARGE_TOOLBAR);
                            down_button.add(down_image);
                            down_button.clicked.connect (() => {
                                pie_list.selection_down();
                            });

                            info_box.pack_end(down_button, false, false);
                        
                        // up Button
                        var up_button = new Gtk.Button();
                            up_button.tooltip_text = _("Moves the selected Slice up");
                            up_button.sensitive = false;
                            var up_image = new Gtk.Image.from_stock (Gtk.Stock.GO_UP, Gtk.IconSize.LARGE_TOOLBAR);
                            up_button.add(up_image);
                            up_button.clicked.connect (() => {
                                pie_list.selection_up();
                            });
                            
                            info_box.pack_end(up_button, false, false);
                            
                        pie_list.get_selection().changed.connect(() => {
                            Gtk.TreeIter selected;
                            if (pie_list.get_selection().get_selected(null, out selected)) {
                                Gtk.TreePath path = pie_list.model.get_path(selected);
                                if (path.get_depth() == 1) {
                                    up_button.sensitive = false;
                                    down_button.sensitive = false;
                                } else {
                                    up_button.sensitive = true;
                                    down_button.sensitive = true;
                                    
                                    int child_pos = path.get_indices()[1];

                                    if (child_pos == 0)
                                        up_button.sensitive = false;
                                    
                                    path.up();
                                    Gtk.TreeIter parent_iter;
                                    pie_list.model.get_iter(out parent_iter, path);
                                    if (child_pos == pie_list.model.iter_n_children(parent_iter)-1)
                                        down_button.sensitive = false;
                                    
                                }
                            }
                        });
                        
                        pies_tab.pack_start (info_box, false);
                
                main_vbox.pack_start(tabs);

            // close button 
            var bbox = new Gtk.HButtonBox ();
                bbox.set_layout (Gtk.ButtonBoxStyle.END);
                var close_button = new Gtk.Button.from_stock (Gtk.Stock.CLOSE);
                close_button.clicked.connect (() => { 
                    hide();
                    // save settings on close
                    Config.global.save();
                    Pies.save();
                });
                bbox.pack_start (close_button);

                main_vbox.pack_start(bbox, false);
                
            main_vbox.show_all();
    }

    /////////////////////////////////////////////////////////////////////
    /// Creates or deletes the autostart file. This code is inspired
    /// by project synapse as well.
    /////////////////////////////////////////////////////////////////////
    
    private void autostart_toggled(Gtk.ToggleButton check_box) {
        bool active = check_box.active;
        if (!active && FileUtils.test(Paths.autostart, FileTest.EXISTS)) {
            // delete the autostart file
            FileUtils.remove (Paths.autostart);
        }
        else if (active && !FileUtils.test(Paths.autostart, FileTest.EXISTS)) {
            string autostart_entry = 
                "#!/usr/bin/env xdg-open\n" + 
                "[Desktop Entry]\n" +
                "Name=Gnome-Pie\n" +
                "Exec=gnome-pie\n" +
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
                var d = new Gtk.MessageDialog (this, 0, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE,
                                           "%s", e.message);
                d.run ();
                d.destroy ();
            }
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Shows or hides the indicator.
    /////////////////////////////////////////////////////////////////////
    
    private void indicator_toggled(Gtk.ToggleButton check_box) {
        var check = check_box as Gtk.CheckButton;
        Config.global.show_indicator = check.active;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Toggles whether the Pies are shown at the mouse or in the middle
    /// of the screen.
    /////////////////////////////////////////////////////////////////////
    
    private void open_at_mouse_toggled(Gtk.ToggleButton check_box) {
        var check = check_box as Gtk.CheckButton;
        Config.global.open_at_mouse = check.active;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Toggles whether the user has to click with the mouse in order to
    /// activate a slice.
    /////////////////////////////////////////////////////////////////////
    
    private void turbo_mode_toggled(Gtk.ToggleButton check_box) {
        var check = check_box as Gtk.CheckButton;
        Config.global.turbo_mode = check.active;
    }
}

}
