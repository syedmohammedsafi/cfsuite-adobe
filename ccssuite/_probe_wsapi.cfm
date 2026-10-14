<cfscript>
	admin = createObject("component", "CFIDE.adminapi.administrator");
	loginOk = admin.login(adminPassword="password", adminUserId="admin");
	writeOutput("loginOk=[#loginOk#]<br>");
	ws = createObject("component", "CFIDE.adminapi.websocket");
	md = getMetadata(ws);
	writeOutput("functions:<br>");
	for(f in md.functions){
		writeOutput("#f.name#(#arrayToList(f.parameters.name,",")#)<br>");
	}
	admin.logout();
</cfscript>
