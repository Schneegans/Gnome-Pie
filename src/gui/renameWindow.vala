/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2015 by Simon Schneegans
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
/// A window which allows selection of a new name for a Pie.
/////////////////////////////////////////////////////////////////////////

public class RenameWindow : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Gets emitted when the user selects a new name.
    /////////////////////////////////////////////////////////////////////

    public signal void on_ok(string new_name);

    /////////////////////////////////////////////////////////////////////
    /// Some Widgets used by this dialog.
    /////////////////////////////////////////////////////////////////////

    private Gtk.Dialog window = null;
    private Gtk.Entry entry = null;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, constructs the Widget.
    /////////////////////////////////////////////////////////////////////

    public RenameWindow() {
        try {

            Gtk.Builder builder = new Gtk.Builder();

            builder.add_from_file (Paths.ui_files + "/rename_pie.ui");

            window = builder.get_object("window") as Gtk.Dialog;
            entry = builder.get_object("name-entry") as Gtk.Entry;

            entry.activate.connect(this.on_ok_button_clicked);

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
    /// Displays the window on the screen.
    /////////////////////////////////////////////////////////////////////

    public void show() {
        this.window.show_all();
        this.entry.is_focus = true;
    }

    /////////////////////////////////////////////////////////////////////
    /// Make the text entry display the name of the Pie with given ID.
    /////////////////////////////////////////////////////////////////////

    public void set_pie(string id) {
        entry.text = PieManager.get_name_of(id);
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the ok button is pressed.
    /////////////////////////////////////////////////////////////////////

    private void on_ok_button_clicked() {
        this.on_ok(entry.text);
        this.window.hide();
    }

    /////////////////////////////////////////////////////////////////////
    /// Called when the cancel button is pressed.
    /////////////////////////////////////////////////////////////////////

    private void on_cancel_button_clicked() {
        this.window.hide();
    }
}

}
