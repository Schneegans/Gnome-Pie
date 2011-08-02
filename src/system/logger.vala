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
    public class Logger {
        
        public static bool display_info {get; set; default = true;}
        public static bool display_debug {get; set; default = true;}
        public static bool display_warning {get; set; default = true;}
        public static bool display_error {get; set; default = true;}
        
        private static Regex regex = null;
        
        public static void init() {
            try {
				regex = new Regex("""(.*)\.vala(:\d+): (.*)""");
			} catch {}
			
            Log.set_default_handler(log_func);
        }
        
        private static void info(string message) {
            if (display_info) {
                stdout.printf(set_color(32, false) + "[INFO]" + reset_color() + message);
            }
        }
        
        private static void debug(string message) {
            if (display_debug) {
                stdout.printf(set_color(34, false) + "[DEBUG]" + reset_color() + message);
            }
        }
        
        private static void warning(string message) {
            if (display_warning) {
                stdout.printf(set_color(33, false) + "[WARNING]" + reset_color() + message);
            }
        }
        
        private static void error(string message) {
            if (display_error) {
                stdout.printf(set_color(31, false) + "[ERROR]" + reset_color()+ message);
            }
        }
        
        private static string reset_color() {
			return "\x001b[0m";
		}
		
		private static string set_color(int color, bool bold) {
		    if (bold) return "\x001b[1;%dm".printf(color);
		    else      return "\x001b[0;%dm".printf(color);
		}
		
		private static string create_message(string message) {
		    if (regex != null && regex.match(message)) {
				var parts = regex.split(message);
				return " %s%s: %s\n".printf(parts[1], parts[2], parts[3]);
			}
			return " " + message + "\n";
		}
		
		static void log_func(string? d, LogLevelFlags flags, string message) {
				
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
