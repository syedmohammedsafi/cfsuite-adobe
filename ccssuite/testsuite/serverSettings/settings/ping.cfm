<cfcontent type="text/plain" reset=true><cfoutput>OK - template runs. port=#cgi.server_port# app=#(structKeyExists(application, "name") ? application.name : "none")#</cfoutput>
