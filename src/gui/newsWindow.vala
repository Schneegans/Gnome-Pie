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
/// 
/////////////////////////////////////////////////////////////////////////

public class NewsWindow: Gtk.Dialog {

    public static const int news_count = 1;
    
    /////////////////////////////////////////////////////////////////////
    /// 
    /////////////////////////////////////////////////////////////////////

    public NewsWindow () {
        this.title = "Gnome-Pie";
        
        this.set_border_width(5);
        
        var box = new Gtk.VBox(false, 12);
        
            var image = new Gtk.Image.from_icon_name("gnome-pie", Gtk.IconSize.DIALOG);
            box.pack_start(image);
        
            var news = new Gtk.Label("");
                news.wrap = true;
                news.set_width_chars(75);
                news.set_markup("<b>Gnome-Pie needs your help!</b>\n\n" +
            
                     "Hey, this is Simon, developer of Gnome-Pie. I’m going to " +
                     "write my Bachelor thesis on pie menus! In order to improve " +
                     "Gnome-Pie to the limits, I need some information on how " +
                     "you use Gnome-Pie.\n\n" +

                     "<b>So please help improving this software by sending the " +
                     "file 'gnome-pie.stats' located in <a href='file:" + 
                     Paths.config_directory + "'>" + Paths.config_directory + 
                     "</a> by email to <a href='mailto:pie-stats@simonschneegans.de?subject=statistics'>" + 
                     "pie-stats@simonschneegans.de</a>!</b>\n\n" + 
                     
                     "There is no personal information in this file. Only " +
                     "information on your usage frequency, how fast you use " +
                     "Gnome-Pie and how many Pies with how many Slices you " +
                     "have configured. If you have any questions regarding " +
                     "this topic please send an email to " +
                     "<a href='mailto:code@simonschneegans.de'>code@simonschneegans.de</a>!\n\n" +
                     
                     "Thank you so much! It’s going to be exciting!");
                 
            box.pack_start(news, false, false);
            
            var check = new Gtk.CheckButton.with_label("Don't show this window again.");
                check.toggled.connect((check_box) => {
                    var checky = check_box as Gtk.CheckButton;
                    
                    if (checky.active)  Config.global.showed_news = news_count;
                    else                Config.global.showed_news = news_count-1;
                    
                    Config.global.save();
                });
                
            box.pack_end(check);
        
        (this.get_content_area() as Gtk.VBox).pack_start(box);
        this.get_content_area().show_all();
        
        this.add_button(Gtk.Stock.CLOSE, 0);
        
        this.response.connect((id) => {
            if (id == 0)
                this.hide();
        });
    }
}

}
