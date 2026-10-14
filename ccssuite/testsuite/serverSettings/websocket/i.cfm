<!--- WebSocket settings test index — all neo-websocket.xml options --->
<cfoutput>
<h2>WebSocket Settings Tests</h2>

<h3>Service &amp; server type</h3>
<ul>
	<li><a href="wsStartWebSocketService.cfm">Enable WebSocket Service (startWebSocketService)</a></li>
	<li><a href="wsEnableProxyPort.cfm">Use Proxy / Built-in (enableWebsocketOverProxyPort)</a></li>
</ul>

<h3>Ports &amp; SSL</h3>
<ul>
	<li><a href="wsStartListenerOnNormalPort.cfm">Port enabled (startListenerOnNormalPort)</a></li>
	<li><a href="wsPort.cfm">Port (port)</a></li>
	<li><a href="wsSslEnabled.cfm">SSL port enabled (sslEnabled)</a></li>
	<li><a href="wsSslPort.cfm">SSL port (sslport)</a></li>
</ul>

<h3>Keystore</h3>
<ul>
	<li><a href="wsKeystoreLocation.cfm">Keystore (keystoreLocation)</a></li>
</ul>

<h3>Data Size</h3>
<ul>
	<li><a href="wsMaxFrameSize.cfm">Max Data Size</a></li>
</ul>

<h3>Data &amp; Flash fallback</h3>
<ul>
	<li><a href="wsFlashFallBack.cfm">Start Flash Policy Server (flashFallBack)</a></li>
</ul>

<h3>Cluster &amp; logging</h3>
<ul>
	<li><a href="wsClustered.cfm">Enable WebSocket cluster (clustered)</a></li>
	<li><a href="wsMulticastPort.cfm">Multicast port (multicastPort)</a></li>
</ul>
</cfoutput>
