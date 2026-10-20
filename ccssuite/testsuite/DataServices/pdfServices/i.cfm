<!--- PDF Services test index — covers the Data & Services > PDF Services admin page --->
<cfoutput>
	<h2>PDF Services Tests</h2>
	<p><a href="../i.cfm">&larr; Data &amp; Services</a></p>
	<h3>PDF Service Settings</h3>
	<ul>
		<li><a href="name.cfm">Name (registration)</a></li>
		<li><a href="hostName.cfm">Host Name</a></li>
		<li><a href="port.cfm">Port</a></li>
		<li><a href="weight.cfm">Weight</a></li>
		<li><a href="httpsEnabled.cfm">HTTPS Enabled</a></li>
		<li><a href="engine.cfm">Engine</a></li>
	</ul>

	<h3>Data List</h3>
	<ul>
		<li><a href="pdfServiceList.cfm">PDF Service List</a></li>
	</ul>

	<h3>Service Operations (CCS Verification)</h3>
	<ul>
		<li><a href="createDeletePdfService.cfm">Create PDF Service</a> | <a href="createDeletePdfService.cfm?delete=1">Delete PDF Service</a></li>
	</ul>
</cfoutput>
