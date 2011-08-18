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
    	
    private string pie_id;

    public PieAction(string id) {
        base("", "");
        this.pie_id = id;
    }

    public override void activate() {
        Timeout.add((uint)(500.0*Config.global.theme.fade_out_time), () => {
            PieManager.open_pie(pie_id);
            return false;
        });	    
    } 
    
    public override void on_all_loaded() {
        var referee = PieManager.get_pie(pie_id);
        this.name = referee.name;
        this.icon_name = referee.icon_name;
    }
}

}
