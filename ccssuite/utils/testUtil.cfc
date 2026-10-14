/**
*
* @file  /E/CFGronckleBuilds/fortunaNx/cfusion/wwwroot/cfsuite/ccssuite/util/testUtil.cfc
* @author  
* @description
*
*/

component output="false" displayname=""  {

	public function init(){
		return this;
	}

	public boolean function structCompare(required struct s1, required struct s2){
		if(serializeJSON(s1) EQ serializeJSON(s2))
			return true

		return false
	}

	public string function getURLFragFromNodeKey(required string nkey){
		frags = ListToArray(nkey, application.testConstants.TEST_FRAME.COMPOSITE_KEY_FIELD_SEPARATOR)
		if(frags.len() EQ 2)
			return frags[1] & ":" & frags[2]
		else if(frags.len() EQ 3)
			return frags[1] & ":" & frags[2] & "/" & frags[3]

		writeOutput("error parsing nodeKey: " & nkey)
	}
}