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

using GnomePie.Settings;

namespace GnomePie {

    Gdk.Pixbuf open_image (string icon) {
        try {
            return new Gdk.Pixbuf.from_file ("/usr/share/pixmaps/" + icon);
        } catch (Error e) {
            error ("%s", e.message);
        }
    }

    class ThemeList : Gtk.TreeView {
        public ThemeList() {
            GLib.Object();
            
            var cells = new Gtk.ListStore(2, typeof (Theme), typeof (string));
            set_model(cells);
            set_headers_visible(false);
            
            var renderer = new ThemeCellRenderer();
            var col = new Gtk.TreeViewColumn ();
            col.pack_start (renderer, true);
            col.add_attribute (renderer, "theme", 0);

            Gtk.TreeIter current;
            append_column (col);
            
            var themes = setting().themes;
            
            foreach(var theme in themes) {
                cells.append(out current);
                cells.set(current, 0, theme); 

            }

            
        }
    }

    class ThemeCellRenderer : Gtk.CellRenderer {

        public Theme theme { get; set; }

        public ThemeCellRenderer () {
            GLib.Object ();
        }

        public override void get_size (Gtk.Widget widget, Gdk.Rectangle? cell_area,
                                       out int x_offset, out int y_offset,
                                       out int width, out int height)
        {
            if (&x_offset != null) x_offset = 0;
            if (&y_offset != null) y_offset = 0;
            if (&width != null) width = 50;
            if (&height != null) height = 50;
        }

        public override void render (Gdk.Window window, Gtk.Widget widget,
                                     Gdk.Rectangle background_area,
                                     Gdk.Rectangle cell_area,
                                     Gdk.Rectangle expose_area,
                                     Gtk.CellRendererState flags)
        {
            var ctx = Gdk.cairo_create (window);
            Gdk.cairo_rectangle (ctx, expose_area);
            ctx.clip ();

            Gdk.cairo_rectangle (ctx, background_area);

            ctx.set_font_size(12);
	        ctx.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
	        ctx.move_to(30, 30); 
            ctx.set_source_rgb(0, 0, 0);
            ctx.show_text(theme.name);
           

        }
    }

}
