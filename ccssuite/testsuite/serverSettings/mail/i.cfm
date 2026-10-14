<!--- Mail settings test index — covers all Administrator Mail tab options --->
<cfoutput>
	<h2>Mail Settings Tests</h2>

	<h3>SMTP / mail server</h3>
	<ul>
		<li><a href="mailServer.cfm">Mail Server (server)</a></li>
		<li><a href="mailUsername.cfm">User name (username)</a></li>
		<li><a href="mailPassword.cfm">Password (password)</a></li>
		<li><a href="mailPort.cfm">Server port (port)</a></li>
		<li><a href="mailVerifyServerConnection.cfm">Verify mail server connection (TestConnection; TCP reachability)</a></li>
		<li><a href="mailBackupMailServers.cfm">Backup Mail Servers (BackupMailServers)</a></li>
		<li><a href="mailSign.cfm">Sign the mail (sign)</a></li>
		<li><a href="mailKeystore.cfm">Keystore (keystore)</a></li>
		<li><a href="mailKeystorePassword.cfm">Keystore password (keystorepassword)</a></li>
		<li><a href="mailKeyAlias.cfm">Key alias (keyalias)</a></li>
		<li><a href="mailKeyPassword.cfm">Key password (keypassword)</a></li>
	</ul>

	<h3>Connection</h3>
	<ul>
		<li><a href="mailTimeout.cfm">Connection timeout (timeout)</a></li>
		<li><a href="mailUseSsl.cfm">Enable SSL (usessl)</a></li>
		<li><a href="mailUseTls.cfm">Enable TLS (usetls)</a></li>
		<li><a href="mailMaintainConnections.cfm">Maintain connection to mail server (MaintainConnections)</a></li>
		<li><a href="mailMaxDeliveryThreads.cfm">Mail Delivery Threads (MaxDeliveryThreads)</a></li>
	</ul>

	<h3>Mail spool</h3>
	<ul>
		<li><a href="mailSpoolInterval.cfm">Spool interval (schedule)</a></li>	
		<li><a href="mailSpoolEnable.cfm">Spool mail messages (spoolenable)</a></li>
		<li><a href="mailAllowDownload.cfm">Allow downloading the attachments for undelivered emails.</a></li>
		<li><a href="mailSpoolToMemory.cfm">Spool destination: disk or memory (SpoolToMemory)</a></li>
		<li><a href="mailMaxMessagesInMemory.cfm">Maximum number of messages spooled to memory (MaxMessagesInMemory)</a></li>
		<!--- <li><a href="mailSpoolDirectory.cfm">Spool directory (spooldir)</a></li> --->
		<!--- <li><a href="mailUndeliverDirectory.cfm">Undelivered mail directory (undeliverdir)</a></li> --->
	</ul>

	<h3>Logging &amp; charset</h3>
	<ul>
		<li><a href="mailErrorLogSeverity.cfm">Error log severity</a></li>
		<li><a href="mailSentLoggingEnable.cfm">Log all mail messages (mailsentloggingenable)</a></li>
		<li><a href="mailDefaultCharset.cfm">Default CFMail charset (defaultmailcharset)</a></li>
	</ul>
</cfoutput>