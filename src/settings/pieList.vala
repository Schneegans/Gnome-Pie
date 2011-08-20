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

// A very complex Widget.

class PieList : Gtk.TreeView {

    private Gtk.ListStore groups;
    private Gtk.ListStore pies;
    private Gtk.ListStore types;
    private Gtk.TreeStore data;

    public PieList() {
        GLib.Object();
        
        Gtk.TreeIter last;
        
        // group choices
        groups = new Gtk.ListStore(1, typeof(string));
            groups.append(out last); groups.set(last, 0, MenuGroup.get_name()); 
            groups.append(out last); groups.set(last, 0, DevicesGroup.get_name()); 
            groups.append(out last); groups.set(last, 0, BookmarkGroup.get_name());
            
        // pie choices
        pies = new Gtk.ListStore(2, typeof(string), typeof(string));
            pies.append(out last); pies.set(last, 0, "name", 1, "id"); 
            pies.append(out last); pies.set(last, 0, "name2", 1, "id2"); 
        
        // action choices
        types = new Gtk.ListStore(3, typeof(string), typeof(CellRendererMorph.Mode), typeof(Gtk.TreeModel));    
            types.append(out last); types.set(last, 0, AppAction.get_name(), 1, CellRendererMorph.Mode.TEXT, 2, null); 
            types.append(out last); types.set(last, 0, KeyAction.get_name(), 1, CellRendererMorph.Mode.ACCEL, 2, null); 
            types.append(out last); types.set(last, 0, PieAction.get_name(), 1, CellRendererMorph.Mode.COMBO, 2, pies); 
            types.append(out last); types.set(last, 0, UriAction.get_name(), 1, CellRendererMorph.Mode.TEXT, 2, null); 
            types.append(out last); types.set(last, 0, _("Slice group"), 1, CellRendererMorph.Mode.COMBO, 2, groups); 
        
        // data model
        data = new Gtk.TreeStore(9, typeof(string),                  // icon_name
                                    typeof(string),                  // name   
                                    typeof(string),                  // type     
                                    typeof(string),                  // command  
                                    typeof(bool),                    // type visible
                                    typeof(int),                     // icon size
                                    typeof(int),                     // font weight
                                    typeof(CellRendererMorph.Mode),  // morph mode
                                    typeof(Gtk.TreeModel));          // morph model
        
        this.set_model(data);
        this.set_grid_lines(Gtk.TreeViewGridLines.NONE);
        this.set_enable_tree_lines(false);
        this.set_reorderable(false);
        this.set_level_indentation(-5);
        //this.set_rules_hint(true);
        
        // create the gui
        // icon column
        var icon_column = new Gtk.TreeViewColumn();
            icon_column.title = _("Icon");
            icon_column.expand = false;
        
            var icon_render = new CellRendererIcon();
                icon_render.editable = true;
                icon_column.pack_start(icon_render, false);
                
                icon_render.on_select.connect((path, icon_name) => {
                    Gtk.TreeIter iter;
                    data.get_iter_from_string(out iter, path);
                    data.set(iter, 0, icon_name);
                });
                
        // command column    
        var command_column = new Gtk.TreeViewColumn();
            command_column.title = _("Command");
            command_column.expand = true;
            command_column.resizable = true;
                
            var command_render = new GnomePie.CellRendererMorph();
                command_render.editable = true;
                command_render.ellipsize = Pango.EllipsizeMode.END;
                command_column.pack_end(command_render, true);
        
                command_render.text_edited.connect((path, text) => {                        
                    Gtk.TreeIter iter;
                    data.get_iter_from_string(out iter, path);
                    data.set(iter, 3, text);
                });
        
        // type column   
        var type_column = new Gtk.TreeViewColumn();
            type_column.title = _("Action type");
            type_column.expand = true;
            type_column.resizable = true;
                
            var type_render = new Gtk.CellRendererCombo();
                type_render.editable = true;
                type_render.has_entry = false;
                type_render.model = types;
                type_render.text_column = 0;
                type_render.ellipsize = Pango.EllipsizeMode.END;
                type_column.pack_start(type_render, true);
                
                // change command_render's type accordingly
                type_render.changed.connect((path, iter) => {
                    string text = "";
                    CellRendererMorph.Mode mode;
                    Gtk.TreeModel model;
                    
                    types.get(iter, 0, out text);
                    types.get(iter, 1, out mode);
                    types.get(iter, 2, out model);
                
                    Gtk.TreeIter tv_iter;
                    data.get_iter_from_string(out tv_iter, path);
                    
                    data.set(tv_iter, 2, text);
                    data.set(tv_iter, 3, "");
                    data.set(tv_iter, 7, mode);
                    data.set(tv_iter, 8, model);
                    
                    //this.set_cursor(new Gtk.TreePath.from_string(path), command_column, true);
                });
        
        // name column    
        var name_column = new Gtk.TreeViewColumn();
            name_column.title = _("Name");
            name_column.expand = true;
            name_column.resizable = true;
        
            var name_render = new Gtk.CellRendererText();
                name_render.editable = true;
                name_render.ellipsize = Pango.EllipsizeMode.END;
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
        name_column.add_attribute(name_render, "weight", 6);
        type_column.add_attribute(type_render, "weight", 6);
        command_column.add_attribute(command_render, "weight", 6);
        command_column.add_attribute(command_render, "morph_mode", 7);
        command_column.add_attribute(command_render, "model", 8);
        
        this.realize.connect(this.load);
    }
    
    private void load() {
        foreach (var pie in PieManager.all_pies.entries) {
        
            if (pie.value.is_custom) {
        
                Gtk.TreeIter parent;
                data.append(out parent, null);
                data.set(parent, 0, pie.value.icon_name,
                                 1, pie.value.name,
                                 2, "",
                                 3, PieManager.get_accelerator_of(pie.value.id),
                                 4, false,
                                 5, Gtk.IconSize.DND,
                                 6, 800,
                                 7, CellRendererMorph.Mode.ACCEL,
                                 8, null);
                                 
                foreach (var group in pie.value.action_groups) {
                    if (group is BookmarkGroup) {
                        Gtk.TreeIter child;
                        data.append(out child, parent);
                        data.set(child, 0, "",
                                        1, "",
                                        2, _("Slice group"),
                                        3, BookmarkGroup.get_name(),
                                        4, true,
                                        5, Gtk.IconSize.LARGE_TOOLBAR,
                                        6, 400,
                                        7, CellRendererMorph.Mode.COMBO,
                                        8, groups);
                    } else if (group is DevicesGroup) {
                        Gtk.TreeIter child;
                        data.append(out child, parent);
                        data.set(child, 0, "",
                                        1, "",
                                        2, _("Slice group"),
                                        3, DevicesGroup.get_name(),
                                        4, true,
                                        5, Gtk.IconSize.LARGE_TOOLBAR,
                                        6, 400,
                                        7, CellRendererMorph.Mode.COMBO,
                                        8, groups);
                    } else if (group is MenuGroup) {
                        Gtk.TreeIter child;
                        data.append(out child, parent);
                        data.set(child, 0, "",
                                        1, "",
                                        2, _("Slice group"),
                                        3, MenuGroup.get_name(),
                                        4, true,
                                        5, Gtk.IconSize.LARGE_TOOLBAR,
                                        6, 400,
                                        7, CellRendererMorph.Mode.COMBO,
                                        8, groups);
                    } else {
                        foreach (var action in group.actions) {
                        
                            if (action is AppAction) {
                                Gtk.TreeIter child;
                                data.append(out child, parent);
                                data.set(child, 0, action.icon_name,
                                                1, action.name,
                                                2, AppAction.get_name(),
                                                3, ((AppAction)action).command,
                                                4, true,
                                                5, Gtk.IconSize.LARGE_TOOLBAR,
                                                6, 400,
                                                7, CellRendererMorph.Mode.TEXT,
                                                8, null);
                            } else if (action is KeyAction) {
                                Gtk.TreeIter child;
                                data.append(out child, parent);
                                data.set(child, 0, action.icon_name,
                                                1, action.name,
                                                2, KeyAction.get_name(),
                                                3, ((KeyAction)action).key.label,
                                                4, true,
                                                5, Gtk.IconSize.LARGE_TOOLBAR,
                                                6, 400,
                                                7, CellRendererMorph.Mode.ACCEL,
                                                8, null);
                            } else if (action is PieAction) {
                                Gtk.TreeIter child;
                                data.append(out child, parent);
                                data.set(child, 0, action.icon_name,
                                                1, action.name,
                                                2, PieAction.get_name(),
                                                3, PieManager.get_name_of(((PieAction)action).pie_id),
                                                4, true,
                                                5, Gtk.IconSize.LARGE_TOOLBAR,
                                                6, 400,
                                                7, CellRendererMorph.Mode.COMBO,
                                                8, pies);
                            } else if (action is UriAction) {
                                Gtk.TreeIter child;
                                data.append(out child, parent);
                                data.set(child, 0, action.icon_name,
                                                1, action.name,
                                                2, UriAction.get_name(),
                                                3, ((UriAction)action).uri,
                                                4, true,
                                                5, Gtk.IconSize.LARGE_TOOLBAR,
                                                6, 400,
                                                7, CellRendererMorph.Mode.TEXT,
                                                8, null);
                            }
                        }
                    }
                }
            }
        }
    }
}

}
