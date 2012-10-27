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

[DBus (name = "org.openpie.main")]
interface DBusInterface : Object {
    public signal void on_select(int id, string item);
    public abstract int show_menu(string menu) throws IOError;   
}

public class Test : GLib.Object {

    private DBusInterface open_pie = null;
    private BindingManager bindings = null;
    
    private int menu_id = 0;

    public void run() {

        this.bindings = new BindingManager();
        this.bindings.bind(new Trigger.from_string("<Ctrl>A"), "test");
        
        try {
            this.open_pie = Bus.get_proxy_sync(BusType.SESSION, "org.openpie.main",
                                                                "/org/openpie/main");
                                                                
            this.bindings.on_press.connect((id) => {
                this.menu_id = this.open_pie.show_menu(this.generate_menu());
                message("Sent request! Got ID: %d", this.menu_id);
            });
            
            this.open_pie.on_select.connect((id, item) => {
                message("Got selection! ID: %d, Item: %s", id, item);
            });
        
        } catch (IOError e) {
            error(e.message);
        }  
    }

    private string generate_menu() {
        var b = new Json.Builder();
        
        b.begin_object();
            b.set_member_name("subs").begin_array();
                b.begin_object();
                    b.set_member_name("text").add_string_value("File");
                    b.set_member_name("icon").add_string_value("file");
                    b.set_member_name("angle").add_double_value(GLib.Math.PI*0.5);
                    b.set_member_name("subs").begin_array();
                        b.begin_object();
                            b.set_member_name("text").add_string_value("Up");
                            b.set_member_name("icon").add_string_value("stock_up");
                            b.set_member_name("angle").add_double_value(0.0);
                        b.end_object();
                        b.begin_object();
                            b.set_member_name("text").add_string_value("Down");
                            b.set_member_name("icon").add_string_value("stock_down");
                            b.set_member_name("angle").add_double_value(GLib.Math.PI);
                        b.end_object();
                        b.begin_object();
                            b.set_member_name("text").add_string_value("Left");
                            b.set_member_name("icon").add_string_value("stock_left");
                            b.set_member_name("angle").add_double_value(GLib.Math.PI*1.5);
                        b.end_object();
                        b.begin_object();
                            b.set_member_name("text").add_string_value("Right");
                            b.set_member_name("icon").add_string_value("stock_right");
                            b.set_member_name("angle").add_double_value(GLib.Math.PI*0.5);
                        b.end_object();
                    b.end_array();
                b.end_object();
                b.begin_object();
                    b.set_member_name("text").add_string_value("Edit");
                    b.set_member_name("icon").add_string_value("edit");
                    b.set_member_name("angle").add_double_value(GLib.Math.PI*1.5);
                b.end_object();
            b.end_array();
        b.end_object();
        
        var generator = new Json.Generator();
        generator.root = b.get_root();
     
        return generator.to_data(null);
    }
}

}
