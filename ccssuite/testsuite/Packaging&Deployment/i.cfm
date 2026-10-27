<!--- Packaging & Deployment test index --->
<cfoutput>
<h2>Packaging &amp; Deployment</h2>

<p>Packaging &amp; Deployment settings and archive definitions in ColdFusion are instance-local (Sync: NO for all). These tests verify that configuring or deploying an archive on the target node updates locally while peer cluster nodes appropriately do NOT replicate the archive definition, fulfilling the documented behavior.</p>

<h3>ColdFusion Archives (archives/index.cfm)</h3>
<ul>
	<li><a href="archives/archiveFileName.cfm">Deploy an Existing Archive</a> &mdash; <code>archiveFileName</code></li>
	<li><a href="archives/archiveName.cfm">Archive Name</a> &mdash; <code>archiveName</code> (create/delete CAR archive definition)</li>
</ul>

<h3>JEE Archives (j2eepackaging/index.cfm)</h3>
<ul>
	<li><a href="jeeArchives/archiveName.cfm">Archive Name</a> &mdash; <code>archivename</code> (create/delete JEE archive definition)</li>
	<li><a href="jeeArchives/applicationDir.cfm">Application Directory</a> &mdash; <code>application_dir</code></li>
	<li><a href="jeeArchives/distDir.cfm">Distribution Directory</a> &mdash; <code>distdir</code></li>
	<li><a href="jeeArchives/archiveType.cfm">Archive Type</a> &mdash; <code>archive_type</code> (WAR / EAR)</li>
	<li><a href="jeeArchives/contextRoot.cfm">Context Root</a> &mdash; <code>context_root</code> (valid for EAR)</li>
	<li><a href="jeeArchives/disableDebug.cfm">Disable Debugging</a> &mdash; <code>disable_debug</code></li>
	<li><a href="jeeArchives/srcLessDeploy.cfm">Include CFML Source</a> &mdash; <code>srclessdeploy</code></li>
	<li><a href="jeeArchives/includeAdmin.cfm">Include CF Administrator</a> &mdash; <code>includeadmin</code></li>
</ul>
</cfoutput>
