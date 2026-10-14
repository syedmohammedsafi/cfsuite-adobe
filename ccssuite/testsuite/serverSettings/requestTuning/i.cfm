<!--- Request Tuning settings test index — all Administrator Request Tuning tab options --->
<cfoutput>
<h2>Request Tuning Settings Tests</h2>

<h3>Request Limits</h3>
<ul>
	<li><a href="requestLimit.cfm">Maximum number of simultaneous Template requests (requestLimit)</a></li>
	<li><a href="webServiceLimit.cfm">Maximum number of simultaneous Web Service requests (WebServiceLimit)</a></li>
	<li><a href="cfcLimit.cfm">Maximum number of simultaneous CFC function requests (CFCLimit)</a></li>
</ul>

<h3>Tag Limit Settings</h3>
<ul>
	<li><a href="reportThreads.cfm">Maximum number of simultaneous Report threads (ReportThreads)</a></li>
	<li><a href="cfThreadLimit.cfm">Maximum number of threads available for CFTHREAD (CFThreadLimit)</a></li>
</ul>

<h3>Queue Timeout Settings</h3>
<ul>
	<li><a href="requestQueueTimeout.cfm">Timeout requests waiting in queue after (RequestQueueTimeout)</a></li>
	<li><a href="requestQueueTimeoutPage.cfm">Request Queue Timeout Page (RequestQueueTimeoutPage)</a></li>
</ul>
</cfoutput>
