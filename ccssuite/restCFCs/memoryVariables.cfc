/**
*
* @file  /E/CFGronckleBuilds/fortunaNx/cfusion/wwwroot/cfsuite/ccssuite/testsuite/serverSettings/settings/settingDriver.cfc
* @author  pnayak, 25 may, 2024
* @description  REST service for setting and getting memeory variables
*/

component rest="true" restpath="memvar" implements="cfsuite.ccssuite.iTestDriver"{

	import CFIDE.adminapi.*;

	admin = new administrator();
	runtime = new runtime();

	/*
	final COOKIE_TIMEOUT = "SessionCookieTimeout"
	final HTTP_ONLY = "HttpOnlySessionCookie"
	final SECURE_SESSION = "SecureSessionCookie"
	final DISABLE_UPDATE = "CFInternalCookieDisableUpdate"
	final SAME_SITE = "SessionCookieSamesite"
	cooKeyList = [COOKIE_TIMEOUT, HTTP_ONLY, SECURE_SESSION, DISABLE_UPDATE, SAME_SITE]
	*/
	cooKeyList = [
		"SessionCookieTimeout",
		"HttpOnlySessionCookie",
		"SecureSessionCookie",
		"CFInternalCookieDisableUpdate",
		"SessionCookieSamesite"
	]
	

    /*  
        USAGE: http://localhost:8500/rest/ccs/memvar/sessioncookie 
        RESPONSE: {"error":true/false,"SessionCookieTimeout":"setvalue", "HttpOnlySessionCookie":"setvalue" ... }

    */
    remote struct function setSettings(required struct cookieSettings) 
								        restpath="sessioncookieset" 
								        httpMethod="POST" 
								    	consumes="application/JSON" 
								        produces="application/JSON"{
        
        response = {};
		cfdump(var=#arguments#, label="rest set args", output="console")
		try{
		    admin.login(application.constants.CF_CONFIG["CF_ADMIN_PASSWORD"]);

		    for(settingKey in cooKeyList){
		    	if(cookieSettings.keyExists(settingKey) AND cookieSettings.find(settingKey)){

		    		try{
			    		runtime.setRuntimeProperty(settingKey, cookieSettings[settingKey]);
			    		response[settingKey] = runtime.getRuntimeProperty(settingKey)
	    			}
	    			catch(any e){
	    				cflog(type="error", application=true, file="#application.applicationname#", text="memory variables : set failed for setting: #settingKey#")
	    				response[settingKey] = "ERROR setting value"
	    				//cfheader(statuscode = 403, statustext = "ERROR setting value for #settingKey#")
	    			}
		    	}
		    	else{
		    		response[settingKey] = "setting not passed. set SKIPPED"
		    	}
		    }
		}
		catch(any e ){
			writedump(e);
			cflog(type="error", application=true, file="#application.applicationname#", text="error in memory variables setter.")
			//response.error = true
			//cfheader( statuscode = 402, statustext = "unable to login to admin api")
		}
		finally{
			admin.logout()
		}

        //cfdump(var="#serializeJSON(response)#", output="console")
        return  serializeJSON(response);
    }



       /*  
        USAGE: http://localhost:8500/rest/ccs/memvar/sessioncookieget 
        RESPONSE: {"error":true/false,"SessionCookieTimeout":"setvalue", "HttpOnlySessionCookie":"setvalue" ... }

    */
    remote struct function getSettings() 
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