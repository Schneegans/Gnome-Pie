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

public class Test : GLib.Object {

    private DBusInterface open_pie = null;
    private BindingManager bindings = null;

    private int menu_id = 0;

    public void run() {

        this.bindings = new BindingManager();
        this.bindings.bind(new Trigger.from_string("<Ctrl>A"), "test");

        try {
            this.open_pie = Bus.get_proxy_sync(BusType.SESSION, "org.gnome.openpie",
                                                                "/org/gnome/openpie");

            // this.bindings.on_press.connect((id) => {
            //     this.menu_id = this.open_pie.show_menu(this.main_menu());
            //     message("Sent request! Got ID: %d", this.menu_id);
            // });



            this.open_pie.on_select.connect((id, item) => {
                if (item == "") {
                    message("Got no selection! ID: %d", id);
                } else {
                    message("Got selection! ID: %d, Item: %s", id, item);
                }

                GLib.Timeout.add(2000, open_menu);
            });

            open_menu();

        } catch (IOError e) {
            error(e.message);
        }
    }

    private bool open_menu() {
        // this.menu_id = this.open_pie.show_menu(this.generate_menu_random());
        // this.menu_id = this.open_pie.show_menu(this.generate_menu(2, 8));
        this.menu_id = this.open_pie.show_menu(this.main_menu());
        message("Sent request! Got ID: %d", this.menu_id);

        return false;
    }

    private string main_menu() {

        string[5]  names = {"File", "Edit", "Find", "Tools", "Help"};

        var subs = new Gee.ArrayList<Gee.ArrayList<string>>();

        subs.add(new Gee.ArrayList<string>());
        subs.get(0).add("Open");
        subs.get(0).add("Save");
        subs.get(0).add("Close");
        subs.get(0).add("Print");

        subs.add(new Gee.ArrayList<string>());
        subs.get(1).add("Copy");
        subs.get(1).add("Cut");
        subs.get(1).add("Paste");
        subs.get(1).add("Undo");
        subs.get(1).add("Redo");

        subs.add(new Gee.ArrayList<string>());
        subs.get(2).add("Find next");
        subs.get(2).add("Find previous");
        subs.get(2).add("Find & replace");
        subs.get(2).add("Find in files");
        subs.get(2).add("Incremental find");

        subs.add(new Gee.ArrayList<string>());
        subs.get(3).add("Snippets");
        subs.get(3).add("Build");
        subs.get(3).add("Macros");
        subs.get(3).add("Build System");
        subs.get(3).add("Preferences");

        subs.add(new Gee.ArrayList<string>());
        subs.get(4).add("Documentation");
        subs.get(4).add("Purchase license");
        subs.get(4).add("Enter license");
        subs.get(4).add("About");

        var b = new Json.Builder();

        b.begin_object();
            b.set_member_name("subs").begin_array();

            for (int i=0; i<subs.size; ++i) {
                b.begin_object();
                    b.set_member_name("text").add_string_value(names[i]);
                    b.set_member_name("icon").add_string_value("Icon");

                    b.set_member_name("subs").begin_array();
                    for (int j=0; j<subs.get(i).size; ++j) {
                        b.begin_object();
                        b.set_member_name("text").add_string_value(subs.get(i).get(j));
                        b.set_member_name("icon").add_string_value("Icon");
                        b.end_object();

                    }
                    b.end_array();

                b.end_object();
            }

            b.end_array();
        b.end_object();

        var generator = new Json.Generator();
        generator.root = b.get_root();

        return generator.to_data(null);
    }

    private string generate_menu_random() {
        var b = new Json.Builder();

        b.begin_object();
            b.set_member_name("subs").begin_array();

            int width = GLib.Random.int_range(4, 10);
            for (int w=0; w<width; ++w) {
                int sub_width = GLib.Random.int_range(4, 10);
                int sub_depth = GLib.Random.int_range(1, 4);

                if (sub_depth > 0)
                    add_sub_menu(b, sub_depth - 1, sub_width, w);
            }

            b.end_array();
        b.end_object();

        var generator = new Json.Generator();
        generator.root = b.get_root();

        return generator.to_data(null);
    }

    private string generate_menu(int depth, int width) {
        var b = new Json.Builder();

        b.begin_object();
            b.set_member_name("subs").begin_array();

            for (int w=0; w<width; ++w) {
                add_sub_menu(b, depth - 1, width, w);
            }

            b.end_array();
        b.end_object();

        var generator = new Json.Generator();
        generator.root = b.get_root();

        return generator.to_data(null);
    }

    private void add_sub_menu(Json.Builder b, int depth, int width, int which) {
        if (depth >= 0) {
            b.begin_object();
                b.set_member_name("text").add_string_value("Text %d".printf(which+1));
                b.set_member_name("icon").add_string_value("Icon");

                if (depth > 0) {
                    b.set_member_name("subs").begin_array();


                    for (int w=0; w<width; ++w) {
                        add_sub_menu(b, depth - 1, width, w);
                    }

                    b.end_array();

                }

            b.end_object();
        }
    }



}

}
