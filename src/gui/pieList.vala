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

    class PieList : Gtk.TreeView {
    
        private Gtk.TreeIter active{private get; private set;}
    
        public PieList() {
            GLib.Object();
            
            var data = new Gtk.ListStore(2, typeof(string), typeof(string));
            base.set_model(data);
            base.set_headers_visible(false);
            base.set_rules_hint(true);
            base.set_grid_lines(Gtk.TreeViewGridLines.NONE);
            
            var icon_column = new Gtk.TreeViewColumn();
            var icon_render = new Gtk.CellRendererPixbuf();
            icon_render.icon_name = "firefox";
            icon_render.stock_size = Gtk.IconSize.DIALOG;
            icon_column.pack_start(icon_render, true);
            
            var theme_column = new Gtk.TreeViewColumn();
            var theme_render = new Gtk.CellRendererText();
            theme_column.pack_start(theme_render, true);
            
            base.append_column(icon_column);
            base.append_column(theme_column);
            
            icon_column.add_attribute(icon_render, "icon_name", 0);
            theme_column.add_attribute(theme_render, "markup", 1);
            
            var themes = Settings.global.themes;
            foreach(var theme in themes) {
                Gtk.TreeIter current;
                data.append(out current);
                data.set(current, 0, "firefox"); 
                data.set(current, 1, "<b>" + theme.name + "</b>\n" + theme.description); 
                if(theme == Settings.global.theme)
                    this.active = current;
            }  
        }
    }

}
