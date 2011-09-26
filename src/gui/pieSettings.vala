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
/// 
/////////////////////////////////////////////////////////////////////////

public class PieSettings : Gtk.VBox {
    
    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////
    
    public PieSettings() {
               
        this.spacing = 6;
        this.homogeneous = false;
        this.border_width = 12;
            
        // pie selection drop down
        var pie_hbox = new Gtk.HBox(false, 6);
            var pie_select = new Gtk.ComboBox.text();
            pie_hbox.pack_start(pie_select, true, true);
         
        // add pie button  
        var add_pie_button = new Gtk.Button();
            add_pie_button.tooltip_text = _("Add a new Pie.");

            var add_image = new Gtk.Image.from_stock(Gtk.Stock.ADD, Gtk.IconSize.BUTTON);
            add_pie_button.add(add_image);
            add_pie_button.clicked.connect (() => {
                debug("Add!");
            });

            pie_hbox.pack_start(add_pie_button, false, false);
        
        // remove pie button
        var del_pie_button = new Gtk.Button();
            del_pie_button.tooltip_text = _("Delete the current Pie.");

            var del_image = new Gtk.Image.from_stock(Gtk.Stock.DELETE, Gtk.IconSize.BUTTON);
            del_pie_button.add(del_image);
            del_pie_button.clicked.connect (() => {
                debug("Remove!");
            });

            pie_hbox.pack_start(del_pie_button, false, false);
            
        //this.pack_start(pie_hbox, false, false);

        // pie render container
        var pie_preview = new PiePreview(); 
        this.pack_start(pie_preview, true, true);
        
        // settings container
        var settings_frame = new Gtk.Frame(null);
            settings_frame.set_shadow_type(Gtk.ShadowType.NONE);
            var settings_frame_label = new Gtk.Label(null);
            settings_frame_label.set_markup(Markup.printf_escaped("<b>%s</b>", _("Pie Settings")));
            settings_frame.set_label_widget(settings_frame_label);
            
            // icon/settings hbox
            var settings_hbox = new Gtk.HBox(false, 6);
            
                // icon button
                var settings_icon = new Gtk.Button();
                settings_hbox.pack_start(settings_icon, false, false);   
                
                // settings vbox
                var settings_vbox = new Gtk.VBox(true, 6);
                
                    // name
                    var settings_name = new Gtk.ComboBox.text();
                    settings_vbox.pack_start(settings_name, false, false);
                    
                    // type
                    var settings_type = new Gtk.ComboBox.text();
                    settings_vbox.pack_start(settings_type, false, false);
                    
                    // command
                    var settings_command = new Gtk.ComboBox.text();
                    settings_vbox.pack_start(settings_command, false, false);
                    
                settings_hbox.pack_start(settings_vbox, true, true);
                
            settings_frame.add(settings_hbox);
            
        this.pack_start(settings_frame, false, false);
    }
}

}
