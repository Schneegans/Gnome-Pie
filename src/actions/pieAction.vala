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

// This Action opens another pie.

public class PieAction : Action {

    // the name of this group, as displayed in the gui
    public static string get_name() {
        return _("Open Pie");
    }
    
    public override string name {
        get {
            var referee = PieManager.get_pie(pie_id);
            if (referee != null)
                return referee.name;
            return "";
        }
        protected set {}
    }
    
    public override string icon_name {
        get {
            var referee = PieManager.get_pie(pie_id);
            if (referee != null)
                return referee.icon_name;
            return "";
        }
        protected set {}
    }
    	
    public string pie_id { get; set; }

    public PieAction(string id) {
        base("", "");
        this.pie_id = id;
    }

    public override void activate() {
        PieManager.open_pie(pie_id);
    } 
}

}
