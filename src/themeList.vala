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
            
            var cells = new Gtk.ListStore(2, typeof (Gdk.Pixbuf), typeof (string));
            set_model(cells);
            set_headers_visible(false);
            
            var renderer = new ThemeCellRenderer();
            var col = new Gtk.TreeViewColumn ();
            col.pack_start (renderer, true);
            col.add_attribute (renderer, "icon", 0);

            Gtk.TreeIter current;
            append_column (col);
            
            for (int i=0; i<3; ++i) {
                cells.append (out current);
                var pixbuf = open_image ("firefox.png");
                cells.set (current, 0, pixbuf, 1, "asd", -1); 
                col.add_attribute (renderer, "icon", 0);
            }

            
        }
    }

    class ThemeCellRenderer : Gtk.CellRenderer {

        /* icon property set by the tree column */
        public Gdk.Pixbuf icon { get; set; }

        public ThemeCellRenderer () {
            GLib.Object ();
        }

        /* get_size method, always request a 50x50 area */
        public override void get_size (Gtk.Widget widget, Gdk.Rectangle? cell_area,
                                       out int x_offset, out int y_offset,
                                       out int width, out int height)
        {
            /* Guards needed to check if the 'out' parameters are null */
            if (&x_offset != null) x_offset = 0;
            if (&y_offset != null) y_offset = 0;
            if (&width != null) width = 50;
            if (&height != null) height = 50;
        }

        /* render method */
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
            if (icon != null) {
                /* draw a pixbuf on a cairo context */
                Gdk.cairo_set_source_pixbuf (ctx, icon,
                                             background_area.x,
                                             background_area.y);
                ctx.fill ();
            }
        }
    }

}
