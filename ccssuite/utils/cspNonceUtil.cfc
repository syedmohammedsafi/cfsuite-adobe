/**
* Read/write enableCspNonceForScript in neo-runtime.xml.
*/
component output="false" {

	variables.VAR_NAME = "enableCspNonceForScript";

	public function init(){
		return this;
	}

	private void function ensureConstants(){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
	}

	private string function getNeoRuntimePath(){
		ensureConstants();
		return server.coldfusion.rootdir & application.constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & application.constants.SYS_CONFIG.FILE_SEPARATOR & "neo-runtime.xml";
	}

	private string function getConfigLockName(required string configPath){
		return "ccs-neo-runtime-" & hash(arguments.configPath);
	}

	private numeric function findVarMarker(required string content, required string varName){
		var markerPos = findNoCase("name='" & arguments.varName & "'", arguments.content);
		if(NOT markerPos)
			throw(message="#arguments.varName# not found in neo-runtime.xml", type="CCSTest.ConfigError");
		return markerPos;
	}

	private array function findBooleanValueBounds(required string content, required numeric fromPos){
		var openTag = findNoCase("<boolean value='", arguments.content, arguments.fromPos);
		var valStart = openTag + len("<boolean value='");
		var quotePos = find("'", arguments.content, valStart);
		if(NOT openTag OR NOT quotePos)
			throw(message="boolean tag not found in neo-runtime.xml", type="CCSTest.ConfigError");
		return [valStart, quotePos];
	}

	private boolean function parseBooleanText(required string text){
		return listFindNoCase("true,yes,1", lCase(trim(arguments.text))) GT 0;
	}

	private string function formatBooleanText(required boolean value){
		return arguments.value ? "true" : "false";
	}

	public boolean function getCspNonceEnabled(){
		var path = getNeoRuntimePath();
		var lockName = getConfigLockName(path);
		lock name="#lockName#" type="readonly" timeout="30" {
			var content = fileRead(path);
			var boolBounds = findBooleanValueBounds(content, findVarMarker(content, variables.VAR_NAME));
			return parseBooleanText(mid(content, boolBounds[1], boolBounds[2] - boolBounds[1]));
		}
	}

	public boolean function setCspNonceEnabled(required any settingValue){
		var path = getNeoRuntimePath();
		var lockName = getConfigLockName(path);
		var boolValue = formatBooleanText(parseBooleanText(arguments.settingValue));
		lock name="#lockName#" type="exclusive" timeout="30" {
			var content = fileRead(path);
			var updated = content;
			var markerPos = findNoCase("name='" & variables.VAR_NAME & "'", updated);
			while(markerPos GT 0){
				var boolBounds = findBooleanValueBounds(updated, markerPos);
				updated = left(updated, boolBounds[1] - 1) & boolValue &
					mid(updated, boolBounds[2], len(updated) - boolBounds[2] + 1);
				markerPos = findNoCase("name='" & variables.VAR_NAME & "'", updated, boolBounds[2] + 1);
			}
			if(NOT findNoCase("name='" & variables.VAR_NAME & "'", updated))
				throw(message="refusing to write corrupted neo-runtime.xml", type="CCSTest.ConfigError");
			fileWrite(path, updated);
		}
		return getCspNonceEnabled();
	}

}
