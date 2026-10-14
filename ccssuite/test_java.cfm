<cftry>
	<cfset ccs = createObject("java", "com.adobe.coldfusion.ccs.CCSManager")>
	<cfoutput>CCS Java API OK: #ccs.toString()#<br></cfoutput>
	<cfcatch type="any">
		<cfoutput>CCS Java API ERR: #cfcatch.message# #cfcatch.detail#<br></cfoutput>
	</cfcatch>
</cftry>
