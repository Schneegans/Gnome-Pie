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

// A cellrenderer which displays an Icon. When clicked onto, a window opens
// for selecting another icon. This needs to be a subclass of Gtk.CellRenderer
// because Gtk.CellRendererPixbuf can't receive click events. Internally it
// stores a Gtk.CellRendererPixbuf, which renders and stuff.

public class CellRendererIcon : Gtk.CellRendererText {

    private IconSelectWindow select_window = null;
    private Gtk.CellRendererPixbuf renderer = null;
    private string current_path = "";
    
    public signal void on_select(string path, string icon);
    
    // forward CellRendererPixbuf's interface
    public bool follow_state {
        get { return renderer.follow_state; }
        set { renderer.follow_state = value; }
    }
    
    public string icon_name { 
        owned get { return renderer.icon_name; }
        set { renderer.icon_name = value; }
    }
    
    public uint stock_size {
        get { return renderer.stock_size; }
        set { renderer.stock_size = value; }
    }
    
    public bool icon_sensitive {
        get { return renderer.sensitive; }
        set { renderer.sensitive = value; }
    }

    // c'tor
    public CellRendererIcon() {
        this.select_window = new IconSelectWindow();  
        this.renderer = new Gtk.CellRendererPixbuf();
    
        this.select_window.on_select.connect((icon) => {
            this.icon_name = icon;
            this.on_select(current_path, icon);
        });
    }
    
    public override void get_size (Gtk.Widget widget, Gdk.Rectangle? cell_area,
                               out int x_offset, out int y_offset,
                               out int width, out int height) {

        this.renderer.get_size(widget, cell_area, out x_offset, out y_offset, out width, out height);
    }
    
    public override void render (Gdk.Window window, Gtk.Widget widget,
                             Gdk.Rectangle bg_area,
                             Gdk.Rectangle cell_area,
                             Gdk.Rectangle expose_area,
                             Gtk.CellRendererState flags) {
                             
        this.renderer.render(window, widget, bg_area, cell_area, expose_area, flags);
    }
    
    public override unowned Gtk.CellEditable start_editing(
        Gdk.Event event, Gtk.Widget widget, string path, Gdk.Rectangle bg_area, 
        Gdk.Rectangle cell_area, Gtk.CellRendererState flags) {
        
        this.current_path = path;
        this.select_window.show();
        this.select_window.active_icon = this.icon_name;
            
        return this.renderer.start_editing(event, widget, path, bg_area, cell_area, flags);
    }
}

}

