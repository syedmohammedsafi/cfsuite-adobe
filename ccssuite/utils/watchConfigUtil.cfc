/**
* Read/write watch.interval from neo-watch.xml (Check configuration files for changes every).
*/
component output="false" {

	public function init(){
		return this;
	}

	private void function ensureConstants(){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
	}

	public string function getNeoWatchPath(){
		ensureConstants();
		return server.coldfusion.rootdir & application.constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & application.constants.SYS_CONFIG.FILE_SEPARATOR & "neo-watch.xml";
	}

	private array function findWatchIntervalNumberBounds(required string content){
		var markerPos = findNoCase("watch.interval", arguments.content);
		if(NOT markerPos)
			throw(message="watch.interval not found in neo-watch.xml", type="CCSTest.ConfigError");
		var numOpen = findNoCase("<number>", arguments.content, markerPos);
		var numClose = findNoCase("</number>", arguments.content, numOpen);
		if(NOT numOpen OR NOT numClose)
			throw(message="watch.interval number tag not found in neo-watch.xml", type="CCSTest.ConfigError");
		return [numOpen, numClose];
	}

	public numeric function getWatchInterval(){
		var content = fileRead(getNeoWatchPath());
		var bounds = findWatchIntervalNumberBounds(content);
		var numOpen = bounds[1];
		var numClose = bounds[2];
		var valueText = mid(content, numOpen + len("<number>"), numClose - numOpen - len("<number>"));
		return val(trim(valueText));
	}

	public numeric function setWatchInterval(required numeric interval){
		if(arguments.interval LT 1)
			throw(message="watch.interval must be numeric and greater than or equal to 1", type="CCSTest.ConfigError");
		var path = getNeoWatchPath();
		var content = fileRead(path);
		var bounds = findWatchIntervalNumberBounds(content);
		var numOpen = bounds[1];
		var numClose = bounds[2];
		var valueLen = numClose - numOpen - len("<number>");
		if(valueLen LT 1 OR NOT findNoCase("watch.interval", content))
			throw(message="neo-watch.xml format is invalid; restore watch.interval before setting", type="CCSTest.ConfigError");
		var updated = left(content, numOpen + len("<number>") - 1) &
			arguments.interval &
			mid(content, numClose, len(content) - numClose + 1);
		if(NOT findNoCase("watch.interval", updated) OR NOT findNoCase("watch.extensions", updated))
			throw(message="refusing to write corrupted neo-watch.xml", type="CCSTest.ConfigError");
		fileWrite(path, updated);
		return getWatchInterval();
	}

	private array function findWatchEnabledValueBounds(required string content){
		var markerPos = findNoCase("watch.watchEnabled", arguments.content);
		if(NOT markerPos)
			throw(message="watch.watchEnabled not found in neo-watch.xml", type="CCSTest.ConfigError");
		var valueOpen = findNoCase("value='", arguments.content, markerPos);
		if(NOT valueOpen)
			throw(message="watch.watchEnabled boolean tag not found in neo-watch.xml", type="CCSTest.ConfigError");
		var valueStart = valueOpen + len("value='");
		var valueEnd = find("'", arguments.content, valueStart);
		if(NOT valueEnd)
			throw(message="watch.watchEnabled boolean tag not found in neo-watch.xml", type="CCSTest.ConfigError");
		return [valueStart, valueEnd];
	}

	public boolean function getWatchEnabled(){
		var content = fileRead(getNeoWatchPath());
		var bounds = findWatchEnabledValueBounds(content);
		var valueText = mid(content, bounds[1], bounds[2] - bounds[1]);
		return isBoolean(valueText) AND valueText;
	}

	public boolean function setWatchEnabled(required boolean enabled){
		var path = getNeoWatchPath();
		var content = fileRead(path);
		var bounds = findWatchEnabledValueBounds(content);
		var valueStart = bounds[1];
		var valueEnd = bounds[2];
		var updated = left(content, valueStart - 1) &
			(arguments.enabled ? "true" : "false") &
			mid(content, valueEnd, len(content) - valueEnd + 1);
		if(NOT findNoCase("watch.interval", updated) OR NOT findNoCase("watch.watchEnabled", updated))
			throw(message="refusing to write corrupted neo-watch.xml", type="CCSTest.ConfigError");
		fileWrite(path, updated);
		return getWatchEnabled();
	}

}
