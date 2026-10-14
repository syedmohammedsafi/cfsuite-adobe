<!--- Package Manager > Settings test index — covers all Administrator Package Manager Settings tab options --->
<cfoutput>
	<h2>Package Manager Settings Tests</h2>

	<h3>Auto-Check</h3>
	<ul>
		<li><a href="autoCheck.cfm">Automatically Check for Updates (autocheck)</a></li>
	</ul>

	<h3>Update Site</h3>
	<ul>
		<li><a href="siteUrl.cfm">Site URL (url)</a></li>
		<li><a href="packagesSiteUrl.cfm">Packages Site URL (packagesurl)</a></li>
	</ul>

	<h3>Notification</h3>
	<ul>
		<li><a href="checkPeriodically.cfm">Check for updates periodically (schedule_check)</a></li>
		<li><a href="checkInterval.cfm">Check for updates every N days (interval)</a></li>
		<li><a href="notificationEmails.cfm">Send notification to (email)</a></li>
		<li><a href="notificationFromEmail.cfm">Send notification from (fromemail)</a></li>
	</ul>

	<h3>Proxy Settings</h3>
	<ul>
		<li><a href="proxyHost.cfm">Proxy Host (proxyserver)</a></li>
		<li><a href="proxyPort.cfm">Proxy Port (proxyport)</a></li>
		<li><a href="proxyUsername.cfm">Proxy Username (proxyusername)</a></li>
		<li><a href="proxyPassword.cfm">Proxy Password (proxypassword)</a> <em>sensitive</em></li>
	</ul>
</cfoutput>
