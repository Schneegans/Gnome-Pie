Gnome-Pie
======

**Gnome-Pie** is a circular application launcher for Linux. It is made of several pies, each consisting of multiple slices. The user presses a key stroke which opens the desired pie. By activating one of its slices, applications may be launched, key presses may be simulated or files can be opened.

Feel free to visit its **homepage** at http://gnome-pie.simonschneegans.de

It is inspired by an addon written for the game World of Warcraft.
(http://go-hero.net/opie/)


## About this Branch

The aim of this branch is to create a more intuitive an visually appealing configuration menu.

## Installing from a PPA

There is a PPA with a recent version of Gnome-Pie. If you simply want to test it, it's very easy to install:

~~~~
sudo add-apt-repository ppa:simonschneegans/testing
sudo apt-get update
sudo apt-get install gnome-pie
~~~~

## Compiling and installing from source

First of all, install all dependancies:

~~~~
sudo apt-get install libgtk2.0-dev libcairo2-dev libappindicator-dev libgee-dev libxml2-dev libxtst-dev libgnome-menu-dev valac cmake libunique-dev libbamf-dev libwnck-dev
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

## Usage

Now you may launch it by Pressing <ctrl><Alt>A to open up a default Pie with your default applications. There are some other Pies defined --- just open up the configuration dialog by activating the appropriate entry in the appindicator menu or by launching gnome-pie for a second time. There you may configure the Pies to suit your needs.

You can open Pies not only by presing their key stroke. Alternatively you may open any Pie by invoking gnome-pie --open 123 where 123 is the ID of the desired Pie (which is displayed in the configuration dialog).

## License

Copyright (C) 2011 Simon Schneegans <code@simonschneegans.de>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
