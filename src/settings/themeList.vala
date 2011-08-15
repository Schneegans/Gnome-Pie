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

class ThemeList : Gtk.TreeView {

    private Gtk.TreeIter active{private get; private set;}

    public ThemeList() {
        GLib.Object();
        
        var data = new Gtk.ListStore(2, typeof(bool), typeof(string));
        base.set_model(data);
        base.set_headers_visible(false);
        base.set_rules_hint(true);
        base.set_grid_lines(Gtk.TreeViewGridLines.NONE);
        
        var main_column = new Gtk.TreeViewColumn();
            var check_render = new Gtk.CellRendererToggle();
                check_render.set_radio(true);
                check_render.set_activatable(true);
                main_column.pack_start(check_render, false);
                
                check_render.toggled.connect((r, path) => {
                    Gtk.TreeIter toggled;
                    data.get_iter(out toggled, new Gtk.TreePath.from_string(path));
                    
                    if (toggled != this.active) {
                        Timeout.add(10, () => {
                            int index = int.parse(path);
                            Settings.global.theme = Settings.global.themes[index];
                            Settings.global.theme.load();
                            return false;
                        });
                        
                        data.set(this.active, 0, false); 
                        data.set(toggled, 0, true);
                        
                        this.active = toggled;
                    }
                });
        
            var theme_render = new Gtk.CellRendererText();
                main_column.pack_start(theme_render, true);
        
        base.append_column(main_column);
        
        main_column.add_attribute(check_render, "active", 0);
        main_column.add_attribute(theme_render, "markup", 1);
        
        var themes = Settings.global.themes;
        foreach(var theme in themes) {
            Gtk.TreeIter current;
            data.append(out current);
            data.set(current, 0, theme == Settings.global.theme); 
            data.set(current, 1, "<b>" + theme.name + "</b>\n" + theme.description
                                 + "  <small> - " + _("by") + " " + theme.author + "</small>"); 
            if(theme == Settings.global.theme)
                this.active = current;
        }  
    }
}

}
