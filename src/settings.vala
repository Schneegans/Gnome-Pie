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

    namespace Settings {
    
        private SettingsInstance instance = null;
    
        public SettingsInstance setting() {
            if (instance == null)
                instance = new SettingsInstance(); 
            return instance;
        }
        
        public class SettingsInstance : GLib.Object {
    
            public Theme  theme          {get; private set;}
            public double refresh_rate   {get; private set; default = 60.0;}
            public bool   show_indicator {get; set; default = true;}
            public bool   open_at_mouse  {get; set; default = false;}

            public SettingsInstance() {
                theme = new Theme("gloss");
            }
        }
    }
   
}
