<cftry>
	<cfset t = new cfsuite.ccssuite.testDriver()>
	<cfoutput>testDriver OK<br></cfoutput>
	<cfcatch type="any">
		<cfoutput>testDriver ERR: #cfcatch.message# #cfcatch.detail#<br></cfoutput>
	</cfcatch>
</cftry>

<cftry>
	<cfset u = new cfsuite.ccssuite.utils.serverSettingsTestUtil()>
	<cfoutput>serverSettingsTestUtil OK<br></cfoutput>
	<cfcatch type="any">
		<cfoutput>serverSettingsTestUtil ERR: #cfcatch.message# #cfcatch.detail#<br></cfoutput>
	</cfcatch>
</cftry>
