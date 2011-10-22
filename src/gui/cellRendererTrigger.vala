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
/// A CellRenderer which opens a TriggerSelectWindow.
/////////////////////////////////////////////////////////////////////////

public class CellRendererTrigger : Gtk.CellRendererText {
    
    /////////////////////////////////////////////////////////////////////
    /// This signal is emitted when the user selects another trigger.
    /////////////////////////////////////////////////////////////////////
    
    public signal void on_select(string path, Trigger trigger);
    
    /////////////////////////////////////////////////////////////////////
    /// The trigger which can be set with this window.
    /////////////////////////////////////////////////////////////////////
    
    public string trigger { get; set; }
    
    /////////////////////////////////////////////////////////////////////
    /// The IconSelectWindow which is shown on click.
    /////////////////////////////////////////////////////////////////////

    private TriggerSelectWindow select_window = null;
    
    /////////////////////////////////////////////////////////////////////
    /// A helper variable, needed to emit the current path.
    /////////////////////////////////////////////////////////////////////
    
    private string current_path = "";
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates a new CellRendererIcon.
    /////////////////////////////////////////////////////////////////////
    
    public CellRendererTrigger() {
        this.select_window = new TriggerSelectWindow();  
    
        this.select_window.on_select.connect((trigger) => {
            this.trigger = trigger.name;
            this.on_select(current_path, trigger);
        });
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Open the TriggerSelectWindow on click.
    /////////////////////////////////////////////////////////////////////
    
    public override unowned Gtk.CellEditable start_editing(
        Gdk.Event event, Gtk.Widget widget, string path, Gdk.Rectangle bg_area, 
        Gdk.Rectangle cell_area, Gtk.CellRendererState flags) {
        
        this.current_path = path;
        
        this.select_window.set_transient_for((Gtk.Window)widget.get_toplevel());
        this.select_window.set_modal(true);
        this.select_window.set_trigger(new Trigger.from_string(this.trigger));
                  
        this.select_window.show();
            
        return base.start_editing(event, widget, path, bg_area, cell_area, flags);
    }
}

}

