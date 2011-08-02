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
    
    // a cellrenderer which can change it's type: Depending
    // on it's morph_mode it can look like a CellRendererText,
    // a CellRendererCombo or a CellRendererAccel 
    public class CellRendererMorph : Gtk.CellRendererText {
    
        public enum Mode { TEXT, ACCEL, COMBO }
    
        // private stuff
        private Gtk.CellRendererAccel renderer_accel;
        private Gtk.CellRendererCombo renderer_combo;
        private string own_path = "";

        public Mode morph_mode { get; set; }
        
        public Gtk.TreeModel model { 
            set{ renderer_combo.model = value; } 
            owned get{ return renderer_combo.model; } 
        } 
        
        public signal void text_edited(string path, string text);

        public CellRendererMorph () {
            
            this.renderer_combo = new Gtk.CellRendererCombo();
            this.renderer_combo.editable = true;
            this.renderer_combo.has_entry = false;
            this.renderer_combo.text_column = 0;
            this.renderer_combo.changed.connect((path, iter) => {
                string text = "";
                this.model.get(iter, 0, out text);
                this.text_edited(own_path, text);
            });
            
            this.renderer_accel = new Gtk.CellRendererAccel();
            this.renderer_accel.editable = true;
            this.renderer_accel.accel_edited.connect((a, path, accel_key, accel_mods, keycode) => {
                string keyname = Gtk.accelerator_get_label(accel_key, accel_mods);
                this.text_edited(path, keyname);
            });
            
            this.renderer_accel.accel_cleared.connect((a, path) => {
                this.text_edited(own_path, renderer_accel.text);
            });
            
            this.morph_mode = Mode.TEXT;
            
            this.notify["text"].connect(() => {
            
                if (this.text == "") {
                    renderer_accel.text = _("Not bound");
                    
                    string text = "";
                    Gtk.TreeIter iter = Gtk.TreeIter();
                    if (model.get_iter_first(out iter))
                        this.model.get(iter, 0, out text);
                    renderer_combo.text = text;
                } else {
                    renderer_accel.text = this.text;
                    renderer_combo.text = this.text;
                }
            });
            
            this.edited.connect((path, text) => {
                this.text_edited(path, text);
            });
        }
        
        public override unowned Gtk.CellEditable start_editing(
            Gdk.Event event, Gtk.Widget widget, string path, Gdk.Rectangle bg_area, 
            Gdk.Rectangle cell_area, Gtk.CellRendererState flags) {
            
            this.own_path = path;
            
            if (this.editable) {
                switch (this.morph_mode) {
                    case Mode.TEXT:
                        return base.start_editing(event, widget, path, bg_area, cell_area, flags);
                    case Mode.ACCEL:
                        return this.renderer_accel.start_editing(event, widget, path, bg_area, cell_area, flags);
                    case Mode.COMBO:
                        return this.renderer_combo.start_editing(event, widget, path, bg_area, cell_area, flags);
                }
            } 
                
            return null;
        }
        
        public override void render (Gdk.Window window, Gtk.Widget widget, Gdk.Rectangle bg_area,
            Gdk.Rectangle cell_area, Gdk.Rectangle expose_area, Gtk.CellRendererState flags) {
            
            switch (this.morph_mode) {
                case Mode.TEXT:
                    base.render(window, widget, bg_area, cell_area, expose_area, flags);
                    break;
                case Mode.ACCEL:
                    this.renderer_accel.render(window, widget, bg_area, cell_area, expose_area, flags);
                    break;
                case Mode.COMBO:
                    this.renderer_combo.render(window, widget, bg_area, cell_area, expose_area, flags);
                    break;
            }
        }
    }
}
