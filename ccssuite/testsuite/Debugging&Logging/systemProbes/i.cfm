<!--- System Probes test index — covers Debugging & Logging > System Probes admin page (scheduler/probes.cfm) --->
<cfoutput>
	<h2>System Probes Tests</h2>
	<p><a href="../i.cfm">&larr; Debugging &amp; Logging</a></p>

	<h3>Global Notification &amp; Probe Settings</h3>
	<ul>
		<li><a href="alarm_email.cfm">Notification email Recipients (alarm_email)</a></li>
		<li><a href="alarm_email_from.cfm">E-mail (alarm_email_from)</a></li>
		<li><a href="probecfm_url.cfm">Probe.cfm URL (probecfm_url)</a></li>
		<li><a href="probe_username.cfm">Probe.cfm User name (probe_username)</a></li>
		<li><a href="probe_password.cfm">Probe.cfm Password (probe_password)</a></li>
	</ul>

	<h3>Data List</h3>
	<ul>
		<li><a href="systemProbeList.cfm">System Probes List (Actions | Probe Name | Status | Interval | URL)</a></li>
	</ul>

	<h3>Add/Edit System Probe Properties</h3>
	<ul>
		<li><a href="taskName.cfm">Probe Name* (TaskName)</a></li>
		<li><a href="customInterval_hour.cfm">Hours (customInterval_hour)</a></li>
		<li><a href="customInterval_min.cfm">Minutes (customInterval_min)</a></li>
		<li><a href="customInterval_sec.cfm">Seconds (customInterval_sec)</a></li>
		<li><a href="customStartTime.cfm">Start Time (CustomStartTime)</a></li>
		<li><a href="customEndTime.cfm">End Time (CustomEndTime)</a></li>
		<li><a href="scheduledURL.cfm">URL* (ScheduledURL)</a></li>
		<li><a href="username.cfm">User Name (Username)</a></li>
		<li><a href="password.cfm">Password (Password)</a></li>
		<li><a href="request_time_out.cfm">Request Timeout (Request_Time_out)</a></li>
		<li><a href="proxy_server.cfm">Proxy Server (proxy_server)</a></li>
		<li><a href="http_proxy_port.cfm">Port (http_proxy_port)</a></li>
		<li><a href="matchCheck.cfm">Probe Failure (matchCheck)</a></li>
		<li><a href="trueMatch.cfm">Fail if the response (trueMatch)</a></li>
		<li><a href="matchType.cfm">the (matchType)</a></li>
		<li><a href="matchValue.cfm">Fail if the response the (matchValue)</a></li>
		<li><a href="send_email.cfm">Failure Actions (send_email)</a></li>
		<li><a href="executeCheck.cfm">Execute the program checkbox (executeCheck)</a></li>
		<li><a href="execute.cfm">Execute the program command (execute)</a></li>
		<li><a href="publish.cfm">Save output to a file (publish)</a></li>
		<li><a href="publish_file.cfm">File (publish_file)</a></li>
		<li><a href="publish_overwrite.cfm">Overwrite (publish_overwrite)</a></li>
		<li><a href="resolveURL.cfm">Resolve internal URLs (ResolveURL)</a></li>
		<li><a href="eventhandler.cfm">Event Handler (eventhandler)</a></li>
		<li><a href="exclude.cfm">Excluded Dates (exclude)</a></li>
		<li><a href="onmisfire.cfm">On Misfire (onmisfire)</a></li>
		<li><a href="onexception.cfm">On Exception (onexception)</a></li>
		<li><a href="oncomplete.cfm">On Complete (oncomplete)</a></li>
		<li><a href="scheduler_priority.cfm">Priority (scheduler_priority)</a></li>
		<li><a href="retrycount.cfm">Retry Count (retrycount)</a></li>
		<li><a href="cluster.cfm">Cluster Setup (cluster)</a></li>
	</ul>
</cfoutput>
