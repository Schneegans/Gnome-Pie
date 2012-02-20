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
/// A static class which beautifies the messages of the default logger.
/// Some of this code is inspired by plank's written by Robert Dyer. 
/// Thanks a lot for this project! 
/////////////////////////////////////////////////////////////////////////

public class Logger {

    /////////////////////////////////////////////////////////////////////
    /// If these are set to false, the according messages are not shown
    /////////////////////////////////////////////////////////////////////
    
    private static const bool display_debug = true; 
    private static const bool display_warning = true; 
    private static const bool display_error = true; 
    private static const bool display_message = true; 
    
    /////////////////////////////////////////////////////////////////////
    /// If these are set to false, the according messages are not logged
    /////////////////////////////////////////////////////////////////////
    
    private static const bool log_debug = false; 
    private static const bool log_warning = true; 
    private static const bool log_error = true; 
    private static const bool log_message = true; 
    
    /////////////////////////////////////////////////////////////////////
    /// If true, a time stamp is shown in each message.
    /////////////////////////////////////////////////////////////////////
    
    private static const bool display_time = false; 
    private static const bool log_time = true; 
    
    /////////////////////////////////////////////////////////////////////
    /// If true, the origin of the message is shown. In form file:line
    /////////////////////////////////////////////////////////////////////
    
    private static const bool display_file = false; 
    private static const bool log_file = false; 
    
    /////////////////////////////////////////////////////////////////////
    /// A regex, used to format the standard message.
    /////////////////////////////////////////////////////////////////////
    
    private static Regex regex = null;
    
    /////////////////////////////////////////////////////////////////////
    /// Limit log and statistics size to roughly 1 MB.
    /////////////////////////////////////////////////////////////////////
    
    private static const int max_log_length = 1000000;
    private static const int max_stats_length = 1000000;
    
    private static int log_length;
    private static int stats_length;
    
    /////////////////////////////////////////////////////////////////////
    /// Possible terminal colors.
    /////////////////////////////////////////////////////////////////////
    
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
    
    /////////////////////////////////////////////////////////////////////
    /// Creates the regex and binds the handler.
    /////////////////////////////////////////////////////////////////////
    
    public static void init() {
        log_length = -1;
        stats_length = -1;
    
        try {
			regex = new Regex("""(.*)\.vala(:\d+): (.*)""");
		} catch {}
		
        GLib.Log.set_handler(null, GLib.LogLevelFlags.LEVEL_MASK, log_func);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Appends a line to the statistics file
    /////////////////////////////////////////////////////////////////////
    
    public static void stats(string line) {
        var stats = GLib.FileStream.open(Paths.stats, "a");
            
        if (stats != null) {
            if (stats_length == -1) 
                stats_length = (int)stats.tell();
        
            string final_line = "[" + get_time() + "] " + line + "\n";
            stats.puts(final_line);
            stats_length += final_line.length;
        }
        
        if (stats_length > max_stats_length) {
            string content = "";
            
            try {
                GLib.FileUtils.get_contents(Paths.stats, out content);
                int split_index = content.index_of_char('\n', stats_length - (int)(max_stats_length*0.9));                
                GLib.FileUtils.set_contents(Paths.stats, content.substring(split_index+1));
                
                stats_length -= (split_index+1);
            } catch (GLib.FileError e) {}
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Appends a line to the log file
    /////////////////////////////////////////////////////////////////////
    
    private static void write_log_line(string line) {
        var log = GLib.FileStream.open(Paths.log, "a");
            
        if (log != null) {
            if (log_length == -1) 
                log_length = (int)log.tell();
                
            log.puts(line);
            log_length += line.length;
        }
        
        if (log_length > max_log_length) {
            string content = "";
            
            try {
                GLib.FileUtils.get_contents(Paths.log, out content);
                int split_index = content.index_of_char('\n', log_length - (int)(max_log_length*0.9));                
                GLib.FileUtils.set_contents(Paths.log, content.substring(split_index+1));
                
                log_length -= (split_index+1);
            } catch (GLib.FileError e) {}
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Displays a message.
    /////////////////////////////////////////////////////////////////////
    
    private static void message(string message, string message_log) {
        if (display_message) {
            stdout.printf(set_color(Color.GREEN, false) + "[" + (display_time ? get_time() + " " : "") + "MESSAGE]" + message);
        }
        
        if (log_message) {
            write_log_line("[" + (log_time ? get_time() + " " : "") + "MESSAGE]" + message_log);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Displays a Debug message.
    /////////////////////////////////////////////////////////////////////
    
    private static void debug(string message, string message_log) {
        if (display_debug) {
            stdout.printf(set_color(Color.BLUE, false) + "[" + (display_time ? get_time() + " " : "") + " DEBUG ]" + message);
        }
        
        if (log_debug) {
            write_log_line("[" + (log_time ? get_time() + " " : "") + " DEBUG ]" + message_log);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Displays a Warning message.
    /////////////////////////////////////////////////////////////////////
    
    private static void warning(string message, string message_log) {
        if (display_warning) {
            stdout.printf(set_color(Color.YELLOW, false) + "[" + (display_time ? get_time() + " " : "") + "WARNING]" + message);
        }
        
        if (log_warning) {
            write_log_line("[" + (log_time ? get_time() + " " : "") + "WARNING]" + message_log);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Displays a Error message.
    /////////////////////////////////////////////////////////////////////
    
    private static void error(string message, string message_log) {
        if (display_error) {
            stdout.printf(set_color(Color.RED, false) + "[" + (display_time ? get_time() + " " : "") + " ERROR ]" + message);
        }
        
        if (log_error) {
            write_log_line("[" + (log_time ? get_time() + " " : "") + " ERROR ]" + message_log);
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Helper method which resets the terminal color.
    /////////////////////////////////////////////////////////////////////
    
    private static string reset_color() {
		return "\x001b[0m";
	}
	
	/////////////////////////////////////////////////////////////////////
	/// Helper method which sets the terminal color.
	/////////////////////////////////////////////////////////////////////
	
	private static string set_color(Color color, bool bold) {
	    if (bold) return "\x001b[1;%dm".printf((int)color + 30);
	    else      return "\x001b[0;%dm".printf((int)color + 30);
	}
	
	/////////////////////////////////////////////////////////////////////
	/// Returns the current time in hh:mm:ss:mmmmmm
	/////////////////////////////////////////////////////////////////////
	
	private static string get_time() {
        var now = new DateTime.now_local();
	    return "%.4d:%.2d:%.2d:%.2d:%.2d:%.2d:%.6d".printf(now.get_year(), now.get_month(), now.get_day_of_month(), now.get_hour(), now.get_minute(), now.get_second(), now.get_microsecond());
	}
	
	/////////////////////////////////////////////////////////////////////
    /// Helper method to format the message.
    /////////////////////////////////////////////////////////////////////
	
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
	
	/////////////////////////////////////////////////////////////////////
    /// Helper method to format the message for logging.
    /////////////////////////////////////////////////////////////////////
	
	private static string create_log_message(string message) {
	    if (log_file && regex != null && regex.match(message)) {
			var parts = regex.split(message);
			return " [%s%s] %s\n".printf(parts[1], parts[2], parts[3]);
		} else if (regex != null && regex.match(message)) {
		    var parts = regex.split(message);
			return " %s\n".printf(parts[3]);
		} else {
		    return " " + message + "\n";
		}
	}
	
	/////////////////////////////////////////////////////////////////////
	/// The handler function.
	/////////////////////////////////////////////////////////////////////
	
	private static void log_func(string? d, LogLevelFlags flags, string text) {
		switch (flags) {
		    case LogLevelFlags.LEVEL_ERROR:
		    case LogLevelFlags.LEVEL_CRITICAL:
			    error(create_message(text), create_log_message(text));
			    break;
		    case LogLevelFlags.LEVEL_INFO:
		    case LogLevelFlags.LEVEL_MESSAGE:
			    message(create_message(text), create_log_message(text));
			    break;
		    case LogLevelFlags.LEVEL_DEBUG:
			    debug(create_message(text), create_log_message(text));
			    break;
		    case LogLevelFlags.LEVEL_WARNING:
		    default:
			    warning(create_message(text), create_log_message(text));
			    break;
		}
	}
}

}
