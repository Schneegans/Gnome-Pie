Gnome-Pie
======

Feel free to visit its **homepage** at http://simmesimme.github.io/gnome-pie.html

**Gnome-Pie** is a circular application launcher for Linux. It is made of several pies, each consisting of multiple slices. The user presses a key stroke which opens the desired pie. By activating one of its slices, applications may be launched, key presses may be simulated or files can be opened.


## Installing from a PPA!

There is a PPA with a recent version of Gnome-Pie. If you simply want to test it, it's very easy to install:

~~~~
sudo add-apt-repository ppa:simonschneegans/testing
sudo apt-get update
sudo apt-get install gnome-pie
~~~~

## Compiling and installing from source!

First of all, install all dependancies:

~~~~
sudo apt-get install libgtk-3-dev libcairo2-dev libappindicator3-dev libgee-dev libxml2-dev libxtst-dev libgnome-menu-3-dev valac cmake libunique-3.0-dev libbamf3-dev libwnck-3-dev bamfdaemon
~~~~

Then build  Gnome-Pie by typing:

~~~~
./make.sh
~~~~

Launch it with

~~~~
./gnome-pie
~~~~

If you want to install it system wide use

~~~~
cd build && sudo make install
~~~~

## Usage!

Now you may launch it by Pressing <ctrl><Alt>A to open up a default Pie with your default applications. There are some other Pies defined --- just open up the configuration dialog by activating the appropriate entry in the appindicator menu or by launching gnome-pie for a second time. There you may configure the Pies to suit your needs.

You can open Pies not only by presing their key stroke. Alternatively you may open any Pie by invoking gnome-pie --open 123 where 123 is the ID of the desired Pie (which is displayed in the configuration dialog).

## Support my work!

I really like working on Gnome-Pie — and you can help improving it! There are multiple ways:

### Translate Gnome-Pie!

This is really easy: [There is an how-to available](http://simmesimme.github.io/lessons/2015/08/07/translate-gnome-pie/)!

### Donate!

If you can’t afford the time to do the stuff mentioned above, but still want to help — you can help improving this software by buying some drinks for a poor student ;) ! You can [do this with the Flattr](http://flattr.com/thing/468485/Gnome-Pie) or by [donating via PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=X65SUVC4ZTQSC). If you happen to dislike PayPal, send a mail to code@simonschneegans.de and we can chat about this!

## License

Copyright (C) 2011-2015 Simon Schneegans <code@simonschneegans.de>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
