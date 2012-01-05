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
/// A which has knowledge on all possible acion group types.
/////////////////////////////////////////////////////////////////////////

public class GroupRegistry : GLib.Object {
    
    /////////////////////////////////////////////////////////////////////
    /// A list containing all available ActionGroup types.
    /////////////////////////////////////////////////////////////////////
    
    public static Gee.ArrayList<Type> types { get; private set; }
    
    /////////////////////////////////////////////////////////////////////
    /// Three maps associating a displayable name for each ActionGroup, 
    /// an icon name and a name for the pies.conf file with it's type.
    /////////////////////////////////////////////////////////////////////
    
    public static Gee.HashMap<Type, TypeDescription?> descriptions { get; private set; }
    
    public struct TypeDescription {
        public string name { get; set; }
        public string icon { get; set; }
        public string description { get; set; }
        public string id { get; set; }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Registers all ActionGroup types.
    /////////////////////////////////////////////////////////////////////
    
    public static void init() {
        types = new Gee.ArrayList<Type>();
        descriptions = new Gee.HashMap<Type, TypeDescription?>();
    
        TypeDescription type_description;
        
        BookmarkGroup.register(out type_description);
        types.add(typeof(BookmarkGroup));
        descriptions.set(typeof(BookmarkGroup), type_description);
        
        DevicesGroup.register(out type_description);
        types.add(typeof(DevicesGroup));
        descriptions.set(typeof(DevicesGroup), type_description);
        
        MenuGroup.register(out type_description);
        types.add(typeof(MenuGroup));
        descriptions.set(typeof(MenuGroup), type_description);
        
        SessionGroup.register(out type_description);
        types.add(typeof(SessionGroup));
        descriptions.set(typeof(SessionGroup), type_description);
        
        WindowListGroup.register(out type_description);
        types.add(typeof(WindowListGroup));
        descriptions.set(typeof(WindowListGroup), type_description);
    }
}

}
