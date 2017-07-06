/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2017 by Simon Schneegans
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
/// A window which allows selection of a new Slice which is about to be
/// added to a Pie. It can be also used to edit an existing Slice
/////////////////////////////////////////////////////////////////////////

public class NewSliceWindow : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// This signal gets emitted when the user confirms his selection.
    /////////////////////////////////////////////////////////////////////

    public signal void on_select(ActionGroup action, bool as_new_slice, int at_position);

    /////////////////////////////////////////////////////////////////////
    /// The contained list of slice types. It contains both: Groups and
    /// single actions.
    /////////////////////////////////////////////////////////////////////

    private SliceTypeList slice_type_list = null;

    /////////////////////////////////////////////////////////////////////
    /// The IconSelectWindow used for icon selection for a Slice.
    /////////////////////////////////////////////////////////////////////

    private IconSelectWindow? icon_window = null;

    /////////////////////////////////////////////////////////////////////
    /// Some widgets of this window. Loaded by a ui-builder and stored
    /// for later access.
    /////////////////////////////////////////////////////////////////////

    private Gtk.Dialog window = null;
    private Gtk.Box name_box = null;
    private Gtk.Box command_box = null;
    private Gtk.Button icon_button = null;
    private Gtk.Box no_options_box = null;
    private Gtk.Box pie_box = null;
    private Gtk.Box hotkey_box = null;
    private Gtk.Box uri_box = null;
    private Gtk.Box quickaction_box = null;
    private Gtk.Box clipboard_box = null;
    private Gtk.Box workspace_only_box = null;
    private Gtk.Image icon = null;
    private Gtk.Entry name_entry = null;
    private CommandComboList command_list = null;
    private Gtk.Entry uri_entry = null;
    private Gtk.Switch quickaction_checkbutton = null;
    private Gtk.Switch workspace_only_checkbutton = null;
    private Gtk.Scale clipboard_slider = null;

    /////////////////////////////////////////////////////////////////////
    /// Two custom widgets. For Pie and hotkey selection respectively.
    /////////////////////////////////////////////////////////////////////

    private PieComboList pie_select = null;
    private TriggerSelectButton key_select = null;

    /////////////////////////////////////////////////////////////////////
    /// These members store information on the currently selected Slice.
    /////////////////////////////////////////////////////////////////////

    private string current_type = "";
    private string current_icon = "";
    private string current_id = "";
    private string current_custom_icon = "";
    private string current_hotkey = "";
    private string current_pie_to_open = "";

    /////////////////////////////////////////////////////////////////////
    /// The position of the edited Slice in its parent Pie.
    /////////////////////////////////////////////////////////////////////

    private int slice_position = 0;

    /////////////////////////////////////////////////////////////////////
    /// True, if the Slice i going to be added as a new Slice. Else it
    /// will edit the Slice at slice_position in its parent Pie.
    /////////////////////////////////////////////////////////////////////

    private bool add_as_new_slice = true;

    /////////////////////////////////////////////////////////////////////
    /// C'tor creates a new window.
    /////////////////////////////////////////////////////////////////////

    public NewSliceWindow() {
        try {

            Gtk.Builder builder = new Gtk.Builder();

            builder.add_from_file (Paths.ui_files + "/slice_select.ui");

            this.slice_type_list = new SliceTypeList();
            this.slice_type_list.on_select.connect((type, icon) => {

                this.name_box.hide();
                this.command_box.hide();
                this.icon_button.sensitive = false;
                this.no_options_box.hide();
                this.pie_box.hide();
                this.hotkey_box.hide();
                this.uri_box.hide();
                this.quickaction_box.hide();
                this.workspace_only_box.hide();
                this.clipboard_box.hide();

                this.current_type = type;

                switch (type) {
                    case "bookmarks": case "devices":
                    case "menu": case "session":
                        this.no_options_box.show();
                        this.set_icon(icon);
                        break;
                    case "window_list":
                        this.workspace_only_box.show();
                        this.set_icon(icon);
                        break;
                    case "clipboard":
                        this.clipboard_box.show();
                        this.set_icon(icon);
                        break;
                    case "app":
                        this.name_box.show();
                        this.command_box.show();
                        this.quickaction_box.show();
                        this.icon_button.sensitive = true;
                        if (this.current_custom_icon == "") this.set_icon(icon);
                        else                                this.set_icon(this.current_custom_icon);
                        break;
                    case "key":
                        this.name_box.show();
                        this.hotkey_box.show();
                        this.quickaction_box.show();
                        this.icon_button.sensitive = true;
                        if (this.current_custom_icon == "") this.set_icon(icon);
                        else                                this.set_icon(this.current_custom_icon);
                        break;
                    case "pie":
                        this.pie_box.show();
                        this.quickaction_box.show();
                        this.set_icon(PieManager.all_pies[this.pie_select.current_id].icon);
                        break;
                    case "uri":
                        this.name_box.show();
                        this.uri_box.show();
                        this.quickaction_box.show();
                        this.icon_button.sensitive = true;
                        if (this.current_custom_icon == "") this.set_icon(icon);
                        else                                this.set_icon(this.current_custom_icon);
                        break;
                }
            });

            this.name_box = builder.get_object("name-box") as Gtk.Box;
            this.command_box = builder.get_object("command-box") as Gtk.Box;
            this.icon_button = builder.get_object("icon-button") as Gtk.Button;
            this.no_options_box = builder.get_object("no-options-box") as Gtk.Box;
            this.pie_box = builder.get_object("pie-box") as Gtk.Box;
            this.pie_select = new PieComboList();
            this.pie_select.on_select.connect((id) => {
                this.current_pie_to_open = id;
                this.set_icon(PieManager.all_pies[id].icon);
            });

            this.pie_box.pack_start(this.pie_select, true, true);

            this.hotkey_box = builder.get_object("hotkey-box") as Gtk.Box;
            this.key_select = new TriggerSelectButton(false);
            this.hotkey_box.pack_start(this.key_select, false, true);
            this.key_select.on_select.connect((trigger) => {
                this.current_hotkey = trigger.name;
            });

            this.uri_box = builder.get_object("uri-box") as Gtk.Box;

            this.name_entry = builder.get_object("name-entry") as Gtk.Entry;
            this.uri_entry = builder.get_object("uri-entry") as Gtk.Entry;
            this.quickaction_checkbutton = builder.get_object("quick-action-checkbutton") as Gtk.Switch;
            this.quickaction_box = builder.get_object("quickaction-box") as Gtk.Box;
            this.icon = builder.get_object("icon") as Gtk.Image;

            this.command_list = new CommandComboList();
            this.command_list.on_select.connect((name, command, icon) => {
                this.set_icon(icon);
                this.name_entry.text = name;
            });

            this.command_box.pack_start(this.command_list, true, true);

            this.workspace_only_checkbutton = builder.get_object("workspace-only-checkbutton") as Gtk.Switch;
            this.workspace_only_box = builder.get_object("workspace-only-box") as Gtk.Box;

            this.clipboard_box = builder.get_object("clipboard-box") as Gtk.Box;
            this.clipboard_slider = (builder.get_object("clipboard-scale") as Gtk.Scale);
                 clipboard_slider.set_range(2, 24);
                 clipboard_slider.set_value(8);

            this.icon_button.clicked.connect(on_icon_button_clicked);

            var scroll_area = builder.get_object("slice-scrolledwindow") as Gtk.ScrolledWindow;
                scroll_area.add(this.slice_type_list);

            this.window = builder.get_object("window") as Gtk.Dialog;

            (builder.get_object("ok-button") as Gtk.Button).clicked.connect(on_ok_button_clicked);
            (builder.get_object("cancel-button") as Gtk.Button).clicked.connect(on_cancel_button_clicked);

            this.window.delete_event.connect(this.window.hide_on_delete);

        } catch (GLib.Error e) {
            error("Could not load UI: %s\n", e.message);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Sets the parent window, in order to make this window stay in
    /// front.
    /////////////////////////////////////////////////////////////////////

    public void set_parent(Gtk.Window parent) {
        this.window.set_transient_for(parent);
    }

    /////////////////////////////////////////////////////////////////////
    /// Sows the window on the screen.
    /////////////////////////////////////////////////////////////////////

    public void show() {
        this.slice_type_list.select_first();
        this.pie_select.select_first();
        this.key_select.set_trigger(new Trigger());
        this.window.show_all();
    }

    /////////////////////////////////////////////////////////////////////
    /// Reloads the window.
    /////////////////////////////////////////////////////////////////////

    public void reload() {
        this.pie_select.reload();
    }

    /////////////////////////////////////////////////////////////////////
    /// Makes all widgets display stuff according to the given action.
    /////////////////////////////////////////////////////////////////////

    public void set_action(ActionGroup group, int position) {
        this.set_default(group.parent_id, position);

        this.add_as_new_slice = false;
        string type = "";

        if (group.get_type().depth() == 2) {
            var action = group.actions[0];
            type = ActionRegistry.descriptions[action.get_type().name()].id;
            this.select_type(type);

            this.set_icon(action.icon);
            this.quickaction_checkbutton.active = action.is_quickaction;
            this.name_entry.text = action.name;

            switch (type) {
                case "app":
                    this.current_custom_icon = action.icon;
                    this.command_list.text = action.real_command;
                    break;
                case "key":
                    this.current_custom_icon = action.icon;
                    this.current_hotkey = action.real_command;
                    this.key_select.set_trigger(new Trigger.from_string(action.real_command));
                    break;
                case "pie":
                    this.pie_select.select(action.real_command);
                    break;
                case "uri":
                    this.current_custom_icon = action.icon;
                    this.uri_entry.text = action.real_command;
                    break;
            }

        } else {
            type = GroupRegistry.descriptions[group.get_type().name()].id;
            switch (type) {
                case "clipboard":
                    this.clipboard_slider.set_value((group as ClipboardGroup).max_items);
                    break;
                case "window_list":
                    this.workspace_only_checkbutton.active = (group as WindowListGroup).current_workspace_only;
                    break;

            }
            this.select_type(type);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Selects a default action.
    /////////////////////////////////////////////////////////////////////

    public void set_default(string pie_id, int position) {
        this.slice_position = position;
        this.add_as_new_slice = true;
        this.current_custom_icon = "";
        this.select_type("app");
        this.current_id = pie_id;
        this.key_select.set_trigger(new Trigger());
        this.pie_select.select_first();
        this.name_entry.text = _("Rename me!");
        this.command_list.text = "";
        this.uri_entry.text = "";
    }

    /////////////////////////////////////////////////////////////////////
    /// Selects a specific action type.
    /////////////////////////////////////////////////////////////////////

    private void select_type(string type) {
        this.current_type = type;
        this.slice_type_list.select(type);
    }

    /////////////////////////////////////////////////////////////////////
    /// Called, when the user presses the ok button.
    /////////////////////////////////////////////////////////////////////

    private void on_ok_button_clicked() {
        this.window.hide();

        ActionGroup group = null;

        switch (this.current_type) {
            case "bookmarks":   group = new BookmarkGroup(this.current_id);      break;
            case "devices":     group = new DevicesGroup(this.current_id);       break;
            case "menu":        group = new MenuGroup(this.current_id);          break;
            case "session":     group = new SessionGroup(this.current_id);       break;
            case "clipboard":
                var g = new ClipboardGroup(this.current_id);
                g.max_items = (int)this.clipboard_slider.get_value();
                group = g;
                break;
            case "window_list":
                var g = new WindowListGroup(this.current_id);
                g.current_workspace_only = this.workspace_only_checkbutton.active;
                group = g;
                break;
            case "app":
                group = new ActionGroup(this.current_id);
                group.add_action(new AppAction(this.name_entry.text, this.current_icon,
                                               this.command_list.text,
                                               this.quickaction_checkbutton.active));
                break;
            case "key":
                group = new ActionGroup(this.current_id);
                group.add_action(new KeyAction(this.name_entry.text, this.current_icon,
                                               this.current_hotkey,
                                               this.quickaction_checkbutton.active));
                break;
            case "pie":
                group = new ActionGroup(this.current_id);
                group.add_action(new PieAction(this.current_pie_to_open,
                                               this.quickaction_checkbutton.active));
                break;
            case "uri":
                group = new ActionGroup(this.current_id);
                group.add_action(new UriAction(this.name_entry.text, this.current_icon,
                                               this.uri_entry.text,
                                               this.quickaction_checkbutton.active));
                break;
        }

        this.on_select(group, this.add_as_new_slice, this.slice_position);
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the user presses the cancel button.
    /////////////////////////////////////////////////////////////////////

    private void on_cancel_button_clicked() {
        this.window.hide();
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the user presses the icon select button.
    /////////////////////////////////////////////////////////////////////

    private void on_icon_button_clicked(Gtk.Button button) {
        if (this.icon_window == null) {
            this.icon_window = new IconSelectWindow(this.window);
            this.icon_window.on_ok.connect((icon) => {
                this.current_custom_icon = icon;
                this.set_icon(icon);
            });
        }

        this.icon_window.show();
        this.icon_window.set_icon(this.current_icon);
    }

    /////////////////////////////////////////////////////////////////////
    /// Helper method which sets the icon of the icon select button.
    /// It assures that both can be displayed: A customly chosen image
    /// from or an icon from the current theme.
    /////////////////////////////////////////////////////////////////////

    private void set_icon(string icon) {
        if (icon.contains("/"))
            try {
                this.icon.pixbuf = new Gdk.Pixbuf.from_file_at_scale(icon, this.icon.get_pixel_size(),
                                                                     this.icon.get_pixel_size(), true);
            } catch (GLib.Error error) {
                warning(error.message);
            }
        else
            this.icon.icon_name = icon;

        this.current_icon = icon;
    }
}

}
