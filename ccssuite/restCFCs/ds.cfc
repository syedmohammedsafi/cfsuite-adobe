/**
*
* @file  /E/CFGronckleBuilds/fortunaNx/cfusion/wwwroot/cfsuite/ccssuite/testsuite/serverSettings/settings/settingDriver.cfc
* @author  pnayak, 25 may, 2024
* @description  REST service for setting and getting memeory variables
*/

component rest="true" restpath="ds" {

    remote struct function setSettings(required struct cookieSettings) 
								        restpath="dsp" 
								        httpMethod="POST" 
								    	consumes="application/JSON" 
								        produces="application/JSON"{
        
        response = {"a1":1}

       // cfdump(var="#serializeJSON(response)#", output="console")
        return  response;
    }

    remote struct function getSettings(required struct cookieSettings) 
								        restpath="dsg" 
								        httpMethod="GET" 
								        produces="application/JSON"{
        
        response = {"a1":1}

       // cfdump(var="#serializeJSON(response)#", output="console")
        return  response;
    }


       /*  
        USAGE: http://localhost:8500/rest/ccs/memvar/sessioncookieget 
        RESPONSE: {"error":true/false,"SessionCookieTimeout":"setvalue", "HttpOnlySessionCookie":"setvalue" ... }

    */
    remote struct function getSettings2() 
								        restpath="sessioncookieget" 
								        httpMethod="GET" 
								        produces="application/json"{
        
        response = {};
		
		try{
		    admin.login(application.constants.CF_CONFIG["CF_ADMIN_PASSWORD"]);

		    for(settingKey in cooKeyList){

	    		try{
		    		response[settingKey] = runtime.getRuntimeProperty(settingKey)
    			}
    			catch(any e){
    				cflog(type="error", application=true, file="#application.applicationname#", text="memory variables : get failed for setting: #settingKey#")
    				//response[settingKey] = "ERROR getting value"
    				cfheader(statuscode = 403);

    			}
		    }
		}
		catch(any e ){
			cfdump(var="#e#", output="console")
			cflog(type="error", application=true, file="#application.applicationname#", text="error in memory variables getter.")
			cfheader(statuscode = 402);
		}
		finally{
			admin.logout()
		}

		cfdump(var="#serializeJSON(response)#", output="console")
        return  response;
    }
}