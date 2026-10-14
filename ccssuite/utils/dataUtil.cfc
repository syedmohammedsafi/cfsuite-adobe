/**
*
* @file  /E/CFGronckleBuilds/fortunaNx/cfusion/wwwroot/cfsuite/ccssuite/util/dataUtil.cfc
* @author  
* @description
*
*/

component output="false" displayname=""  {

	public function init(){
		return this;
	}

	public any function invertBoolean(required any eVal){
		if(lcase(eVal) EQ "no")
			return "YES"
		if(lcase(eVal) EQ "yes")
			return "NO"

		return NOT(convertToBoolean(eVal))
	}


	public boolean function convertToBoolean(required any eVal){
	
		if(eVal.trim() NEQ "")
			if(lcase(eVal) EQ "yes")
				return true
			elif(lcase(eVal) EQ "no")
				return false

		throw (message="arg is an invalid boolean", type="invalid data type")
	}
}