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
    
        public PieList() {
            GLib.Object();
            
            var types = new Gtk.ListStore(2, typeof(string), typeof(CellRendererMorph.Mode));
                Gtk.TreeIter last;
                types.append(out last); types.set(last, 0, _("Key Stroke"), 1, CellRendererMorph.Mode.ACCEL); 
                types.append(out last); types.set(last, 0, _("Command"),  1, CellRendererMorph.Mode.TEXT); 
                types.append(out last); types.set(last, 0, _("Open Pie"),         1, CellRendererMorph.Mode.COMBO); 
                types.append(out last); types.set(last, 0, _("Plugin"),           1, CellRendererMorph.Mode.COMBO); 
                
            var plugins = new Gtk.ListStore(1, typeof(string));
                plugins.append(out last); plugins.set(last, 0, _("Main Menu")); 
                plugins.append(out last); plugins.set(last, 0, _("Bookmarks")); 
            
            var data = new Gtk.TreeStore(7, typeof(string), // icon_name - CellRendererPixbuf
                                            typeof(string), // name      - CellRendererText
                                            typeof(string), // type      - CellRendererCombo
                                            typeof(string), // command   - CellRendererMorph
                                            typeof(bool),   // type visible
                                            typeof(int),    // icon size
                                            typeof(CellRendererMorph.Mode)); // command mode
            
            this.set_model(data);
            this.set_grid_lines(Gtk.TreeViewGridLines.NONE);
            this.set_show_expanders(false);
            this.set_enable_tree_lines(true);
            this.set_reorderable(true);
            
            // expand the selected row
            this.get_selection().changed.connect(() => {
                Gtk.TreeIter selected;
                if (this.get_selection().get_selected(null, out selected)) {
                    var path = data.get_path(selected);
                    if (path != null && path.get_depth() == 1) {
                        collapse_all();
                        expand_row(path, false);
                    }
                }
            });
            
            // create the gui
            // icon column
            var icon_column = new Gtk.TreeViewColumn();
                icon_column.title = _("Icon");
                icon_column.expand = false;
            
                var icon_render = new Gtk.CellRendererPixbuf();
                    icon_render.xalign = 1.0f;
                    icon_render.stock_size = Gtk.IconSize.LARGE_TOOLBAR;
                    icon_column.pack_start(icon_render, false);
                    
                    this.button_press_event.connect((event) => {
                        Gtk.TreePath path;
                        Gtk.TreeViewColumn column;
                        Gtk.TreeIter iter = Gtk.TreeIter();
                        if (this.get_path_at_pos((int)event.x, (int)event.y, out path, out column, null, null)) {
                            var selection = this.get_selection();
                            
                            if (column == icon_column 
                                && selection.get_selected_rows(null).length() > 0 
                                && data.get_iter(out iter, path)) {

                                if (selection.get_selected_rows(null).first().data.compare(path) == 0) {
                                    var select = new IconSelectWindow();
                                    string icon_name;
                                    data.get(iter, 0, out icon_name);
                                    select.active_icon = icon_name;
                                    select.show();
                                    
                                    select.on_select.connect((icon_name) => {
                                        data.set(iter, 0, icon_name);
                                    });
                                } else {
                                    this.get_selection().select_path(path);
                                }
                                
                                return true;
                            }
                        }
                        return false;
                    });
                    
            // command column    
            var command_column = new Gtk.TreeViewColumn();
                command_column.title = _("Command");
                command_column.expand = true;
                    
                var command_render = new GnomePie.CellRendererMorph();
                    command_render.editable = true;
                    command_column.pack_end(command_render, true);
                    command_render.model = plugins;
            
                    command_render.text_edited.connect((path, text) => {                        
                        Gtk.TreeIter iter;
                        data.get_iter_from_string(out iter, path);
                        data.set(iter, 3, text);
                    });
            
            // type column   
            var type_column = new Gtk.TreeViewColumn();
                type_column.title = _("Action type");
                type_column.expand = true;
                    
                var type_render = new Gtk.CellRendererCombo();
                    type_render.editable = true;
                    type_render.has_entry = false;
                    type_render.model = types;
                    type_render.text_column = 0;
                    type_column.pack_start(type_render, true);
                    
                    // change command_render's type accordingly
                    type_render.changed.connect((path, iter) => {
                        string text = "";
                        CellRendererMorph.Mode mode;
                        
                        types.get(iter, 0, out text);
                        types.get(iter, 1, out mode);
                    
                        Gtk.TreeIter tv_iter;
                        data.get_iter_from_string(out tv_iter, path);
                        data.set(tv_iter, 2, text);
                        data.set(tv_iter, 6, mode);
                        data.set(tv_iter, 3, "");
                        
                        //this.set_cursor(new Gtk.TreePath.from_string(path), command_column, true);
                    });
            
            // name column    
            var name_column = new Gtk.TreeViewColumn();
                name_column.title = _("Name");
                name_column.expand = true;
            
                var name_render = new Gtk.CellRendererText();
                    name_render.editable = true;
                    name_column.pack_start(name_render, true);
                    
                    name_render.edited.connect((path, text) => {                        
                        Gtk.TreeIter iter;
                        data.get_iter_from_string(out iter, path);
                        data.set(iter, 1, text);
                    });
            
            this.append_column(icon_column);
            this.append_column(name_column);
            this.append_column(type_column);
            this.append_column(command_column);
            
            icon_column.add_attribute(icon_render, "icon_name", 0);
            name_column.add_attribute(name_render, "text", 1);
            type_column.add_attribute(type_render, "text", 2);
            command_column.add_attribute(command_render, "text", 3);
            type_column.add_attribute(type_render, "visible", 4);
            icon_column.add_attribute(icon_render, "stock_size", 5);
            command_column.add_attribute(command_render, "morph_mode", 6);
            
            for (int i=0; i<5; ++i) {
                
                Gtk.TreeIter parent;
                data.append(out parent, null);
                data.set(parent, 0, "firefox",
                                 1, "Pie name",
                                 2, "",
                                 3, _("Not bound"),
                                 4, false,
                                 5, Gtk.IconSize.DIALOG,
                                 6, CellRendererMorph.Mode.ACCEL);

                for (int j=0; j<5; ++j) {
                    Gtk.TreeIter child;
                    data.append(out child, parent);
                    data.set(child, 0, "thunderbird",
                                    1, "Slice name",
                                    2, _("Key Stroke"),
                                    3, _("Not bound"),
                                    4, true,
                                    5, Gtk.IconSize.LARGE_TOOLBAR,
                                    6, CellRendererMorph.Mode.ACCEL);
                }
            }  
        }
    }

}
