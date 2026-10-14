/**
* ColdFusion (Solr) Collections are normally physical, filesystem-backed indexes local to a
* single CF instance (cfusion/jetty/multicore/collections/<name>) — but in THIS environment,
* confirmed via direct testing (matching neo-solr.xml's solrhost/solrport on all three nodes,
* and netstat showing exactly one process listening on that port) that every instance is
* configured to talk to the SAME physical Solr server. A collection created via any instance is
* therefore visible from every instance in the same environment immediately — not because of any
* CCS replication, but because there's only one Solr behind all of them. runFullCollectionSyncTest
* uses nodesScope="all" and relies on buildAiVerificationRows' cross-cluster check (same pattern
* as mail) to keep a genuinely different-cluster/environment node from ever being reported as
* updated, even though — unlike CCS-replicated settings — that node might actually be hitting the
* same shared Solr too; the check simply refuses to report cross-cluster/environment nodes as
* changed regardless of what a live query would show.
*
* Term Highlighting is the one real per-collection boolean setting exposed by
* CFIDE.adminapi.collections (enableTermHighlighting/disableTermHighlighting/
* isTermHighlightingEnabled); create/delete use the built-in <cfcollection> tag directly,
* which needs no admin login. The adminapi CFC calls do require the same
* adminUtil.createAdministrator()/login() pattern used elsewhere (e.g. cacheConfigUtil.cfc).
*/
component output="false" {

	public function init(){
		return this;
	}

	private void function ensureConstants(){
		if(isDefined("application") AND NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		if(NOT structKeyExists(request, "constants") OR NOT isStruct(request.constants))
			request.constants = new cfsuite.ccssuite.constants().init();
	}

	private struct function getConstants(){
		ensureConstants();
		if(isDefined("application") AND structKeyExists(application, "constants") AND isStruct(application.constants))
			return application.constants;
		return request.constants;
	}

	private struct function getRuntime(){
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		var admin = adminUtil.createAdministrator();
		adminUtil.login(getConstants().CF_CONFIG);
		return {
			admin = admin,
			adminUtil = adminUtil,
			api = createObject("component", "CFIDE.adminapi.collections")
		};
	}

	public boolean function collectionExists(required string collectionName){
		var collList = "";
		cfcollection(action="list", name="collList");
		for(var row in collList){
			if(compareNoCase(trim(row.NAME), arguments.collectionName) EQ 0)
				return true;
		}
		return false;
	}

	public void function createCollectionIfMissing(required string collectionName){
		if(collectionExists(arguments.collectionName))
			return;
		cfcollection(action="create", collection=arguments.collectionName, language="English");
	}

	public void function deleteCollection(required string collectionName){
		try {
			cfcollection(action="delete", collection=arguments.collectionName);
		}
		catch(any e){
			// already absent - nothing to delete
		}
		// cfcollection delete unregisters the Solr core but leaves the now-empty
		// collection directory on disk; remove it so repeated test runs don't accumulate cruft.
		try {
			var leftoverDir = getSolrHome() & "\collections\" & arguments.collectionName;
			if(directoryExists(leftoverDir))
				directoryDelete(leftoverDir, true);
		}
		catch(any e2){
			// best-effort cleanup only
		}
	}

	private string function getSolrHome(){
		var constants = getConstants();
		var neoSolrPath = server.coldfusion.rootdir & constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & constants.SYS_CONFIG.FILE_SEPARATOR & "neo-solr.xml";
		var content = trim(fileRead(neoSolrPath));
		var cfg = {};
		cfwddx(action="WDDX2CFML", input=content, output="cfg");
		return cfg.solrhome;
	}

	private string function getTermHighlightingSetting(required string collectionName){
		if(NOT collectionExists(arguments.collectionName))
			return "";
		var runtime = getRuntime();
		try {
			return runtime.api.isTermHighlightingEnabled(arguments.collectionName) ? "true" : "false";
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	private void function setTermHighlighting(required string collectionName, required boolean enable){
		var runtime = getRuntime();
		try {
			if(arguments.enable)
				runtime.api.enableTermHighlighting(arguments.collectionName);
			else
				runtime.api.disableTermHighlighting(arguments.collectionName);
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public struct function sortStructKeys(required struct data){
		return new cfsuite.ccssuite.utils.llmConfigUtil().init().sortStructKeys(arguments.data);
	}

	public struct function decodeConfigValue(required any settingValue){
		var raw = trim("" & arguments.settingValue);
		if(NOT len(raw))
			return {};

		try {
			if(reFind("^[A-Za-z0-9+/=\r\n]+$", raw) AND len(raw) MOD 4 EQ 0)
				raw = toString(toBinary(raw));
			var parsed = deserializeJSON(raw);
			return isStruct(parsed) ? parsed : {};
		}
		catch(any e){
			throw(message="Invalid collection config payload", detail=e.message, type="CCSTest.ConfigError");
		}
	}

	public string function encodeConfigValue(required struct config){
		return toBase64(serializeJSON(sortStructKeys(arguments.config)));
	}

	/**
	* The "config" for a collection is just its existence plus the one real per-collection
	* setting (Term Highlighting) — this is what makes an empty-alias-style sync test possible:
	* "" when the collection doesn't exist, a full struct once it's been created.
	*/
	public string function getCollectionSetting(required string collectionName){
		if(NOT collectionExists(arguments.collectionName))
			return "";
		return encodeConfigValue({
			"language": "English",
			"termHighlighting": getTermHighlightingSetting(arguments.collectionName) EQ "true"
		});
	}

	public string function setCollectionSetting(required string collectionName, required any settingValue){
		var raw = trim("" & arguments.settingValue);
		if(NOT len(raw)){
			deleteCollection(arguments.collectionName);
			return "";
		}

		var config = decodeConfigValue(arguments.settingValue);
		if(structIsEmpty(config)){
			deleteCollection(arguments.collectionName);
			return "";
		}

		createCollectionIfMissing(arguments.collectionName);
		setTermHighlighting(arguments.collectionName, structKeyExists(config, "termHighlighting") ? config.termHighlighting : false);
		return getCollectionSetting(arguments.collectionName);
	}

	private boolean function valuesEquivalent(required any left, required any right){
		if(isNumeric(arguments.left) AND isNumeric(arguments.right))
			return val(arguments.left) EQ val(arguments.right);
		if(
			(isBoolean(arguments.left) AND NOT isNumeric(arguments.left))
			OR (isBoolean(arguments.right) AND NOT isNumeric(arguments.right))
		)
			return (arguments.left ? true : false) EQ (arguments.right ? true : false);
		return trim("" & arguments.left) EQ trim("" & arguments.right);
	}

	private boolean function structValuesMatch(required struct expected, required struct actual){
		for(var key in arguments.expected){
			if(NOT structKeyExists(arguments.actual, key))
				continue;
			if(NOT valuesEquivalent(arguments.expected[key], arguments.actual[key]))
				return false;
		}
		return true;
	}

	public boolean function configsMatch(required any expectedValue, required any actualValue){
		var expected = decodeConfigValue(arguments.expectedValue);
		var actual = decodeConfigValue(arguments.actualValue);
		if(structIsEmpty(expected) AND structIsEmpty(actual))
			return true;
		return structValuesMatch(expected, actual);
	}

	public boolean function setMatches(
		required any presetValue,
		required any actualValue,
		required any requestedValue
	){
		return configsMatch(arguments.requestedValue, arguments.actualValue);
	}
}
