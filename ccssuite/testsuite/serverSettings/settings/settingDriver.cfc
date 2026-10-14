/**
*
* @file  /E/CFGronckleBuilds/fortunaNx/cfusion/wwwroot/cfsuite/ccssuite/testsuite/serverSettings/settings/settingDriver.cfc
* @author  
* @description
*
*/

component output="false" displayname=""  {

	import CFIDE.adminapi.*;
	admin = new administrator();
	runtime = new runtime();
	final SETTINGKEY = "TimeoutRequestTimeLimit"

	public function init(){
		return this;
	}

	public boolean function set(required string svalue){
		try{
		    admin.login(application.constants.CF_CONFIG["CF_ADMIN_PASSWORD"]);

	       	runtime.setRuntimeProperty(SETTINGKEY, svalue);
			writeOutput("TimeoutRequestTimeLimit set to: " & runtime.getRuntimeProperty(SETTINGKEY) & "<br>");
		}
		catch(any e ){
			writedump(e);
		}
		finally{
			admin.logout()
		}
	}

	public any function get(){
		setValue= ""
		try{
		    admin.login(application.constants.CF_CONFIG["CF_ADMIN_PASSWORD"]);

	       	setValue = runtime.getRuntimeProperty(SETTINGKEY);
			writeOutput("TimeoutRequestTimeLimit: " & setValue & "<br>");
		}
		catch(any e ){
			writedump(e);
		}
		finally{
			admin.logout()
		}
		
		return setValue
	}
}