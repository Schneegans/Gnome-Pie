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
            
                
        // upper container
        var upper_hbox = new Gtk.HBox(false, 6);
            
            // scrollable frame
            var scroll = new Gtk.ScrolledWindow (null, null);
                scroll.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
                scroll.set_shadow_type (Gtk.ShadowType.IN);
                
                // pie list
                var pie_list = new PieList();
                    scroll.add(pie_list);
                    
            upper_hbox.pack_start(scroll, true, true);
    
            // pie selection box
            var pie_vbox = new Gtk.VBox(false, 6);
             
                // add pie button  
                var add_pie_button = new Gtk.Button();
                    add_pie_button.tooltip_text = _("Add a new Pie.");

                    var add_image = new Gtk.Image.from_stock(Gtk.Stock.ADD, Gtk.IconSize.BUTTON);
                    add_pie_button.add(add_image);
                    add_pie_button.clicked.connect (() => {
                        debug("Add!");
                    });

                    pie_vbox.pack_start(add_pie_button, false, false);
                
                // remove pie button
                var del_pie_button = new Gtk.Button();
                    del_pie_button.tooltip_text = _("Delete the current Pie.");

                    var del_image = new Gtk.Image.from_stock(Gtk.Stock.DELETE, Gtk.IconSize.BUTTON);
                    del_pie_button.add(del_image);
                    del_pie_button.clicked.connect (() => {
                        debug("Remove!");
                    });

                    pie_vbox.pack_start(del_pie_button, false, false);
                    
                // remove pie button
                var edit_pie_button = new Gtk.Button();
                    edit_pie_button.tooltip_text = _("Delete the current Pie.");

                    var edit_image = new Gtk.Image.from_stock(Gtk.Stock.EDIT, Gtk.IconSize.BUTTON);
                    edit_pie_button.add(edit_image);
                    edit_pie_button.clicked.connect (() => {
                        debug("Edit!");
                    });

                pie_vbox.pack_start(edit_pie_button, false, false);
        
            upper_hbox.pack_start(pie_vbox, false, false);
            
        this.pack_start(upper_hbox, false, false);

        // pie render container
        var pie_preview = new PiePreview(); 
            pie_list.on_select.connect((id) => {
                pie_preview.set_pie(id);
            });
        
        this.pack_start(pie_preview, true, true);
        
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
                    _("It's possible to drag'n'drop files and folders from your file browser to the list above."),
                    _("It's recommended to keep your Pies small (at most 6-8 Slices). Else they will become hard to navigate."),
                    _("In order to create a launcher for a Pie, drag the Pie from the list to your desktop!")
                });
                this.show.connect(info_label.start_slide_show);
                this.hide.connect(info_label.stop_slide_show);
                
            info_box.pack_start (info_label);
            
            // add slice button  
            var add_slice_button = new Gtk.Button();
                add_slice_button.tooltip_text = _("Add a new slice.");

                add_image = new Gtk.Image.from_stock(Gtk.Stock.ADD, Gtk.IconSize.BUTTON);
                add_slice_button.add(add_image);
                add_slice_button.clicked.connect (() => {
                    debug("Add!");
                });

            info_box.pack_end(add_slice_button, false, false);
            
            // remove slice button
            var del_slice_button = new Gtk.Button();
                del_slice_button.tooltip_text = _("Delete the current slice.");

                del_image = new Gtk.Image.from_stock(Gtk.Stock.DELETE, Gtk.IconSize.BUTTON);
                del_slice_button.add(del_image);
                del_slice_button.clicked.connect (() => {
                    debug("Remove!");
                });

                info_box.pack_end(del_slice_button, false, false);
                
            // remove slice button
            var edit_slice_button = new Gtk.Button();
                edit_slice_button.tooltip_text = _("Delete the current slice.");

                edit_image = new Gtk.Image.from_stock(Gtk.Stock.EDIT, Gtk.IconSize.BUTTON);
                edit_slice_button.add(edit_image);
                edit_slice_button.clicked.connect (() => {
                    debug("Edit!");
                });
                
            info_box.pack_end(edit_slice_button, false, false);
            
        this.pack_start(info_box, false, false);
        
        this.show.connect(() => {
            Timeout.add((uint)(1000.0/Config.global.refresh_rate), () => {
                pie_preview.queue_draw();
                return this.visible;
            }); 
        });
        
    }
}

}
