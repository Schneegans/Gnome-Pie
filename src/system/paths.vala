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
	
    public class Paths : GLib.Object {
    
        public static string pie_config         {get; private set; default="";}
        public static string default_pie_config {get; private set; default="";}
        public static string settings           {get; private set; default="";}
        public static string local_themes       {get; private set; default="";}
        public static string global_themes      {get; private set; default="";}
        public static string locales            {get; private set; default="";}
        public static string autostart          {get; private set; default="";}
        
        public static void init() {
        
            // get global paths
            var default_dir = GLib.File.new_for_path("/usr/share/gnome-pie/");
            if(!default_dir.query_exists()) {
                default_dir = GLib.File.new_for_path("/usr/local/gnome-pie/");
                
                if(!default_dir.query_exists()) {
                    try {
                        default_dir = GLib.File.new_for_path(GLib.Path.get_dirname(GLib.FileUtils.read_link("/proc/self/exe"))).get_child("resources");
                    } catch (GLib.FileError e) {
                        warning("Failed to get path of executable!");
                    }
                }
            }
            
            global_themes = default_dir.get_path() + "/themes";
            default_pie_config = default_dir.get_path() + "/pies.conf.default";
            
            // get locales path
            var locale_dir = GLib.File.new_for_path("/usr/share/locale/de/LC_MESSAGES/gnomepie.mo");
            if(locale_dir.query_exists()) {
                locale_dir = GLib.File.new_for_path("/usr/share/locale");
            } else {
                try {
                    locale_dir = GLib.File.new_for_path(GLib.Path.get_dirname(GLib.FileUtils.read_link("/proc/self/exe"))).get_child("resources/locale/de/LC_MESSAGES/gnomepie.mo");
                } catch (GLib.FileError e) {
                    warning("Failed to get path of executable!");
                }
                
                if(locale_dir.query_exists()) {
                    try {
                        locale_dir = GLib.File.new_for_path(GLib.Path.get_dirname(GLib.FileUtils.read_link("/proc/self/exe"))).get_child("resources/locale");
                    } catch (GLib.FileError e) {
                        warning("Failed to get path of executable!");
                    }
                }
            }
            
            locales = locale_dir.get_path();
        
            // get local paths
            var config_dir = GLib.File.new_for_path(GLib.Environment.get_user_config_dir()).get_child("gnome-pie");

            // create config_dir if neccasary
            if(!config_dir.query_exists()) {
                try {
                    config_dir.make_directory();
                } catch (GLib.Error e) {
                    error(e.message);
                }
            }
            
            // create local themes directory if neccasary
            var themes_dir = config_dir.get_child("themes");
            if(!themes_dir.query_exists()) {
                try {
                    themes_dir.make_directory();
                } catch (GLib.Error e) {
                    error(e.message);
                }
            }
            
            local_themes = themes_dir.get_path();
            
            // check for config file and copy default if it doesn't exist
            var config_file = config_dir.get_child("pies.conf");
            if(!config_file.query_exists()) {
            
                var default_conf = GLib.File.new_for_path(default_pie_config);
                if(default_conf.query_exists()) {
                    try {
                        default_conf.copy(config_file, GLib.FileCopyFlags.NONE);
                    } catch (GLib.Error e) {
                        error(e.message);
                    }
                } 
            }
            
            pie_config = config_file.get_path();
            settings = config_dir.get_path() + "/gnome-pie.conf";
            
            // autostart file name
            autostart = GLib.Path.build_filename(GLib.Environment.get_user_config_dir(), 
                                                 "autostart", "gnome-pie.desktop", null);
            
            // print results
            if (GLib.File.new_for_path(pie_config).query_exists()) 
                message("Found pie configuration file: " + pie_config);
            else                                                   
                warning("Failed to find pie configuration file \"pies.conf\"!");
                
            if (GLib.File.new_for_path(settings).query_exists()) 
                message("Found settings file: " + settings);
            else                                                   
                warning("Failed to find settings file \"gnome-pie.conf\"!");
                
            if (GLib.File.new_for_path(local_themes).query_exists()) 
                message("Found local themes directory: " + local_themes);
            else                                                   
                warning("Failed to find local themes directory!");
                
            if (GLib.File.new_for_path(global_themes).query_exists()) 
                message("Found global themes directory: " + global_themes);
            else                                                   
                warning("Failed to find global themes directory!");
        }    
    }
}
