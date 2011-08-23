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

    public override string action_type { get {return _("Open Pie");} }
    public override string label { get {return name;} }
    public override string command { get {return pie_id;} }
    
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

    public PieAction(string id, bool is_quick_action = false) {
        base("", "", is_quick_action);
        this.pie_id = id;
    }

    public override void activate() {
        PieManager.open_pie(pie_id);
    } 
}

}
