/**
*
* @file  /E/CFGronckleBuilds/fortunaNx/instance1/wwwroot/cfsuite/ccssuite/utils/restUtil.cfc
* @author  
* @description
*
*/

component output="true" displayname=""  {

	import CFIDE.adminapi.*;
	admin = new administrator();
	restSrvExt = new extensions();		
	
	final this.MAPPING_KEY = "MAPPING"
	final this.REST_INIT_CFM_PATH = "cfsuite/ccssuite/restCFCs/_initRest.cfm"

	public function init(){
		return this;
	}

	public boolean function registerRestService(required string path, 
													required string serviceMapping, 
													string host="localhost",
													boolean isDefault=false 
													){
		
		try{
			if(restMappingExists(serviceMapping))
				return false

			admin.login(application.constants.CF_CONFIG["CF_ADMIN_PASSWORD"])
			restSrvExt.registerRESTService(path, serviceMapping, host, isDefault)
			return true
		}
		catch(any e){
			writeDump(e)
		}
		finally{
			admin.logout()
		}
		return false
	}


	public boolean function restMappingExists(required string mapping){

		try{
			admin.login(application.constants.CF_CONFIG["CF_ADMIN_PASSWORD"])
			mapList = restSrvExt.getRESTServices()
			return mapListContains(mapList, mapping)

		}
		catch(any e){
			writeDump(e)
		}
		finally{
			admin.logout()
		}
	}


	private boolean function mapListContains(required array mapList, required string mapping){

		foundMap = false
		for(map in mapList){

			try{
				if(lcase(structFind(map, this.MAPPING_KEY)) EQ lcase(mapping) and NOT foundMap)
					foundMap = true
			}
			catch(any e){
				//swallow
			}
		}
		return foundMap
	}


	public array function getRestInitURLsList(required array hostNodePairsList){
		urlsList = []
		for(hostNodePair in hostNodePairsList)
			urlsList.append(application.protocol & "://" &  hostNodePair & "/" & this.REST_INIT_CFM_PATH)
		
		return urlsList
	}


	public boolean function initRestApp(required string _url){
		
		writeOutput("calling GET URL: " & _url & "<br>")
		
		try{
			cfhttp(url="#_url#", method="GET", result="response")
			//writeDump(response)
			if(response.statusCode EQ application.constants.CF_CONFIG["HTTP_STATUS_CODE_SUCCESS"])
				return true
			else if(response.statusCode EQ 500)
				writeOutput("#response.statusCode# ERROR calling rest init URL #_url#<br>")
		}
		catch(any e){
			writeOutput("ERROR calling URL: #_url#<br>")
			writeDump(e)
		}
		return false
	}
}