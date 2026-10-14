<cfscript>
	_url = "http://localhost:8500/x.cfm"
		cfhttp(url="#_url#", method="get", result="getRes")
		//writeDump(cfhttp)
		writeDump(getRes)

		cfhttp(method="GET", charset="utf-8", url="https://www.google.com/", result="result") 
writeDump(result);

/*


		{
    cfhttpparam(name="q", type="url", value="cfml");
}


		if(cfhttp.responseCode EQ 200)
			writeOutput(cfhttp.fileContent
		else if(cfhttp.responseCode EQ 500)
			return "500 ERROR getting setting value"
		else 
			return cfhttp.statusCode


	application.testConstants.COMPOSITE_KEY_FIELD_SEPERATOR = "::"
	writeOutput(getURLFragFromNodeKey("n::8501::cfsu"))
	public string function getURLFragFromNodeKey(required string nkey){
		frags = ListToArray(nkey, application.testConstants.COMPOSITE_KEY_FIELD_SEPERATOR)
		if(frags.len() EQ 2)
			return frags[1] & ":" & frags[2]
		else if(frags.len() EQ 3)
			return frags[1] & ":" & frags[2] & "/" & frags[3]

		writeOutput("error parsing nodeKey: " & nkey)
		}
*/
</cfscript>
