/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2021 Simon Schneegans
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// A window which allows selection of an Icon of the user's current icon
/// theme. Custom icons/images can be selested as well. Loading of icons
/// happens in an extra thread and a spinner is displayed while loading.
/////////////////////////////////////////////////////////////////////////

public class IconSelectWindow : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// This signal gets emitted when the user selects a new icon.
    /////////////////////////////////////////////////////////////////////

    public signal void on_ok(string icon_name);

    /////////////////////////////////////////////////////////////////////
    /// Stores the currently selected icon.
    /////////////////////////////////////////////////////////////////////

    private string active_icon = "";

    /////////////////////////////////////////////////////////////////////
    /// The ListStore storing all theme-icons.
    /////////////////////////////////////////////////////////////////////

    private static Gtk.ListStore icon_list = null;

    /////////////////////////////////////////////////////////////////////
    /// True, if the icon theme is currently reloaded.
    /////////////////////////////////////////////////////////////////////

    private static bool loading = false;

    /////////////////////////////////////////////////////////////////////
    /// If set to true, the icon list will be reloaded next time the
    /// window opens.
    /////////////////////////////////////////////////////////////////////

    private static bool need_reload = true;

    /////////////////////////////////////////////////////////////////////
    /// Icons of these contexts won't appear in the list.
    /////////////////////////////////////////////////////////////////////

    private const string disabled_contexts = "Animations, FileSystems";

    /////////////////////////////////////////////////////////////////////
    /// The list of icons, filtered according to the chosen type and
    /// filter string.
    /////////////////////////////////////////////////////////////////////

    private Gtk.TreeModelFilter icon_list_filtered = null;

    /////////////////////////////////////////////////////////////////////
    /// The Gtk widget displaying the icons.
    /////////////////////////////////////////////////////////////////////

    private Gtk.IconView icon_view = null;

    /////////////////////////////////////////////////////////////////////
    /// This spinner is displayed when the icons are loaded.
    /////////////////////////////////////////////////////////////////////

    private Gtk.Spinner spinner = null;

    /////////////////////////////////////////////////////////////////////
    /// A Gtk widget used for custom icon/image selection.
    /////////////////////////////////////////////////////////////////////

    private Gtk.FileChooserWidget file_chooser = null;

    /////////////////////////////////////////////////////////////////////
    /// The notebook containing the different icon choice possibilities:
    /// from the theme or custom.
    /////////////////////////////////////////////////////////////////////

    private Gtk.Notebook tabs = null;

    /////////////////////////////////////////////////////////////////////
    /// The main window.
    /////////////////////////////////////////////////////////////////////

    private Gtk.Window window = null;

    /////////////////////////////////////////////////////////////////////
    /// A little structure containing data for one icon in the icon_view.
    /////////////////////////////////////////////////////////////////////

    private class ListEntry {
        public string name;
        public Gdk.Pixbuf pixbuf;
    }

    /////////////////////////////////////////////////////////////////////
    /// This queue is used for icon loading. A loading thread pushes
    /// icons into it --- the main thread updates the icon_view
    /// accordingly.
    /////////////////////////////////////////////////////////////////////

    private GLib.AsyncQueue<ListEntry?> load_queue;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates a new IconSelectWindow.
    /////////////////////////////////////////////////////////////////////

    public IconSelectWindow(Gtk.Window parent) {
        try {
            this.load_queue = new GLib.AsyncQueue<ListEntry?>();

            if (IconSelectWindow.icon_list == null) {
                IconSelectWindow.icon_list = new Gtk.ListStore(2, typeof(string), // icon name
                                                                  typeof(Gdk.Pixbuf)); // the icon itself

                // disable sorting until all icons are loaded
                // else loading becomes horribly slow
                IconSelectWindow.icon_list.set_default_sort_func(() => {return 0;});

                // reload if icon theme changes
                Gtk.IconTheme.get_default().changed.connect(() => {
                    if (this.window.visible) load_icons();
                    else IconSelectWindow.need_reload = true;
                });
            }

            // make the icon_view filterable
            this.icon_list_filtered = new Gtk.TreeModelFilter(IconSelectWindow.icon_list, null);

            Gtk.Builder builder = new Gtk.Builder();

            builder.add_from_file (Paths.ui_files + "/icon_select.ui");

            this.window = builder.get_object("window") as Gtk.Window;
            this.window.set_transient_for(parent);
            this.window.set_modal(true);

            this.tabs = builder.get_object("tabs") as Gtk.Notebook;

            this.spinner = builder.get_object("spinner") as Gtk.Spinner;
            this.spinner.start();

            (builder.get_object("ok-button") as Gtk.Button).clicked.connect(on_ok_button_clicked);
            (builder.get_object("cancel-button") as Gtk.Button).clicked.connect(on_cancel_button_clicked);

            // string filter entry
            var filter = builder.get_object("filter-entry") as Gtk.Entry;

                // only display items which have the selected type
                // and whose name contains the text entered in the entry
                this.icon_list_filtered.set_visible_func((model, iter) => {
                    string name = "";
                    model.get(iter, 0, out name);
                    if (name == null) return false;
                    return name.down().contains(filter.text.down());
                });

                // clear when the users clicks on the "clear" icon
                filter.icon_release.connect((pos, event) => {
                    if (pos == Gtk.EntryIconPosition.SECONDARY) {
                        filter.text = "";
                    }
                });

                // refilter on input
                filter.notify["text"].connect(() => {
                    this.icon_list_filtered.refilter();
                });

            // container for the icon_view
            var scroll = builder.get_object("icon-scrolledwindow") as Gtk.ScrolledWindow;

                // displays the filtered icons
                this.icon_view = new Gtk.IconView.with_model(this.icon_list_filtered);
                    this.icon_view.item_width = 32;
                    this.icon_view.item_padding = 2;
                    this.icon_view.pixbuf_column = 1;
                    this.icon_view.tooltip_column = 0;

                    // set active_icon if selection changes
                    this.icon_view.selection_changed.connect(() => {
                        foreach (var path in this.icon_view.get_selected_items()) {
                            Gtk.TreeIter iter;
                            this.icon_list_filtered.get_iter(out iter, path);
                            this.icon_list_filtered.get(iter, 0, out this.active_icon);
                        }
                    });

                    // hide this window when the user activates an icon
                    this.icon_view.item_activated.connect((path) => {
                        Gtk.TreeIter iter;
                        this.icon_list_filtered.get_iter(out iter, path);
                        this.icon_list_filtered.get(iter, 0, out this.active_icon);
                        this.on_ok(this.active_icon);
                        this.window.hide();
                    });

                scroll.add(this.icon_view);

            // file chooser widget
            this.file_chooser = builder.get_object("filechooser") as Gtk.FileChooserWidget;
                var file_filter = new Gtk.FileFilter();
                    file_filter.add_pixbuf_formats();
                    file_filter.set_filter_name(_("All supported image formats"));
                    file_chooser.add_filter(file_filter);

                // set active_icon if the user selected a file
                file_chooser.selection_changed.connect(() => {
                    if (file_chooser.get_filename() != null &&
                        GLib.FileUtils.test(file_chooser.get_filename(),
                                            GLib.FileTest.IS_REGULAR))

                        this.active_icon = file_chooser.get_filename();
                });

                // hide this window when the user activates a file
                file_chooser.file_activated.connect(() => {
                    this.active_icon = file_chooser.get_filename();
                    this.on_ok(this.active_icon);
                    this.window.hide();
                });

            this.window.set_focus(this.icon_view);
            this.window.delete_event.connect(this.window.hide_on_delete);

        } catch (GLib.Error e) {
            error("Could not load UI: %s\n", e.message);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Displays the window. The icons are reloaded if neccessary.
    /////////////////////////////////////////////////////////////////////

    public void show() {
        this.window.show_all();
        this.spinner.hide();

        if (IconSelectWindow.need_reload) {
            IconSelectWindow.need_reload = false;
            this.load_icons();
        }
    }

    public static void clear_icons() {
        if (IconSelectWindow.icon_list != null) {
            IconSelectWindow.need_reload = true;
            IconSelectWindow.icon_list.clear();
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Makes the window select the icon of the given Pie.
    /////////////////////////////////////////////////////////////////////

    public void set_icon(string icon) {
        this.active_icon = icon;

        if (icon.contains("/")) {
            this.file_chooser.set_filename(icon);
            this.tabs.set_current_page(1);
        } else {
            this.icon_list_filtered.foreach((model, path, iter) => {
                string name = "";
                model.get(iter, 0, out name);

                if (name == icon) {
                    this.icon_view.select_path(path);
                    this.icon_view.scroll_to_path(path, true, 0.5f, 0.0f);
                    this.icon_view.set_cursor(path, null, false);
                }
                return (name == icon);
            });

            this.tabs.set_current_page(0);
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the user clicks the ok button.
    /////////////////////////////////////////////////////////////////////

    private void on_ok_button_clicked() {
        this.on_ok(this.active_icon);
        this.window.hide();
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the user clicks the cancel button.
    /////////////////////////////////////////////////////////////////////

    private void on_cancel_button_clicked() {
        this.window.hide();
    }

    /////////////////////////////////////////////////////////////////////
    /// (Re)load all icons.
    /////////////////////////////////////////////////////////////////////

    private void load_icons() {
        // only if it's not loading currently
        if (!IconSelectWindow.loading) {
            IconSelectWindow.loading = true;
            IconSelectWindow.icon_list.clear();

            // display the spinner
            if (spinner != null)
                this.spinner.visible = true;

            // disable sorting of the icon_view - else it's horribly slow
            IconSelectWindow.icon_list.set_sort_column_id(-1, Gtk.SortType.ASCENDING);

            this.load_all.begin();

            // insert loaded icons every 200 ms
            Timeout.add(200, () => {
                while (this.load_queue.length() > 0) {
                    var new_entry = this.load_queue.pop();
                    Gtk.TreeIter current;
                    IconSelectWindow.icon_list.append(out current);
                    IconSelectWindow.icon_list.set(current, 0, new_entry.name,
                                                1, new_entry.pixbuf);
                }

                // enable sorting of the icon_view if loading finished
                if (!IconSelectWindow.loading) {
                    IconSelectWindow.icon_list.set_sort_column_id(0, Gtk.SortType.ASCENDING);
                }

                return loading;
            });
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads all icons of an icon theme and pushes them into the
    /// load_queue.
    /////////////////////////////////////////////////////////////////////

    private async void load_all() {
        var icon_theme = Gtk.IconTheme.get_default();
        foreach (var icon in icon_theme.list_icons(null)) {
            Idle.add(load_all.callback);
            yield;

            try {
                // create a new entry for the queue
                var new_entry = new ListEntry();
                new_entry.name = icon;
                new_entry.pixbuf = icon_theme.load_icon(icon, 32, Gtk.IconLookupFlags.FORCE_SIZE);

                this.load_queue.push(new_entry);

            } catch (GLib.Error e) {
                warning("Failed to load image " + icon);
            }
        }

        // finished loading
        IconSelectWindow.loading = false;

        // hide the spinner
        if (spinner != null) {
            spinner.visible = false;
        }
    }
}

}
