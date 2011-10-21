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
/// Not ready yet
/////////////////////////////////////////////////////////////////////////

public class AcceleratorSelectWindow : Gtk.Dialog {
    
    public signal void on_select(string icon_name);
    
    public AcceleratorSelectWindow() {
        this.title = _("Define an open-command");
        this.set_size_request(300, 250);
        this.delete_event.connect(hide_on_delete);

        var container = new Gtk.VBox(false, 6);
            container.set_border_width(6);
        
            var label = new Gtk.Label(null);
                label.set_line_wrap(true);
                label.width_request = 288;
                label.set_markup(_("Please press your desired <b>hot key</b>. If you want to bind the Pie to a <b>button of your mouse</b>, click with a button of your choice in the area below. You can also hold some modifier keys while clicking."));
                
            container.pack_start(label, true);
            
            var click_frame = new Gtk.Frame("Click area");
            
                var click_box = new Gtk.EventBox();
                    click_box.height_request = 50;
                    click_box.button_press_event.connect(on_area_clicked);
                    
                click_frame.add(click_box);
                
            container.pack_start(click_frame, false);
            
            var clickhold = new Gtk.CheckButton.with_label (_("Click & hold"));
                clickhold.tooltip_text = _("If checked, the Pie will close when you release the chosen hot key.");
                clickhold.active = false;
                
            container.pack_start(clickhold, false);
                
            var delayed = new Gtk.CheckButton.with_label (_("Long press for activation"));
                delayed.tooltip_text = _("If checked, the Pie will only open if you press this hot key a bit longer.");
                delayed.active = false;
                
            container.pack_start(delayed, false);

        container.show_all();
        
        this.vbox.pack_start(container, true, true);
    }
    
    bool on_area_clicked(Gdk.EventButton event) {
        debug("%u", event.button);
        return true;
    }
}

}
