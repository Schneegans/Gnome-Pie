/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2016 by Simon Schneegans
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// This Group keeps a history of the last used Clipboard entries.
/// Experimental. Not enabled.
/////////////////////////////////////////////////////////////////////////

public class ClipboardGroup : ActionGroup {

    /////////////////////////////////////////////////////////////////////

    private class ClipboardItem : GLib.Object {

        public string name { get; protected set; }
        public string icon { get; protected set; }

        protected Gtk.Clipboard clipboard { get; set; }
        protected static Key paste_key = new Key.from_string("<Control>v");

        public virtual void paste() {}
    }

    /////////////////////////////////////////////////////////////////////

    private class TextClipboardItem : ClipboardItem {

        public TextClipboardItem(Gtk.Clipboard clipboard) {
            GLib.Object(clipboard : clipboard,
                        name      : clipboard.wait_for_text(),
                        icon      : "edit-paste");

            // check whether a file has been copied and search for a cool icon
            var first_line = this.name.substring(0, this.name.index_of("\n"));
            var file = GLib.File.new_for_path(first_line);

            if (file.query_exists()) {
                try {
                    var info = file.query_info("standard::icon", 0);
                    this.icon = Icon.get_icon_name(info.get_icon().to_string());
                } catch (Error e) {
                    warning("Failed to generate icon for ClipboardGroupItem.");
                }
            }
        }

        public override void paste() {
            clipboard.set_text(name, name.length);
            paste_key.press();
        }
    }

    /////////////////////////////////////////////////////////////////////

    private class ImageClipboardItem : ClipboardItem {

        private Gdk.Pixbuf image { get; set; }

        public ImageClipboardItem(Gtk.Clipboard clipboard) {
            GLib.Object(clipboard : clipboard,
                        name      : _("Image data"),
                        icon      : "image-viewer");
            this.image = clipboard.wait_for_image();
        }

        public override void paste() {
            clipboard.set_image(image);
            paste_key.press();
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// The maximum remembered items of the clipboard.
    /////////////////////////////////////////////////////////////////////

    public int max_items {get; set; default=8; }

    /////////////////////////////////////////////////////////////////////

    public ClipboardGroup(string parent_id) {
        GLib.Object(parent_id : parent_id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of ActionGroup. It sets the display
    /// name for this ActionGroup, it's icon name and the string used in
    /// the pies.conf file for this kind of ActionGroups.
    /////////////////////////////////////////////////////////////////////

    public static GroupRegistry.TypeDescription register() {
        var description = new GroupRegistry.TypeDescription();
        description.name = _("Group: Clipboard");
        description.icon = "edit-paste";
        description.description = _("Manages your Clipboard.");
        description.id = "clipboard";
        return description;
    }

    /////////////////////////////////////////////////////////////////////
    /// The clipboard to be monitored.
    /////////////////////////////////////////////////////////////////////

    private Gtk.Clipboard clipboard;

    private bool ignore_next_change = false;

    private Gee.ArrayList<ClipboardItem?> items;

    construct {
        this.items = new Gee.ArrayList<ClipboardItem?>();
        this.clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
        this.clipboard.owner_change.connect(this.on_change);
    }

    /////////////////////////////////////////////////////////////////////
    /// This one is called, when the ActionGroup is saved.
    /////////////////////////////////////////////////////////////////////

    public override void on_save(Xml.TextWriter writer) {
        base.on_save(writer);
        writer.write_attribute("max_items", this.max_items.to_string());
    }

    /////////////////////////////////////////////////////////////////////
    /// This one is called, when the ActionGroup is loaded.
    /////////////////////////////////////////////////////////////////////

    public override void on_load(Xml.Node* data) {
        for (Xml.Attr* attribute = data->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;

            if (attr_name == "max_items") {
                this.max_items = int.parse(attr_content);
            }
        }
    }

    private void on_change() {
        if (ignore_next_change) {
            ignore_next_change = false;
            return;
        }

        if (this.clipboard.wait_is_text_available()) {
            if (clipboard.wait_for_text() != null) {
                add_item(new TextClipboardItem(this.clipboard));
            }
        } else if (this.clipboard.wait_is_image_available()) {
            add_item(new ImageClipboardItem(this.clipboard));
        }
    }

    private void add_item(ClipboardItem item) {

        // remove one item if there are too many
        if (this.items.size == this.max_items) {
            this.items.remove_at(0);
        }

        this.items.add(item);

        // update slices
        this.delete_all();

        for (int i=this.items.size-1; i>=0; --i) {
            var action = new SigAction(items[i].name, items[i].icon, i.to_string());
            action.activated.connect(() => {
                ignore_next_change = true;
                this.items[int.parse(action.real_command)].paste();
            });
            this.add_action(action);
        }

    }
}

}
