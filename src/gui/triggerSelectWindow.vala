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

public class TriggerSelectWindow : Gtk.Dialog {
    
    public signal void on_select(Trigger trigger);
    
    private Gtk.CheckButton turbo;
    private Gtk.CheckButton delayed;
    
    public TriggerSelectWindow() {
        this.title = _("Define an open-command");
        this.resizable = false;
        this.delete_event.connect(hide_on_delete);
        this.key_press_event.connect(on_key_press);
        this.button_press_event.connect(on_button_press);
        
        this.show.connect_after(() => {
            FocusGrabber.grab(this);
        });
        
        this.hide.connect(() => {
            FocusGrabber.ungrab(this);
        });

        var container = new Gtk.VBox(false, 6);
            container.set_border_width(6);
        
            var label = new Gtk.Label(null);
                label.set_line_wrap(true);
                label.width_request = 288;
                label.set_markup(_("Please press your desired <b>hot key</b>. If you want to bind the Pie to a <b>button of your mouse</b>, click with a button of your choice in the area below. You can also hold some modifier keys while clicking. Press <b>Esc to cancel</b> this dialog, <b>Backspace to unbind</b> the pie."));
                
            container.pack_start(label, true);
            
            var click_frame = new Gtk.Frame("Click area");
            
                var click_box = new Gtk.EventBox();
                    click_box.height_request = 50;
                    click_box.button_press_event.connect(on_area_clicked);
                    
                click_frame.add(click_box);
                
            container.pack_start(click_frame, false);
            
            this.turbo = new Gtk.CheckButton.with_label (_("Turbo mode"));
                this.turbo.tooltip_text = _("If checked, the Pie will close when you release the chosen hot key.");
                this.turbo.active = false;
                
            container.pack_start(turbo, false);
                
            this.delayed = new Gtk.CheckButton.with_label (_("Long press for activation"));
                this.delayed.tooltip_text = _("If checked, the Pie will only open if you press this hot key a bit longer.");
                this.delayed.active = false;
                
            container.pack_start(delayed, false);

        container.show_all();
        
        this.vbox.pack_start(container, true, true);
    }
    
    public void set_trigger(Trigger trigger) {
        this.turbo.active = trigger.turbo;
        this.delayed.active = trigger.delayed;
    }
    
    private bool on_area_clicked(Gdk.EventButton event) {
        var trigger = new Trigger.from_values((int)event.button, event.state, true, this.turbo.active, this.delayed.active);
        if (trigger.name.contains("button1")) {
            var dialog = new Gtk.MessageDialog((Gtk.Window)this.get_toplevel(), Gtk.DialogFlags.MODAL, 
                                                Gtk.MessageType.WARNING, 
                                                Gtk.ButtonsType.YES_NO, 
                                                _("It possible to make your system unusable if you bind a Pie to your left mouse button. Do you really want to do this?"));
                                                 
            dialog.response.connect((response) => {
                if (response == Gtk.ResponseType.YES) {
                    this.select(trigger);
                }
            });
            
            dialog.run();
            dialog.destroy();
        } else {
            this.select(trigger);
        }
        
        return true;
    }
    
    private bool on_key_press(Gdk.EventKey event) {
        if (Gdk.keyval_name(event.keyval) == "Escape") {
            this.hide();
        } else if (Gdk.keyval_name(event.keyval) == "BackSpace") {
            this.select(new Trigger());
        } else if (event.is_modifier == 0) {
            this.select(new Trigger.from_values((int)event.keyval, event.state, false, this.turbo.active, this.delayed.active));
        }
        
        return true;
    }
    
    private bool on_button_press(Gdk.EventButton event) {
        int width = 0, height = 0;
        this.window.get_geometry(null, null, out width, out height, null);
        if (event.x < 0 || event.x > width || event.y < 0 || event.y > height)
            this.hide();
        return true;
    }
    
    private void select(Trigger trigger) {
        this.on_select(trigger);
        this.hide();
    }
}

}
