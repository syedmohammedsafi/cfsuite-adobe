<!--- SSL Certificate settings test index — Existing-certificate fields only. --->
<cfoutput>
	<h2>SSL Certificate Settings Tests</h2>

	<h3>Use SSL Certificate: Existing</h3>
	<ul>
		<li><a href="useSslCertificate.cfm">Use SSL Certificate (UseSslCertificate) — synthetic, see below</a></li>
		<li><a href="certificateLocation.cfm">Certificate location (certificateNamePath)</a></li>
		<li><a href="certificatePassword.cfm">Password (certificatePassword)</a></li>
		<li><a href="certificateAlgorithm.cfm">Algorithm (certificateAlgorithm)</a></li>
	</ul>

	<h3>Https / Http</h3>
	<ul>
		<li><a href="sslHttpsEnabled.cfm">Https "Enable" (SslHttpsEnabled) — synthetic, see below</a></li>
		<li><a href="sslHttpEnabled.cfm">Http "Enable" (SslHttpEnabled) — synthetic, see below</a></li>
	</ul>

	<h3>Use SSL Certificate: Create</h3>
	<ul>
		<li><a href="distinguishedName.cfm">Distinguished Name (DistinguishedName) — synthetic, see below</a></li>
		<li><a href="certificateName.cfm">Certificate Name (CertificateName) — synthetic, see below</a></li>
	</ul>

	<p>
		Scope deliberately excludes: the Create radio's passwordValue field, and the actual generate
		action itself (generateKeyAndCertificate()/updateServerXml()) — same certificate-generation and
		live-connector risk as Https/Http below.
	</p>
	<p>
		certificateLocation/certificatePassword/certificateAlgorithm map to the
		&lt;Certificate certificateKeystoreFile="..." certificateKeystorePassword="..." type="..." /&gt;
		element inside the SSL Connector block in runtime/conf/server.xml — a block that ships
		commented out. Editing attribute text inside an XML comment is inert to the running Tomcat
		instance (its parser skips comments entirely), so these tests never uncomment the SSL
		connector and never touch the live port-8500 HTTP connector this admin session itself runs on.
	</p>
	<p>
		<strong>useSslCertificate.cfm, sslHttpsEnabled.cfm, sslHttpEnabled.cfm, distinguishedName.cfm
		and certificateName.cfm are synthetic tests</strong>, not real field round-trips:
	</p>
	<ul>
		<li>
			The Existing/Create radio has no persisted state anywhere in CF admin (it's a pure UI
			selector). useSslCertificate.cfm stands in for it as whether the &lt;Certificate .../&gt;
			element exists at all inside the still-commented &lt;SSLHostConfig&gt; block.
		</li>
		<li>
			The real Https/Http checkboxes control whether the live &lt;Connector&gt; blocks are
			commented or active. Enabling Https for real means uncommenting a connector whose
			keystore ("adminlocalhost") almost certainly isn't a real file — Tomcat commonly refuses
			to start at all with an invalid cert config, not just fail that one connector. Disabling
			Http for real means commenting out the port-8500 connector this admin session runs on —
			a self-lockout risk on the next restart. Neither takes effect without a restart, but the
			file would sit in that broken state for the test's duration, and any restart during that
			window turns it into a real outage. So instead, sslHttpsEnabled.cfm/sslHttpEnabled.cfm
			toggle a synthetic marker attribute on already-inert companion elements that are NEVER the
			live connectors: the commented SSL &lt;Connector&gt;'s own opening tag (for Https), and the
			separate, always-commented "shared thread pool" HTTP &lt;Connector&gt; template a few lines
			above it (for Http) — the one Tomcat never uses regardless of anything in this file.
		</li>
		<li>
			Distinguished Name and Certificate Name have no real persisted state at all — both only
			ever exist transiently in the Create form, consumed by generateKeyAndCertificate() to
			build a brand-new self-signed cert (the same generation risk as above).
			distinguishedName.cfm/certificateName.cfm each round-trip a plain string instead, via
			their own custom attribute (data-ccstest-distinguished-name /
			data-ccstest-certificate-name) added to the same already-inert commented
			&lt;Certificate .../&gt; tag the Existing fields use.
		</li>
	</ul>
	<p>
		All eight tests run with <code>nodesScope="all"</code> and push the new value to same-cluster/
		environment peers (<code>serverSettingsApiUtil.requiresPeerInstancePropagation()</code>
		returns true for the "sslcertificate" area, same mechanism as mail's keystore fields). A peer
		in a different cluster or environment is correctly left untouched — see
		testDriver.propagateDocumentSettingToPrimePeers -> getNodeKeysInPrimeEnvironment().
	</p>
</cfoutput>
