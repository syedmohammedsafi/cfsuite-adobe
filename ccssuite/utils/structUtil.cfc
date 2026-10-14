/**
*
* @file  /E/cfmain/ColdFusion/cfusion/wwwroot/azure/utils/structCompare.cfc
* @author  
* @description
*
*/

component output=true displayname=""  {


	public function init(){
		return this;
	}


	public boolean function structCompare(required struct s1, required struct s2){
		writeOutput("struct1: " & deSerializeStruct(s1) & "<br>")
		writeOutput("struct2: " & deSerializeStruct(s2) & "<br>")
		if(serializeJSON(s1) EQ serializeJSON(s2))
			return true

		return false
	}
	
    
    public string function flattenStruct(required struct structDataArg){

        strData = ""
        structData = StructToSorted(structDataArg, "text")
        for(key in structData)
            strData = strData & "[#key#:" & (isStruct(structData[key])?flattenStruct(structData[key]):structData[key]) & "]"

        return strData
    }
    

    string function deSerializeStruct(required struct _struct, string structStr = ""){

    	keyList = listSort(structKeyList(_struct), "TEXTNOCASE")
    	try{
			for(key in keyList){
				structStr = structStr & "[" & key 
				val = _struct[key]
				if(isStruct(val))
					val = deSerializeStruct(val, "")
				else if(isArray(val))
					val = arrayToList(val)
				else
					val = _struct[key]
		
				structStr = structStr & ":" & val & "]"
				//structStr = structStr & "; " & key & " : " & IIF(isStruct(_struct[key]), Evaluate(deSerializeStruct(_struct[key], "")), DE( _struct[key]))
			}
    	}
    	catch(any e){
    		writeOutput("error deSerializing passed struct.<br>")
    		writeDump(val)
    	}
		return structStr
	}


    string function deSerializeStructSimpleVals(required struct _struct, string structStr = ""){

    	keyList = structKeyList(_struct)
    	try{
			for(key in keyList){
				structStr = structStr &  key 
				val = _struct[key]
				if(isStruct(val) || isArray(val))
					continue
				else
					val = _struct[key]
		
				structStr = structStr & ":" & val & ";<br>"
				//structStr = structStr & "; " & key & " : " & IIF(isStruct(_struct[key]), Evaluate(deSerializeStruct(_struct[key], "")), DE( _struct[key]))
			}
    	}
    	catch(any e){
    		writeOutput("error deSerializing passed struct.<br>")
    		writeDump(val)
    	}
		return structStr
	}


    boolean function allKeysMatch(required struct struct1 ,required struct struct2){

    	if(structCount(struct1) != structCount(struct2)){
			writeOutput("keycount does not match. #structCount(struct1)# != #structCount(struct2)#<br>")
	   		return false
		}

		return allContainedKeysMatch(struct1, struct2)
    }


	boolean function allContainedKeysMatch(required struct struct1 ,required struct struct2){
    	_delim = ","
    	_keys = structKeyList(struct1, _delim)
    	for(key in _keys){
			writeoutput("processing key: #key#; value: #structFind(struct1,key)#...<br>")

    		if(isBoolean( structFind(struct1, key)) || isNumeric(structFind(struct1, key) )){
	    		if( struct1.find(key) != struct2.find(key)){
					writeOutput("boolean/num value do not match: <br>#structFind(struct1, key)#<br>#structFind(struct2, key)#<br>")
    				return false
				}
				continue
			}
    		else if( compareNoCase(structFind(struct1, key) , structFind(struct2, key))  != 0 ){
				writeOutput("string value do not match: <br>#structFind(struct1, key)#<br>#structFind(struct2, key)#<br>")
    			return false
			}
    	}
    	return true
	}
}