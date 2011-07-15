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

    // this Action opens another pie
    public class PieAction : Action {
	    	
	    private string pie_name {private get; private set;}

	    public PieAction(string name, string icon_name, string pie_name) {
	        base(name, icon_name);
	        this.pie_name = pie_name;
	    }

	    public override void execute() {	    
	        var manager = new PieManager();
	        manager.open_pie(pie_name);
        } 
    }

}
