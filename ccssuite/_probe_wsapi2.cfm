<cfsetting requesttimeout="120">
<cftry>
<cfscript>
	admin = createObject("component", "CFIDE.adminapi.administrator");
	loginOk = admin.login(adminPassword="password", adminUserId="admin");
	ws = createObject("component", "CFIDE.adminapi.websocket");
	md = getMetadata(ws);
	result = "loginOk=[" & loginOk & "]";
	for(f in md.functions){
		result = result & " | #f.name#(";
		if(structKeyExists(f, "parameters")){
			for(p in f.parameters){ result = result & p.name & "=" & p.type & ";"; }
		}
		result = result & ")";
	}
	for(n in ["flashfallback","FlashFallback","flashFallback","startwebsocketservice"]){
		try { result = result & " | getProperty(#n#)=[" & ws.getProperty(n) & "]"; }
		catch(any e){ result = result & " | getProperty(#n#) ERR " & e.message; }
	}
	writeOutput(result);
</cfscript>
<cfcatch>
	writeOutput("PROBE ERROR: " & cfcatch.message & " :: " & cfcatch.detail);
</cfcatch>
</cftry>
