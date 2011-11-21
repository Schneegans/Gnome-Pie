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
/// A simple about Dialog.
/////////////////////////////////////////////////////////////////////////

public class GnomePieAboutDialog: Gtk.AboutDialog {

    public GnomePieAboutDialog () {
    	string[] devs = {
			"Simon Schneegans <code@simonschneegans.de>", 
            "Francesco Piccinno <stack.box@gmail.com>"
        };
        string[] artists = {
			"Simon Schneegans <code@simonschneegans.de>"
        };
    	string[] translators = {
    		"DE\t\t Simon Schneegans <code@simonschneegans.de>",
    		"IT\t\t Riccardo Traverso <gr3yfox.fw@gmail.com>",
    		"PT-BR\t Magnun Leno <magnun@codecommunity.org>",
    		"EN\t\t Simon Schneegans <code@simonschneegans.de>",
    		"KO\t\t Kim Boram <Boramism@gmail.com>",
            "ES\t\t Eduardo Anabalon <lalo1412@gmail.com>"
    	};
    	
    	// sort translators
    	GLib.List<string> translator_list = new GLib.List<string>();
    	foreach (var translator in translators)
    		translator_list.append(translator);
    		
    	translator_list.sort((a, b) => {
    		return a.ascii_casecmp(b);
    	});
    	
    	string translator_string = "";
    	foreach (var translator in translator_list)
	   		translator_string += translator + "\n";
        
        GLib.Object (
            artists : artists,
            authors : devs,
            translator_credits : translator_string,
            copyright : "Copyright (C) 2011 Simon Schneegans <code@simonschneegans.de>",
            program_name: "Gnome-Pie",
            logo_icon_name: "gnome-pie",
            website: "http://www.simonschneegans.de/?page_id=12",
            website_label: "www.gnome-pie.simonschneegans.de",
            version: "0.3.1"
        );
    }
}

}
