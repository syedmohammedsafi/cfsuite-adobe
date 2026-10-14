
component rest="true" restpath="chart" implements="cfsuite.ccssuite.iTestDriver"{

	import CFIDE.adminapi.*;

	admin = new administrator();
	runtime = new runtime();
	
	constants = new cfsuite.ccssuite.utils.serverSettingsApiUtil().init()
	chartKeyList = constants.getChartingSettingKeyList()

	import CFIDE.adminapi.*;

	admin = new administrator();
	runtime = new runtime();
	
    remote struct function setSettings(required struct chartingSettings) 
								        restpath="chartingset" 
								        httpMethod="POST" 
								    	consumes="application/json"
								        produces="application/json"{
        
        response = {};
		cfdump(var=#arguments#, label="rest set args", output="console")
		try{
		    admin.login(application.constants.CF_CONFIG["CF_ADMIN_PASSWORD"]);
		    for(settingKey in chartKeyList){
		    	if(chartingSettings.keyExists(settingKey)){

		    		try{
			    		runtime.setChartProperty(settingKey, chartingSettings[settingKey]);
			    		response[settingKey] = runtime.getChartProperty(settingKey)
						writeoutput("testing the response here")
						writedump(response);
	    			}
	    			catch(any e){
	    				cflog(type="error", application=true, file="#application.applicationname#", text="memory variables : set failed for setting: #settingKey#")
	    				response[settingKey] = "ERROR setting value"
						writedump(e);
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
        //return  serializeJSON(response);
		return response;
    }
	
	 remote struct function getSettings() 
								        restpath="chartingget" 
								        httpMethod="GET" 
								        produces="application/json"{
        
        response = {};
		
		try{
		    admin.login(application.constants.CF_CONFIG["CF_ADMIN_PASSWORD"]);

		    for(settingKey in chartKeyList){

	    		try{
		    		response[settingKey] = runtime.getChartProperty(settingKey)
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