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
/// The settings menu of Gnome-Pie, with options for theme switching and
/// some general options.
/////////////////////////////////////////////////////////////////////////

public class SettingsWindow : GLib.Object {
    
    /////////////////////////////////////////////////////////////////////
    /// Some widgets.
    /////////////////////////////////////////////////////////////////////
    
    private Gtk.Dialog? window = null;
    private ThemeList? theme_list = null;
    private Gtk.ToggleButton? indicator = null;
    private Gtk.ToggleButton? autostart = null;
    private Gtk.ToggleButton? captions = null;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor creates, the dialog.
    /////////////////////////////////////////////////////////////////////
    
    public SettingsWindow() {
        try {
        
            Gtk.Builder builder = new Gtk.Builder();

            builder.add_from_file (Paths.ui_files + "/settings.ui");

            this.window = builder.get_object("window") as Gtk.Dialog;
            
            this.theme_list = new ThemeList();
            
            var scroll_area = builder.get_object("theme-scrolledwindow") as Gtk.ScrolledWindow;
                scroll_area.add(this.theme_list);
                
            (builder.get_object("close-button") as Gtk.Button).clicked.connect(on_close_button_clicked);
            
            this.autostart = (builder.get_object("autostart-checkbox") as Gtk.ToggleButton);
            this.autostart.toggled.connect(on_autostart_toggled);
            
            this.indicator = (builder.get_object("indicator-checkbox") as Gtk.ToggleButton);
            this.indicator.toggled.connect(on_indicator_toggled);
            
            this.captions = (builder.get_object("captions-checkbox") as Gtk.ToggleButton);
            this.captions.toggled.connect(on_captions_toggled);
            
            var scale_slider = (builder.get_object("scale-hscale") as Gtk.HScale);
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
                
            this.window.delete_event.connect(this.window.hide_on_delete);
                
        } catch (GLib.Error e) {
            error("Could not load UI: %s\n", e.message);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Sets the parent window, in order to make this window stay in
    /// front.
    /////////////////////////////////////////////////////////////////////
    
    public void set_parent(Gtk.Window parent) {
        this.window.set_transient_for(parent);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Displays the window on the screen.
    /////////////////////////////////////////////////////////////////////
    
    public void show() {
        this.indicator.active = Config.global.show_indicator;
        this.autostart.active = Config.global.auto_start;
        this.captions.active = Config.global.show_captions;
    
        this.window.show_all(); 
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Called when the close button is clicked.
    /////////////////////////////////////////////////////////////////////
    
    private void on_close_button_clicked() {
        this.window.hide();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Creates or deletes the autostart file. This code is inspired
    /// by project synapse as well.
    /////////////////////////////////////////////////////////////////////
    
    private void on_autostart_toggled(Gtk.ToggleButton check_box) {
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
                var d = new Gtk.MessageDialog (this.window, 0, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE,
                                           "%s", e.message);
                d.run ();
                d.destroy ();
            }
        }
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
}

}
