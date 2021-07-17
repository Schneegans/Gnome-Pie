/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2021 Simon Schneegans
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
///
/////////////////////////////////////////////////////////////////////////

public class NewsWindow: Gtk.Dialog {

    public const int news_count = 2;

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
