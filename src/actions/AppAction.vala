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
// This type of Action launches an application or a custom command.           //
////////////////////////////////////////////////////////////////////////////////

public class AppAction : Action {

  //////////////////////////////////////////////////////////////////////////////
  //                          public interface                                //
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////// public static methods ///////////////////////////////

  // Used to register this type of Action. It sets the display name
  // for this Action, whether it has a custom Icon/Name and the string
  // used in the pies.conf file for this kind of Actions.
  public static ActionRegistry.TypeDescription register() {
    var description = new ActionRegistry.TypeDescription();
    description.name = _("Launch application");
    description.icon = "application-x-executable";
    description.description = _("Executes the given command.");
    description.icon_name_editable = true;
    description.id = "app";
    return description;
  }

  //////////////////////////// public members //////////////////////////////////

  // Stores the command line.
  public override string real_command { get; construct set; }

  // Simply returns the real_command. No beautification.
  public override string display_command { get {return real_command;} }

  //////////////////////////// public methods //////////////////////////////////

  // C'tor, initializes all members. -------------------------------------------
  public AppAction(string name, string icon, string command, bool is_quickaction = false) {
    GLib.Object(name : name, icon : icon, real_command : command, is_quickaction : is_quickaction);
  }

  // Launches the desired command. ---------------------------------------------
  public override void activate() {
    try{
      var item = GLib.AppInfo.create_from_commandline(this.real_command, null, GLib.AppInfoCreateFlags.NONE);
      item.launch(null, null);
  	} catch (Error e) {
      warning(e.message);
    }
  }
}

}
