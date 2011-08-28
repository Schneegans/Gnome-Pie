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

// A which has knowledge on all possible acion group types.

public class GroupRegistry : GLib.Object {
    
    public static Gee.ArrayList<Type> types {get; private set;}
    
    public static Gee.HashMap<Type, string> names {get; private set;}
    public static Gee.HashMap<Type, string> icons {get; private set;}
    public static Gee.HashMap<Type, string> settings_names {get; private set;}
    
    public static void init() {
        types = new Gee.ArrayList<Type>();
    
        names = new Gee.HashMap<Type, string>();
        icons = new Gee.HashMap<Type, string>();
        settings_names = new Gee.HashMap<Type, string>();
    
        string name = "";
        string icon = "";
        string settings_name = "";
        
        BookmarkGroup.register(out name, out icon, out settings_name);
        types.add(typeof(BookmarkGroup));
        names.set(typeof(BookmarkGroup), name);
        icons.set(typeof(BookmarkGroup), icon);
        settings_names.set(typeof(BookmarkGroup), settings_name);
        
        DevicesGroup.register(out name, out icon, out settings_name);
        types.add(typeof(DevicesGroup));
        names.set(typeof(DevicesGroup), name);
        icons.set(typeof(DevicesGroup), icon);
        settings_names.set(typeof(DevicesGroup), settings_name);
        
        MenuGroup.register(out name, out icon, out settings_name);
        types.add(typeof(MenuGroup));
        names.set(typeof(MenuGroup), name);
        icons.set(typeof(MenuGroup), icon);
        settings_names.set(typeof(MenuGroup), settings_name);
        
        SessionGroup.register(out name, out icon, out settings_name);
        types.add(typeof(SessionGroup));
        names.set(typeof(SessionGroup), name);
        icons.set(typeof(SessionGroup), icon);
        settings_names.set(typeof(SessionGroup), settings_name);
    }

}

}
