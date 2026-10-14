<cfset srvInst = createObject("component", "CFIDE.adminapi.serverinstance")>
<cfset meta = getMetadata(srvInst)>
<cfcontent type="application/json">
<cfoutput>#serializeJSON(meta)#</cfoutput>
