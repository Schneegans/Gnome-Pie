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

// Some of this code is inspired by plank's written by Robert Dyer. 
// Thanks a lot for this project!

// A static class which beautifies the messages of the default logger.

public class Logger {
    
    // if these are set to false, the according messages are not shown
    public static bool display_info    {get; set; default = true;}
    public static bool display_debug   {get; set; default = true;}
    public static bool display_warning {get; set; default = true;}
    public static bool display_error   {get; set; default = true;}
    
    public static bool display_time    {get; set; default = true;}
    public static bool display_file    {get; set; default = false;}
    
    private static Regex regex = null;
    
    private enum Color {
        BLACK,
        RED,
        GREEN,
        YELLOW,
        BLUE,
        PURPLE,
        TURQUOISE,
        WHITE
    }
    
    public static void init() {
        try {
			regex = new Regex("""(.*)\.vala(:\d+): (.*)""");
		} catch {}
		
        GLib.Log.set_default_handler(log_func);
    }
    
    private static void info(string message) {
        if (display_info) {
            stdout.printf(set_color(Color.GREEN, false) + "[" + get_time() + "MESSAGE]" + message);
        }
    }
    
    private static void debug(string message) {
        if (display_debug) {
            stdout.printf(set_color(Color.BLUE, false) + "[" + get_time() + " DEBUG ]" + message);
        }
    }
    
    private static void warning(string message) {
        if (display_warning) {
            stdout.printf(set_color(Color.YELLOW, false) + "[" + get_time() + "WARNING]" + message);
        }
    }
    
    private static void error(string message) {
        if (display_error) {
            stdout.printf(set_color(Color.RED, false) + "[" + get_time() + " ERROR ]" + message);
        }
    }
    
    private static string reset_color() {
		return "\x001b[0m";
	}
	
	private static string set_color(Color color, bool bold) {
	    if (bold) return "\x001b[1;%dm".printf((int)color + 30);
	    else      return "\x001b[0;%dm".printf((int)color + 30);
	}
	
	private static string get_time() {
	    if (display_time) {  
            var now = new DateTime.now_local ();
		    return "%.2d:%.2d:%.2d:%.6d ".printf (now.get_hour (), now.get_minute (), now.get_second (), now.get_microsecond ());
		} else {
		    return "";
		}
	}
	
	private static string create_message(string message) {
	    if (display_file && regex != null && regex.match(message)) {
			var parts = regex.split(message);
			return " [%s%s]%s %s\n".printf(parts[1], parts[2], reset_color(), parts[3]);
		} else if (regex != null && regex.match(message)) {
		    var parts = regex.split(message);
			return "%s %s\n".printf(reset_color(), parts[3]);
		} else {
		    return reset_color() + " " + message + "\n";
		}
	}
	
	private static void log_func(string? d, LogLevelFlags flags, string message) {
			
		switch (flags) {
		    case LogLevelFlags.LEVEL_ERROR:
		    case LogLevelFlags.LEVEL_CRITICAL:
			    error(create_message(message));
			    break;
		    case LogLevelFlags.LEVEL_INFO:
		    case LogLevelFlags.LEVEL_MESSAGE:
			    info(create_message(message));
			    break;
		    case LogLevelFlags.LEVEL_DEBUG:
			    debug(create_message(message));
			    break;
		    case LogLevelFlags.LEVEL_WARNING:
		    default:
			    warning(create_message(message));
			    break;
		}
	}
}

}
