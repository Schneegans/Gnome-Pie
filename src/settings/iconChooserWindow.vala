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

// A window which allows selection of an Icon of the user's current icon 
// theme. Loading of Icons happens in an extra thread.

public class IconSelectWindow : Gtk.Window {

    private static Gtk.ListStore icon_list = null;
    
    private static bool loading {get; set; default = false;}
    private static bool need_reload {get; set; default = true;}
    
    private const string disabled_contexts = "Animations, FileSystems, MimeTypes";
    private Gtk.TreeModelFilter icon_list_filtered = null;
    private Gtk.IconView icon_view = null;
    private Gtk.Spinner spinner = null;
    
    private class ListEntry {
        public string name;
        public IconContext context;
        public Gdk.Pixbuf pixbuf;
    }
    
    private GLib.AsyncQueue<ListEntry?> load_queue;
    
    private enum IconContext {
        ALL,
        APPS,
        ACTIONS,
        PLACES,
        FILES,
        EMOTES,
        OTHER
    }
    
    public string _active_icon = "application-default-icon";
    
    public string active_icon {
        get {
            return _active_icon;
        }
        set {
            _active_icon = value;

            icon_list_filtered.foreach((model, path, iter) => {
                string name = "";
                model.get(iter, 0, out name);
                
                if (name == value) {
                    this.icon_view.select_path(path);
                    this.icon_view.scroll_to_path(path, true, 0.5f, 0.0f);
                    this.icon_view.set_cursor(path, null, false);
                }
                return (name == value);
            });
        }
    }
    
    public signal void on_select(string icon_name);
    
    public IconSelectWindow() {
        this.title = _("Choose an Icon");
        this.modal = true;
        this.set_size_request(290, 450);
        this.delete_event.connect(hide_on_delete);
        this.load_queue = new GLib.AsyncQueue<ListEntry?>();
            
        if (this.icon_list == null) {
            this.icon_list = new Gtk.ListStore(3, typeof(string), typeof(IconContext), typeof(Gdk.Pixbuf)); 
            this.icon_list.set_default_sort_func(() => {return 0;});

            Gtk.IconTheme.get_default().changed.connect(() => {
                if (this.visible) load_icons();
                else              need_reload = true;
            });
        } 
        
        icon_list_filtered = new Gtk.TreeModelFilter(this.icon_list, null);
        
        var main_vbox = new Gtk.VBox(false, 12);
            main_vbox.border_width = 12;
        
            var context_combo = new Gtk.ComboBox.text();
                context_combo.append_text(_("All icons"));
                context_combo.append_text(_("Applications"));
                context_combo.append_text(_("Actions"));
                context_combo.append_text(_("Places"));
                context_combo.append_text(_("File types"));
                context_combo.append_text(_("Emotes"));
                context_combo.append_text(_("Miscellaneous"));

                context_combo.set_active(0);
                
                context_combo.changed.connect(() => {
                    icon_list_filtered.refilter();
                });
                
                main_vbox.pack_start(context_combo, false, false);
                
            var filter = new Gtk.Entry();
                filter.primary_icon_stock = Gtk.Stock.FIND;
                filter.primary_icon_activatable = false;
                filter.secondary_icon_stock = Gtk.Stock.CLEAR;
                main_vbox.pack_start(filter, false, false);
                
                icon_list_filtered.set_visible_func((model, iter) => {
                    string name = "";
                    IconContext context = IconContext.ALL;
                    model.get(iter, 0, out name);
                    model.get(iter, 1, out context);
                    
                    if (name == null) return false;
                    
                    return (context_combo.get_active() == context || 
                            context_combo.get_active() == IconContext.ALL) && 
                            name.down().contains(filter.text.down());
                });
                
                filter.icon_release.connect((pos, event) => {
                    if (pos == Gtk.EntryIconPosition.SECONDARY)
                        filter.text = "";
                });
                
                filter.notify["text"].connect(() => {
                    icon_list_filtered.refilter();
                });
            
            var scroll = new Gtk.ScrolledWindow (null, null);
                scroll.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
                scroll.set_shadow_type (Gtk.ShadowType.IN);

                this.icon_view = new Gtk.IconView.with_model(icon_list_filtered);
                    this.icon_view.item_width = 32;
                    this.icon_view.item_padding = 3;
                    this.icon_view.pixbuf_column = 2;
                    this.icon_view.tooltip_column = 0;
                    
                    this.icon_view.selection_changed.connect(() => {
                        foreach (var path in icon_view.get_selected_items()) {
                            Gtk.TreeIter iter;
                            icon_list_filtered.get_iter(out iter, path);
                            icon_list_filtered.get(iter, 0, out this._active_icon);
                        }
                    });
                    
                    this.icon_view.item_activated.connect((path) => {
                        Gtk.TreeIter iter;
                        icon_list_filtered.get_iter(out iter, path);
                        icon_list_filtered.get(iter, 0, out this._active_icon);
                        this.on_select(this.active_icon);
                        this.hide();
                    });
            
                scroll.add(icon_view);
                
                main_vbox.pack_start(scroll, true, true);
            
            // button box
            var bottom_box = new Gtk.HBox(false, 6);
            
                var bbox = new Gtk.HButtonBox();
                    bbox.set_spacing(6);
                    bbox.set_layout(Gtk.ButtonBoxStyle.END);
                    
                    var cancel_button = new Gtk.Button.from_stock(Gtk.Stock.CANCEL);
                        cancel_button.clicked.connect(() => { 
                            this.hide();
                        });
                        bbox.pack_start(cancel_button);
                        
                    var ok_button = new Gtk.Button.from_stock(Gtk.Stock.OK);
                        ok_button.clicked.connect(() => { 
                            this.on_select(this.active_icon);
                            this.hide();
                        });
                        bbox.pack_start(ok_button);
                        
                    bottom_box.pack_end(bbox, false);
                
                spinner = new Gtk.Spinner();
                    spinner.set_size_request(16, 16);
                    spinner.start();
                    
                    bottom_box.pack_start(spinner, false, false);
                    
                main_vbox.pack_start(bottom_box, false);
            
        main_vbox.show_all();
        spinner.visible = this.loading;
        this.add(main_vbox);
        this.set_focus(icon_view);
    }
    
    public override void show() {
        base.show();
        if (this.need_reload) {
            this.need_reload = false;
            this.load_icons();
        }
    }
    
    private void load_icons() {
        this.icon_list.clear();
        this.loading = true;
        this.icon_list.set_sort_column_id(-1, Gtk.SortType.ASCENDING);
        
        if (spinner != null)
            this.spinner.visible = true;
        
        try {
            unowned Thread loader = Thread.create<void*>(load_thread, false);
            loader.set_priority(ThreadPriority.LOW);
        } catch (GLib.ThreadError e) {
            error("Failed to create icon loader thread!");
        }
        
        Timeout.add(200, () => {
            while (load_queue.length() > 0) {
                var new_entry = load_queue.pop();
                Gtk.TreeIter current;
                icon_list.append(out current);
                icon_list.set(current, 0, new_entry.name, 
                                       1, new_entry.context,
                                       2, new_entry.pixbuf);
            }
            
            if (!loading) this.icon_list.set_sort_column_id(0, Gtk.SortType.ASCENDING);  

            return loading;
        });
    }
    
    private void* load_thread() {
        var icon_theme = Gtk.IconTheme.get_default();

        foreach (var context in icon_theme.list_contexts()) {
            if (!disabled_contexts.contains(context)) {
                foreach (var icon in icon_theme.list_icons(context)) {
                    IconContext icon_context = IconContext.OTHER;
                    switch(context) {
                        case "Apps": case "Applications":
                            icon_context = IconContext.APPS; break;
                        case "Emotes":
                            icon_context = IconContext.EMOTES; break;
                        case "Places": case "Devices":
                            icon_context = IconContext.PLACES; break;
                        case "Mimetypes":
                            icon_context = IconContext.FILES; break;
                        case "Actions":
                            icon_context = IconContext.ACTIONS; break;
                        default: break;
                    }
                    
                    try {
                        var new_entry = new ListEntry();
                        new_entry.name = icon;
                        new_entry.context = icon_context;
                        new_entry.pixbuf = icon_theme.load_icon(icon, 32, 0); 
                        
                        load_queue.push(new_entry);
                        
                        Thread.usleep(2000);
                    } catch (GLib.Error e) {
                        warning("Failed to load image " + icon);
                    }
                }
            }
        }
        
        loading = false;
        
        if (spinner != null)
            spinner.visible = this.loading;
        
        return null;
    }
}

}
