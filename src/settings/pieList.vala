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
    
    // data positions in the data ListStore
    private enum DataPos {IS_QUICKACTION, ICON, NAME, TYPE_ID, ACTION_TYPE,
                          ICON_SIZE, FONT_WEIGHT, ICON_NAME_EDITABLE, QUICKACTION_VISIBLE,
                          TYPE_VISIBLE, GROUP_VISIBLE, APP_VISIBLE, KEY_VISIBLE, PIE_VISIBLE,
                          URI_VISIBLE, DISPLAY_COMMAND_GROUP, DISPLAY_COMMAND_APP, 
                          DISPLAY_COMMAND_KEY, DISPLAY_COMMAND_PIE, DISPLAY_COMMAND_URI,
                          REAL_COMMAND_GROUP, REAL_COMMAND_PIE, REAL_COMMAND_KEY}
    
    // data positions in the types ListStore
    private enum TypePos {NAME, TYPE, CAN_QUICKACTION, ICON_NAME_EDITABLE}
    
    // data positions in the pies ListStore
    private enum PiePos {NAME, ID}
    
    // data positions in the groups ListStore
    private enum GroupPos {NAME, TYPE}

    public PieList() {
        GLib.Object();
        
        Gtk.TreeIter last;
        
        // group choices
        this.groups = new Gtk.ListStore(2, typeof(string),     // group name
                                           typeof(string));    // group type
        
        this.groups.append(out last); this.groups.set(last, 0, _("Bookmarks"), 1, typeof(BookmarkGroup).name()); 
        this.groups.append(out last); this.groups.set(last, 0, _("Devices"),   1, typeof(DevicesGroup).name()); 
        this.groups.append(out last); this.groups.set(last, 0, _("Main menu"), 1, typeof(MenuGroup).name());
            
        // pie choices
        this.pies = new Gtk.ListStore(2,  typeof(string),      // pie name 
                                          typeof(string));     // pie id
        
        // action type choices                                                              
        this.types = new Gtk.ListStore(4, typeof(string),      // type name
                                          typeof(string),      // action type 
                                          typeof(bool),        // can be quickaction
                                          typeof(bool));       // icon/name editable   
            
            
        types.append(out last); types.set(last, 0, _("Launch application"), 1, typeof(AppAction).name(), 2, true,  3, true ); 
        types.append(out last); types.set(last, 0, _("Press key stroke"),   1, typeof(KeyAction).name(), 2, true,  3, true ); 
        types.append(out last); types.set(last, 0, _("Open Pie"),           1, typeof(PieAction).name(), 2, true,  3, false); 
        types.append(out last); types.set(last, 0, _("Open URL"),           1, typeof(UriAction).name(), 2, true,  3, true ); 
        types.append(out last); types.set(last, 0, _("Slice group"),        1, "",                       2, false, 3, false); 
        
        // main data model
        this.data = new Gtk.TreeStore(23, typeof(bool),       // is quickaction
                                          typeof(string),     // icon
                                          typeof(string),     // name   
                                          typeof(string),     // slice: type label, pie: id
                                          typeof(string),     // typeof(action), "" if group action  
                                          
                                          typeof(int),        // icon size
                                          typeof(int),        // font weight
                                          
                                          typeof(bool),       // icon/name editable
                                          
                                          typeof(bool),       // quickaction visible
                                          typeof(bool),       // type visible
                                          typeof(bool),       // group renderer visible
                                          typeof(bool),       // app renderer visible
                                          typeof(bool),       // key renderer visible
                                          typeof(bool),       // pie renderer visible
                                          typeof(bool),       // uri renderer visible
                                          
                                          typeof(string),     // display command group
                                          typeof(string),     // display command app
                                          typeof(string),     // display command key
                                          typeof(string),     // display command pie
                                          typeof(string),     // display command uri
                                          
                                          typeof(string),     // real command group
                                          typeof(string),     // real command pie
                                          typeof(string));    // real command key
                                          
            
        this.set_model(this.data);
        this.set_grid_lines(Gtk.TreeViewGridLines.NONE);
        this.set_enable_tree_lines(false);
        this.set_reorderable(false);
        
        // create the gui
        // icon column
        var icon_column = new Gtk.TreeViewColumn();
            icon_column.title = _("Icon");
            icon_column.expand = false;
            
            // quickaction checkbox
            var check_render = new Gtk.CellRendererToggle();
                check_render.activatable = true;
                check_render.radio = true;
                check_render.width = 15;

                check_render.toggled.connect((path) => {
                    Gtk.TreeIter toggled;
                    this.data.get_iter_from_string(out toggled, path);
                    
                    bool current = false;
                    this.data.get(toggled, DataPos.IS_QUICKACTION, out current);
                    
                    // set all others off
                    Gtk.TreeIter parent;
                    this.data.iter_parent(out parent, toggled);
                    string parent_pos = this.data.get_string_from_iter(parent);
                    int child_count = this.data.iter_n_children(parent);
                    
                    for (int i=0; i<child_count; ++i) {
                        Gtk.TreeIter child;
                        this.data.get_iter_from_string(out child, "%s:%d".printf(parent_pos, i));
                        this.data.set(child, DataPos.IS_QUICKACTION, false);
                    }
                    
                    // toggle selected
                    this.data.set(toggled, DataPos.IS_QUICKACTION, !current);
                    
                    this.update_pie(toggled);
                });
                
                icon_column.pack_start(check_render, false);
                icon_column.add_attribute(check_render, "visible", DataPos.QUICKACTION_VISIBLE);
                icon_column.add_attribute(check_render, "active", DataPos.IS_QUICKACTION);
                
        
            // icon 
            var icon_render = new GnomePie.CellRendererIcon();
                icon_render.editable = true;

                icon_render.on_select.connect((path, icon_name) => {
                    Gtk.TreeIter iter;
                    this.data.get_iter_from_string(out iter, path);
                    this.data.set(iter, DataPos.ICON, icon_name);
                    
                    this.update_pie(iter);
                });
                
                icon_column.pack_start(icon_render, false);
                icon_column.add_attribute(icon_render, "icon_name", DataPos.ICON);
                icon_column.add_attribute(icon_render, "stock_size", DataPos.ICON_SIZE);
                icon_column.add_attribute(icon_render, "editable", DataPos.ICON_NAME_EDITABLE);
                
                  
        // command column    
        var command_column = new Gtk.TreeViewColumn();
            command_column.title = _("Command");
            command_column.expand = true;
            command_column.resizable = true;
            
            // slice group 
            var command_renderer_group = new Gtk.CellRendererCombo();
                command_renderer_group.editable = true;
                command_renderer_group.has_entry = false;
                command_renderer_group.text_column = 0;
                command_renderer_group.ellipsize = Pango.EllipsizeMode.END;
                command_renderer_group.model = this.groups;

                command_renderer_group.changed.connect((path, iter) => {
                    string display_name;
                    string type;
                    
                    this.groups.get(iter, GroupPos.NAME, out display_name);
                    this.groups.get(iter, GroupPos.TYPE, out type);
                                     
                    Gtk.TreeIter data_iter;
                    this.data.get_iter_from_string(out data_iter, path);
                    
                    this.data.set(data_iter, DataPos.DISPLAY_COMMAND_GROUP, display_name);
                    this.data.set(data_iter, DataPos.REAL_COMMAND_GROUP, type);
                    
                    this.update_pie(data_iter);
                });
                
                command_column.pack_end(command_renderer_group, true);
                command_column.add_attribute(command_renderer_group, "weight", DataPos.FONT_WEIGHT);
                command_column.add_attribute(command_renderer_group, "text", DataPos.DISPLAY_COMMAND_GROUP);
                command_column.add_attribute(command_renderer_group, "visible", DataPos.GROUP_VISIBLE);
                
                
            // app action 
            var command_renderer_app = new Gtk.CellRendererText();
                command_renderer_app.editable = true;
                command_renderer_app.ellipsize = Pango.EllipsizeMode.END;

                command_renderer_app.edited.connect((path, command) => {                 
                    Gtk.TreeIter data_iter;
                    this.data.get_iter_from_string(out data_iter, path);
                    
                    this.data.set(data_iter, DataPos.DISPLAY_COMMAND_APP, command);
                    
                    this.update_pie(data_iter);
                });
                
                command_column.pack_end(command_renderer_app, true);
                command_column.add_attribute(command_renderer_app, "weight", DataPos.FONT_WEIGHT);
                command_column.add_attribute(command_renderer_app, "text", DataPos.DISPLAY_COMMAND_APP);
                command_column.add_attribute(command_renderer_app, "visible", DataPos.APP_VISIBLE);
                
                
            // key action 
            var command_renderer_key = new Gtk.CellRendererAccel();
                command_renderer_key.editable = true;
                command_renderer_key.ellipsize = Pango.EllipsizeMode.END;

                command_renderer_key.accel_edited.connect((path, key, mods) => {                 
                    Gtk.TreeIter data_iter;
                    this.data.get_iter_from_string(out data_iter, path);
                    
                    string label = Gtk.accelerator_get_label(key, mods);
                    string accelerator = Gtk.accelerator_name(key, mods);
                    
                    this.data.set(data_iter, DataPos.DISPLAY_COMMAND_KEY, label);
                    this.data.set(data_iter, DataPos.REAL_COMMAND_KEY, accelerator);
                    
                    this.update_pie(data_iter);
                });
                
                command_renderer_key.accel_cleared.connect((path) => {                 
                    Gtk.TreeIter data_iter;
                    this.data.get_iter_from_string(out data_iter, path);
                    
                    this.data.set(data_iter, DataPos.DISPLAY_COMMAND_KEY, _("Not bound"));
                    this.data.set(data_iter, DataPos.REAL_COMMAND_KEY, "");
                    
                    this.update_pie(data_iter);
                });
                
                command_column.pack_end(command_renderer_key, true);
                command_column.add_attribute(command_renderer_key, "weight", DataPos.FONT_WEIGHT);
                command_column.add_attribute(command_renderer_key, "text", DataPos.DISPLAY_COMMAND_KEY);
                command_column.add_attribute(command_renderer_key, "visible", DataPos.KEY_VISIBLE);
                
                
            // pie action 
            var command_renderer_pie = new Gtk.CellRendererCombo();
                command_renderer_pie.editable = true;
                command_renderer_pie.has_entry = false;
                command_renderer_pie.text_column = 0;
                command_renderer_pie.ellipsize = Pango.EllipsizeMode.END;
                command_renderer_pie.model = this.pies;

                command_renderer_pie.changed.connect((path, iter) => {
                    string name;
                    string id;
                    
                    this.pies.get(iter, PiePos.NAME, out name);
                    this.pies.get(iter, PiePos.ID, out id);
                                     
                    Gtk.TreeIter data_iter;
                    this.data.get_iter_from_string(out data_iter, path);
                    
                    this.data.set(data_iter, DataPos.DISPLAY_COMMAND_PIE, name);
                    this.data.set(data_iter, DataPos.REAL_COMMAND_PIE, id);
                    
                    this.update_pie(data_iter);
                });
                
                command_column.pack_end(command_renderer_pie, true);
                command_column.add_attribute(command_renderer_pie, "weight", DataPos.FONT_WEIGHT);
                command_column.add_attribute(command_renderer_pie, "text", DataPos.DISPLAY_COMMAND_PIE);
                command_column.add_attribute(command_renderer_pie, "visible", DataPos.PIE_VISIBLE);
                
                
            // uri action 
            var command_renderer_uri = new Gtk.CellRendererText();
                command_renderer_uri.editable = true;
                command_renderer_uri.ellipsize = Pango.EllipsizeMode.END;

                command_renderer_uri.edited.connect((path, uri) => {                 
                    Gtk.TreeIter data_iter;
                    this.data.get_iter_from_string(out data_iter, path);
                    
                    this.data.set(data_iter, DataPos.DISPLAY_COMMAND_URI, uri);
                    
                    this.update_pie(data_iter);
                });
                
                command_column.pack_end(command_renderer_uri, true);
                command_column.add_attribute(command_renderer_uri, "weight", DataPos.FONT_WEIGHT);
                command_column.add_attribute(command_renderer_uri, "text", DataPos.DISPLAY_COMMAND_URI);
                command_column.add_attribute(command_renderer_uri, "visible", DataPos.URI_VISIBLE);
                
        
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

                // change command_render's visibility accordingly
                type_render.changed.connect((path, iter) => {
                    string text = "";
                    string type;
                    bool can_quickaction;
                    bool icon_name_editable;
                    
                    this.types.get(iter, TypePos.NAME, out text);
                    this.types.get(iter, TypePos.TYPE, out type);
                    this.types.get(iter, TypePos.CAN_QUICKACTION, out can_quickaction);
                    this.types.get(iter, TypePos.ICON_NAME_EDITABLE, out icon_name_editable);
                
                    Gtk.TreeIter data_iter;
                    this.data.get_iter_from_string(out data_iter, path);
                    
                    this.data.set(data_iter, DataPos.TYPE_ID, text);
                    this.data.set(data_iter, DataPos.ACTION_TYPE, type);
                    this.data.set(data_iter, DataPos.QUICKACTION_VISIBLE, can_quickaction);
                    this.data.set(data_iter, DataPos.ICON_NAME_EDITABLE, icon_name_editable);
                    
                    // set all command renderes invisible
                    this.data.set(data_iter, DataPos.GROUP_VISIBLE, false);
                    this.data.set(data_iter, DataPos.APP_VISIBLE, false);
                    this.data.set(data_iter, DataPos.KEY_VISIBLE, false);
                    this.data.set(data_iter, DataPos.PIE_VISIBLE, false);
                    this.data.set(data_iter, DataPos.URI_VISIBLE, false);
                    
                    // set one visible
                    int type_id = 0;
                    if(type == typeof(AppAction).name()) type_id = 1; 
                    else if(type == typeof(KeyAction).name()) type_id = 2; 
                    else if(type == typeof(PieAction).name()) type_id = 3; 
                    else if(type == typeof(UriAction).name()) type_id = 4; 
                    else type_id = 0;
                    
                    this.data.set(data_iter, DataPos.GROUP_VISIBLE + type_id, true);
                    
                    this.set_cursor(new Gtk.TreePath.from_string(path), command_column, true);
                    
                    this.update_pie(data_iter);
                });
                
                type_column.pack_start(type_render, true);
                type_column.add_attribute(type_render, "visible", DataPos.TYPE_VISIBLE);
                type_column.add_attribute(type_render, "text", DataPos.TYPE_ID);
                type_column.add_attribute(type_render, "weight", DataPos.FONT_WEIGHT);
                
        
        // name column    
        var name_column = new Gtk.TreeViewColumn();
            name_column.title = _("Name");
            name_column.expand = true;
            name_column.resizable = true;
        
            var name_render = new Gtk.CellRendererText();
                name_render.editable = true;
                name_render.ellipsize = Pango.EllipsizeMode.END;

                name_render.edited.connect((path, text) => {                        
                    Gtk.TreeIter iter;
                    this.data.get_iter_from_string(out iter, path);
                    this.data.set(iter, DataPos.NAME, text);
                    
                    this.set_cursor(new Gtk.TreePath.from_string(path), type_column, true);
                    
                    this.update_pie(iter);
                });
                
                name_column.pack_start(name_render, true);
                name_column.add_attribute(name_render, "weight", DataPos.FONT_WEIGHT);
                name_column.add_attribute(name_render, "text", DataPos.NAME);
                name_column.add_attribute(name_render, "editable", DataPos.ICON_NAME_EDITABLE);
                
        
        this.append_column(icon_column);
        this.append_column(name_column);
        this.append_column(type_column);
        this.append_column(command_column);
        
        this.realize.connect(this.load);
        
        // context menu
        var menu = new Gtk.Menu();

        var item = new Gtk.ImageMenuItem.with_label(_("Add new Pie"));
        item.set_image(new Gtk.Image.from_stock(Gtk.Stock.ADD, Gtk.IconSize.MENU));
        item.activate.connect(this.add_pie);
        menu.append(item);

        item = new Gtk.ImageMenuItem.with_label(_("Add new Slice"));
        item.set_image(new Gtk.Image.from_stock(Gtk.Stock.ADD, Gtk.IconSize.MENU));
        item.activate.connect(this.add_slice);
        menu.append(item);
        
        var sepa = new Gtk.SeparatorMenuItem();
        menu.append(sepa);

        item = new Gtk.ImageMenuItem.with_label(_("Delete"));
        item.set_image(new Gtk.Image.from_stock(Gtk.Stock.DELETE, Gtk.IconSize.MENU));
        item.activate.connect(this.delete_selection);
        menu.append(item);
        
        menu.show_all();
        
        this.button_press_event.connect((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
                menu.popup(null, null, null, event.button, event.time);
            }
            return false;
        });
    }
    
    private void add_pie() {
        var new_one = PieManager.add_pie("new_pie", null, _("New Pie"), "application-default-icon", "", true);
        
        Gtk.TreeIter last;
        this.pies.append(out last); this.pies.set(last, 0, new_one.name, 1, new_one.id); 
    
        Gtk.TreeIter parent;
        this.data.append(out parent, null);
        this.data.set(parent, DataPos.IS_QUICKACTION, false,
                                        DataPos.ICON, new_one.icon_name,
                                        DataPos.NAME, new_one.name,
                                     DataPos.TYPE_ID, new_one.id,
                                 DataPos.ACTION_TYPE, "",
                                   DataPos.ICON_SIZE, Gtk.IconSize.DND,
                                 DataPos.FONT_WEIGHT, 800,
                          DataPos.ICON_NAME_EDITABLE, true,
                         DataPos.QUICKACTION_VISIBLE, false,
                                DataPos.TYPE_VISIBLE, false,
                               DataPos.GROUP_VISIBLE, false,
                                 DataPos.APP_VISIBLE, false,
                                 DataPos.KEY_VISIBLE, true,
                                 DataPos.PIE_VISIBLE, false,
                                 DataPos.URI_VISIBLE, false,
                       DataPos.DISPLAY_COMMAND_GROUP, "",
                         DataPos.DISPLAY_COMMAND_APP, "",
                         DataPos.DISPLAY_COMMAND_KEY, PieManager.get_accelerator_label_of(new_one.id),
                         DataPos.DISPLAY_COMMAND_PIE, "",
                         DataPos.DISPLAY_COMMAND_URI, "",
                          DataPos.REAL_COMMAND_GROUP, "",
                            DataPos.REAL_COMMAND_PIE, "",
                            DataPos.REAL_COMMAND_KEY, PieManager.get_accelerator_of(new_one.id));
                          
        
        this.get_selection().select_iter(parent);
        this.scroll_to_cell(this.data.get_path(parent), null, true, 0.5f, 0.0f);
    }
    
    private void add_slice() {
        Gtk.TreeIter selected;
        if (this.get_selection().get_selected(null, out selected)) {
            var path = this.data.get_path(selected);
            if (path != null) {
                if (path.get_depth() == 2)
                    this.data.iter_parent(out selected, selected);
                
                this.load_action(selected, new AppAction(_("New Action"), "application-default-icon", ""));
                
                Gtk.TreeIter new_one;
                this.data.iter_nth_child(out new_one, selected, this.data.iter_n_children(selected)-1);
                this.expand_to_path(this.data.get_path(new_one));
                this.get_selection().select_iter(new_one);
                this.scroll_to_cell(this.data.get_path(new_one), null, true, 0.5f, 0.0f);
                
                this.update_pie(selected);
            } 
        } else {
            var dialog = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, 
                                                     Gtk.MessageType.INFO, 
                                                     Gtk.ButtonsType.CLOSE, 
                                                     _("You have to select a Pie to add a Slice to!"));
            dialog.run();
            dialog.destroy();
        }
    }
    
    private void delete_selection() {
        Gtk.TreeIter selected;
        if (this.get_selection().get_selected(null, out selected)) {
            var path = this.data.get_path(selected);
            if (path != null) {
                if (path.get_depth() == 1)
                    this.delete_pie(selected);
                else
                    this.delete_slice(selected);
            } 
        } else {
            var dialog = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, 
                                                     Gtk.MessageType.INFO, 
                                                     Gtk.ButtonsType.CLOSE, 
                                                     _("You have to select a Pie or a Slice to delete!"));
            dialog.run();
            dialog.destroy();
        }
    }
    
    private void delete_pie(Gtk.TreeIter pie) {
        var dialog = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, 
                                                 Gtk.MessageType.QUESTION, 
                                                 Gtk.ButtonsType.YES_NO, 
                                                 _("Do you really want to delete the selected Pie with all contained Slices?"));
                                                 
        dialog.response.connect((response) => {
            if (response == Gtk.ResponseType.YES) {
                string id;
                this.data.get(pie, DataPos.TYPE_ID, out id);
                this.data.remove(pie);
                PieManager.remove_pie(id);
            }
        });
        
        dialog.run();
        dialog.destroy();
    }
    
    private void delete_slice(Gtk.TreeIter slice) {
        var dialog = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, 
                                                 Gtk.MessageType.QUESTION, 
                                                 Gtk.ButtonsType.YES_NO, 
                                                 _("Do you really want to delete the selected Slice?"));
                                                 
        dialog.response.connect((response) => {
            if (response == Gtk.ResponseType.YES) {
                Gtk.TreeIter parent;
                this.data.iter_parent(out parent, slice);
                this.data.remove(slice);
                this.update_pie(parent);
            }
        });
        
        dialog.run();
        dialog.destroy();
    }
    
    private void load() {
        foreach (var pie in PieManager.all_pies.entries) {
            this.load_pie(pie.value);
        }
    }
    
    private void load_pie(Pie pie) {
        if (pie.is_custom) {
        
            Gtk.TreeIter last;
            this.pies.append(out last); this.pies.set(last, PiePos.NAME, pie.name, 
                                                              PiePos.ID, pie.id); 
        
            Gtk.TreeIter parent;
            this.data.append(out parent, null);
            this.data.set(parent, DataPos.IS_QUICKACTION, false,
                                            DataPos.ICON, pie.icon_name,
                                            DataPos.NAME, pie.name,
                                         DataPos.TYPE_ID, pie.id,
                                     DataPos.ACTION_TYPE, "",
                                       DataPos.ICON_SIZE, Gtk.IconSize.DND,
                                     DataPos.FONT_WEIGHT, 800,
                              DataPos.ICON_NAME_EDITABLE, true,
                             DataPos.QUICKACTION_VISIBLE, false,
                                    DataPos.TYPE_VISIBLE, false,
                                   DataPos.GROUP_VISIBLE, false,
                                     DataPos.APP_VISIBLE, false,
                                     DataPos.KEY_VISIBLE, true,
                                     DataPos.PIE_VISIBLE, false,
                                     DataPos.URI_VISIBLE, false,
                           DataPos.DISPLAY_COMMAND_GROUP, "",
                             DataPos.DISPLAY_COMMAND_APP, "",
                             DataPos.DISPLAY_COMMAND_KEY, PieManager.get_accelerator_label_of(pie.id),
                             DataPos.DISPLAY_COMMAND_PIE, "",
                             DataPos.DISPLAY_COMMAND_URI, "",
                              DataPos.REAL_COMMAND_GROUP, "",
                                DataPos.REAL_COMMAND_PIE, "",
                                DataPos.REAL_COMMAND_KEY, PieManager.get_accelerator_of(pie.id));
                             
            foreach (var group in pie.action_groups) {
                this.load_group(parent, group);
            }
        }
    }
    
    private void load_group(Gtk.TreeIter parent, ActionGroup group) {
        if (group.is_custom) {
            foreach (var action in group.actions) {
                this.load_action(parent, action);
            }
        } else {
            Gtk.TreeIter child;
            this.data.append(out child, parent);
            this.data.set(child, DataPos.IS_QUICKACTION, false,
                                           DataPos.ICON, group.icon_name,
                                           DataPos.NAME, group.group_type,
                                        DataPos.TYPE_ID, _("Slice group"),
                                    DataPos.ACTION_TYPE, "",
                                      DataPos.ICON_SIZE, Gtk.IconSize.LARGE_TOOLBAR,
                                    DataPos.FONT_WEIGHT, 400,
                             DataPos.ICON_NAME_EDITABLE, false,
                            DataPos.QUICKACTION_VISIBLE, false,
                                   DataPos.TYPE_VISIBLE, true,
                                  DataPos.GROUP_VISIBLE, true,
                                    DataPos.APP_VISIBLE, false,
                                    DataPos.KEY_VISIBLE, false,
                                    DataPos.PIE_VISIBLE, false,
                                    DataPos.URI_VISIBLE, false,
                          DataPos.DISPLAY_COMMAND_GROUP, group.group_type,
                            DataPos.DISPLAY_COMMAND_APP, "",
                            DataPos.DISPLAY_COMMAND_KEY, _("Not bound"),
                            DataPos.DISPLAY_COMMAND_PIE, "",
                            DataPos.DISPLAY_COMMAND_URI, "",
                             DataPos.REAL_COMMAND_GROUP, group.get_type().name(),
                               DataPos.REAL_COMMAND_PIE, "",
                               DataPos.REAL_COMMAND_KEY, "");
        }
    }
    
    private void load_action(Gtk.TreeIter parent, Action action) {
        Gtk.TreeIter child;
        this.data.append(out child, parent);
        this.data.set(child, DataPos.IS_QUICKACTION, action.is_quick_action,
                                       DataPos.ICON, action.icon_name,
                                       DataPos.NAME, action.name,
                                    DataPos.TYPE_ID, action.action_type,
                                DataPos.ACTION_TYPE, action.get_type().name(),
                                  DataPos.ICON_SIZE, Gtk.IconSize.LARGE_TOOLBAR,
                                DataPos.FONT_WEIGHT, 400,
                         DataPos.ICON_NAME_EDITABLE, !(action is PieAction),
                        DataPos.QUICKACTION_VISIBLE, true,
                               DataPos.TYPE_VISIBLE, true,
                              DataPos.GROUP_VISIBLE, false,
                                DataPos.APP_VISIBLE, action is AppAction,
                                DataPos.KEY_VISIBLE, action is KeyAction,
                                DataPos.PIE_VISIBLE, action is PieAction,
                                DataPos.URI_VISIBLE, action is UriAction,
                      DataPos.DISPLAY_COMMAND_GROUP, "",
                        DataPos.DISPLAY_COMMAND_APP, (action is AppAction) ? action.label : "",
                        DataPos.DISPLAY_COMMAND_KEY, (action is KeyAction) ? action.label : _("Not bound"),
                        DataPos.DISPLAY_COMMAND_PIE, (action is PieAction) ? action.label : "",
                        DataPos.DISPLAY_COMMAND_URI, (action is UriAction) ? action.label : "",
                         DataPos.REAL_COMMAND_GROUP, "",
                           DataPos.REAL_COMMAND_PIE, (action is PieAction) ? action.command : "",
                           DataPos.REAL_COMMAND_KEY, (action is KeyAction) ? action.command : "");
    }
    
    private void update_pie(Gtk.TreeIter slice_or_pie) {
        // get pie iter
        var path = this.data.get_path(slice_or_pie);
        if (path != null) {
            var pie = slice_or_pie;
            if (path.get_depth() == 2)
                this.data.iter_parent(out pie, slice_or_pie);
            
            // get information on pie
            string id;
            string icon;
            string name;
            string hotkey;
            
            this.data.get(pie, DataPos.ICON, out icon);
            this.data.get(pie, DataPos.NAME, out name);
            this.data.get(pie, DataPos.TYPE_ID, out id);
            this.data.get(pie, DataPos.REAL_COMMAND_KEY, out hotkey);
            
            // remove pie
            PieManager.remove_pie(id);
            
            // create new pie
            var new_pie = PieManager.add_pie(id, null, name, icon, hotkey, true);
            
            // add actions accordingly
            if (this.data.iter_has_child(pie)) {
                Gtk.TreeIter child;
                this.data.iter_children(out child, pie);
                
                do {
                    // get slice information
                    string slice_type;
                    string slice_icon;
                    string slice_name;
                    bool is_quick_action;
                    
                    this.data.get(child, DataPos.ICON, out slice_icon);
                    this.data.get(child, DataPos.NAME, out slice_name);
                    this.data.get(child, DataPos.ACTION_TYPE, out slice_type);
                    this.data.get(child, DataPos.IS_QUICKACTION, out is_quick_action);
                    
                    if (slice_type == typeof(AppAction).name()) {
                        string slice_command;
                        this.data.get(child, DataPos.DISPLAY_COMMAND_APP, out slice_command);
                        var group = new ActionGroup(new_pie.id);
                        group.add_action(new AppAction(slice_name, slice_icon, slice_command, is_quick_action));
                        new_pie.add_group(group);
                    } else if (slice_type == typeof(KeyAction).name()) {
                        string slice_command;
                        this.data.get(child, DataPos.REAL_COMMAND_KEY, out slice_command);
                        var group = new ActionGroup(new_pie.id);
                        group.add_action(new KeyAction(slice_name, slice_icon, slice_command, is_quick_action));
                        new_pie.add_group(group);
                    } else if (slice_type == typeof(PieAction).name()) {
                        string slice_command;
                        this.data.get(child, DataPos.REAL_COMMAND_PIE, out slice_command);
                        var group = new ActionGroup(new_pie.id);
                        group.add_action(new PieAction(slice_command, is_quick_action));
                        new_pie.add_group(group);
                    } else if (slice_type == typeof(UriAction).name()) {
                        string slice_command;
                        this.data.get(child, DataPos.DISPLAY_COMMAND_URI, out slice_command);
                        var group = new ActionGroup(new_pie.id);
                        group.add_action(new UriAction(slice_name, slice_icon, slice_command, is_quick_action));
                        new_pie.add_group(group);
                    } else {
                        string slice_command;
                        this.data.get(child, DataPos.REAL_COMMAND_GROUP, out slice_command);
                    
                        if (slice_command == typeof(MenuGroup).name()) {
                            var group = new MenuGroup(new_pie.id);
                            new_pie.add_group(group);
                        } else if (slice_command == typeof(DevicesGroup).name()) {
                            var group = new DevicesGroup(new_pie.id);
                            new_pie.add_group(group);
                        } else if (slice_command == typeof(BookmarkGroup).name()) {
                            var group = new BookmarkGroup(new_pie.id);
                            new_pie.add_group(group);
                        }
                    } 
                    
                } while (this.data.iter_next(ref child));
            }
        }         
    }
}

}
