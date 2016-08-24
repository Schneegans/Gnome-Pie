/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2016 by Simon Schneegans
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
///
/////////////////////////////////////////////////////////////////////////

public class NewsWindow: Gtk.Dialog {

    public static const int news_count = 2;

    /////////////////////////////////////////////////////////////////////
    ///
    /////////////////////////////////////////////////////////////////////

    public NewsWindow () {
        this.title = "Gnome-Pie";

        this.set_border_width(5);

        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);

            var image = new Gtk.Image.from_icon_name("gnome-pie", Gtk.IconSize.DIALOG);
            box.pack_start(image);

            var news = new Gtk.Label("");
                news.wrap = true;
                news.set_width_chars(75);
                news.set_markup("<b>Thank you!</b>\n\n");

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

        this.add_button(_("_Close"), 0);

        this.response.connect((id) => {
            if (id == 0)
                this.hide();
        });
    }
}

}
