<cfsetting requesttimeout="30">
<cfscript>
	admin = createObject("component", "CFIDE.adminapi.administrator");
	loginOk = admin.login(adminPassword="password", adminUserId="admin");
	ext = createObject("component", "CFIDE.adminapi.extensions");
	md = getMetadata(ext);
	out = [];
	for(f in md.functions){
		if(f.name EQ "setWebService" OR f.name EQ "getWebServices" OR f.name EQ "deleteWebService" OR f.name EQ "reloadWebService"){
			var ps = [];
			for(p in f.parameters){
				arrayAppend(ps, p.name & ":" & (structKeyExists(p, "required") ? p.required : false) & ":" & (structKeyExists(p, "type") ? p.type : "any"));
			}
			arrayAppend(out, f.name & "(" & arrayToList(ps, ", ") & ")");
		}
	}
	writeOutput(arrayToList(out, "<br>"));
</cfscript>
