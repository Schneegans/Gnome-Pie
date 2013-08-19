////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2013 by Simon Schneegans                                //
//                                                                            //
// This program is free software: you can redistribute it and/or modify it    //
// under the terms of the GNU General Public License as published by the Free //
// Software Foundation, either version 3 of the License, or (at your option)  //
// any later version.                                                         //
//                                                                            //
// This program is distributed in the hope that it will be useful, but        //
// WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY //
// or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License   //
// for more details.                                                          //
//                                                                            //
// You should have received a copy of the GNU General Public License along    //
// with this program.  If not, see <http://www.gnu.org/licenses/>.            //
////////////////////////////////////////////////////////////////////////////////

namespace GnomePie {

////////////////////////////////////////////////////////////////////////////////
// A base class for actions, which are executed when the users                //
// activates a menu item.                                                     //
////////////////////////////////////////////////////////////////////////////////

public abstract class Action : GLib.Object {

  //////////////////////////////////////////////////////////////////////////////
  //                          public interface                                //
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////// public abstract members /////////////////////////////

  // The command which gets executed when user activates the item.
  // It may be anything but has to be representable with a string.
  public abstract string real_command { get; construct set; }

  // The command displayed to the user. It should be a bit more
  // beautiful than the real_command.
  public abstract string display_command { get; }

  ///////////////////////////// public members /////////////////////////////////

  // The name of the Action.
  public virtual string name { get; set; }

  // The name of the icon of this Action. It should be in the users
  // current icon theme.
  public virtual string icon { get; set; }

  // True, if this Action is the quickAction of the associated Menu.
  // The quickAction of a Menu gets executed when the users clicks w/o
  // moving his pointer
  public virtual bool is_quickaction { get; set; }

  /////////////////////// public abstract methods //////////////////////////////

  // This one is called, when the user activates the item ----------------------
  public abstract void activate();

  //////////////////////////// public methods //////////////////////////////////

  // C'tor, initializes all members --------------------------------------------
  public Action(string name, string icon, bool is_quickaction) {
      GLib.Object(name : name, icon : icon, is_quickaction : is_quickaction);
  }
}

}
