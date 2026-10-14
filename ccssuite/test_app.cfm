<cftry>
	<cfscript>
		writeOutput("Testing Application.cfc...<br>");
		testDvr = new cfsuite.ccssuite.testDriver();
		writeOutput("testDriver created successfully.<br>");
	</cfscript>
	<cfcatch type="any">
		<cfoutput>
			<h3>ERROR:</h3>
			<p>Message: #cfcatch.message#</p>
			<p>Detail: #cfcatch.detail#</p>
			<p>StackTrace: #cfcatch.stackTrace#</p>
		</cfoutput>
	</cfcatch>
</cftry>
