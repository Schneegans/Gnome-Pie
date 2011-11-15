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
        this.set_size_request(450, 550);
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
                            
                        // Slider
                        var slider_hbox = new Gtk.HBox(false, 6);
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
                
                var pies_tab = new PieSettings();
                tabs.append_page(pies_tab, new Gtk.Label(_("Pies")));

                main_vbox.pack_start(tabs);

            // close button 
            var bbox = new Gtk.HButtonBox();
                bbox.set_layout (Gtk.ButtonBoxStyle.END);
                var close_button = new Gtk.Button.from_stock(Gtk.Stock.CLOSE);
                close_button.clicked.connect (() => { 
                    hide();
                });
                bbox.pack_start(close_button);

                main_vbox.pack_start(bbox, false);
                
            main_vbox.show_all();
            
        this.hide.connect(() => {
            // save settings on close
            Config.global.save();
            Pies.save();
        });
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
}

}
