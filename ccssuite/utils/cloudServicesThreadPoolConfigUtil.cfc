/**
* Read/write the Cloud Services Thread Pool Configuration settings from neo-runtime.xml.
* CFIDE.adminapi.runtime does not expose corePoolSizeCloudServices/maxPoolSizeCloudServices/
* keepAliveTimeCloudServices generically (they are only reachable via the internal
* coldfusion.runtime.RuntimeServiceImpl Java API, which is blocked by the CF sandbox for
* non-admin CFML code), so these are read/written directly from their neo-runtime.xml <var> entries.
*/
component output="false" {

	public function init(){
		return this;
	}

	private void function ensureConstants(){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
	}

	public string function getNeoRuntimePath(){
		ensureConstants();
		return server.coldfusion.rootdir & application.constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & application.constants.SYS_CONFIG.FILE_SEPARATOR & "neo-runtime.xml";
	}

	private array function findNumberValueBounds(required string content, required string keyName){
		var markerPos = findNoCase("name='" & arguments.keyName & "'", arguments.content);
		if(NOT markerPos)
			throw(message="#arguments.keyName# not found in neo-runtime.xml", type="CCSTest.ConfigError");
		var numOpen = findNoCase("<number>", arguments.content, markerPos);
		var numClose = findNoCase("</number>", arguments.content, numOpen);
		if(NOT numOpen OR NOT numClose)
			throw(message="#arguments.keyName# number tag not found in neo-runtime.xml", type="CCSTest.ConfigError");
		return [numOpen, numClose];
	}

	public numeric function getCloudServicesPoolSetting(required string keyName){
		var content = fileRead(getNeoRuntimePath());
		var bounds = findNumberValueBounds(content, arguments.keyName);
		var valueText = mid(content, bounds[1] + len("<number>"), bounds[2] - bounds[1] - len("<number>"));
		return val(trim(valueText));
	}

	public numeric function setCloudServicesPoolSetting(required string keyName, required numeric value){
		if(arguments.value LT 1)
			throw(message="#arguments.keyName# must be numeric and greater than zero", type="CCSTest.ConfigError");
		var path = getNeoRuntimePath();
		var content = fileRead(path);
		var bounds = findNumberValueBounds(content, arguments.keyName);
		var numOpen = bounds[1];
		var numClose = bounds[2];
		var updated = left(content, numOpen + len("<number>") - 1) &
			arguments.value &
			mid(content, numClose, len(content) - numClose + 1);
		if(NOT findNoCase(arguments.keyName, updated))
			throw(message="refusing to write corrupted neo-runtime.xml", type="CCSTest.ConfigError");
		fileWrite(path, updated);
		return getCloudServicesPoolSetting(arguments.keyName);
	}

}
