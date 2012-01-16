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

/////////////////////////////////////////////////////////////////////////    
/// This Group keeps a history of the last used Clipboard entries.
/// Experimental. Not enabled.
/////////////////////////////////////////////////////////////////////////

public class ClipboardGroup : ActionGroup {

    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////

    private class ClipboardItem : GLib.Object {
        
        public string name { get; private set; }
        public string icon { get; private set; }
        
        private Gtk.SelectionData contents;
    
        public ClipboardItem(Gtk.SelectionData contents) {
            this.contents = contents.copy();
            this.name = this.contents.get_text() ?? "";
            this.icon = "edit-paste";
        }
        
        public void paste() {
            debug(name);
        }
    }
    
    public ClipboardGroup(string parent_id) {
        GLib.Object(parent_id : parent_id);
    }
    
    /////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////
    
    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of ActionGroup. It sets the display
    /// name for this ActionGroup, it's icon name and the string used in 
    /// the pies.conf file for this kind of ActionGroups.
    /////////////////////////////////////////////////////////////////////
    
    public static void register(out GroupRegistry.TypeDescription description) {
        description = new GroupRegistry.TypeDescription();
        description.name = _("Group: Clipboard");
        description.icon = "edit-paste";
        description.description = _("Manages your Clipboard.");
        description.id = "clipboard";
    }
    
    /////////////////////////////////////////////////////////////////////
    /// The clipboard to be monitored.
    /////////////////////////////////////////////////////////////////////
    
    private Gtk.Clipboard clipboard;
    
    
    /////////////////////////////////////////////////////////////////////
    /// The maximum remembered items of the clipboard.
    /////////////////////////////////////////////////////////////////////
    
    private const int max_items = 6;
    
    private Gee.ArrayList<ClipboardItem?> items;
    
    construct {
        this.items = new Gee.ArrayList<ClipboardItem?>();
        this.clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
        this.clipboard.owner_change.connect(this.on_change);
    }
    
    private void on_change() {
        if (this.clipboard.wait_is_text_available()) {
            this.clipboard.request_contents(Gdk.Atom.intern("text/plain", false), this.add_item);
        }
    }
    
    private void add_item(Gtk.Clipboard c, Gtk.SelectionData contents) {
        var new_item = new ClipboardItem(contents);
        
        if (this.items.size == this.max_items)
            this.items.remove_at(0);
        
        this.items.add(new_item);
        
        // update slices
        this.delete_all();
        
        for (int i=0; i<this.items.size; ++i) {
            var action = new SigAction(items[i].name, items[i].icon, i.to_string());
            action.activated.connect(() => {
                this.items[int.parse(action.real_command)].paste();
            });
            this.add_action(action);
        }

    }
}

}
