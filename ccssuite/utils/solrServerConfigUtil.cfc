/**
* Read/write Solr Server settings directly in neo-solr.xml. There's no adminapi accessor for
* these fields — CFIDE.adminapi.collections.getSolrServer() returns a live connected
* org.apache.solr.client.solrj.SolrClient object (for querying Solr), not a config struct, and
* the generic CFIDE.adminapi.runtime property names ("SolrPort" etc.) aren't recognized.
*
* IMPORTANT: solrhost/solrport here are the connection this CF instance's own <cfcollection>
* calls use to reach Solr. Every CF instance on this box currently points at the same
* localhost:8997 Solr server (confirmed empirically), so those two fields are load-bearing for
* live collection functionality — don't use them for sync tests. solrbuffersize is a safe,
* non-connection-critical tuning knob.
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

	private string function getNeoSolrPath(){
		var constants = getConstants();
		return server.coldfusion.rootdir & constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & constants.SYS_CONFIG.FILE_SEPARATOR & "neo-solr.xml";
	}

	private string function getConfigLockName(required string configPath){
		return "ccs-neo-solr-" & hash(arguments.configPath);
	}

	private string function findStructKey(required struct data, required string key){
		for(var existingKey in arguments.data){
			if(compareNoCase(existingKey, arguments.key) EQ 0)
				return existingKey;
		}
		return arguments.key;
	}

	private struct function loadConfigMap(){
		var configPath = getNeoSolrPath();
		var lockName = getConfigLockName(configPath);
		var lastError = {};

		lock name="#lockName#" type="readonly" timeout="30" {
			for(var attempt = 1; attempt LTE 3; attempt++){
				try {
					var content = trim(fileRead(configPath));
					if(NOT len(content))
						return {};
					var cfg = {};
					cfwddx(action="WDDX2CFML", input=content, output="cfg");
					if(NOT isStruct(cfg))
						throw(message="invalid neo-solr.xml structure", type="CCSTest.ConfigError");
					return cfg;
				}
				catch(any e){
					lastError = e;
					if(attempt LT 3)
						sleep(50);
				}
			}
		}

		throw(message=lastError.message, detail=lastError.detail, type="CCSTest.ConfigError");
	}

	private void function saveConfigMap(required struct configMap){
		var configPath = getNeoSolrPath();
		var lockName = getConfigLockName(configPath);

		lock name="#lockName#" type="exclusive" timeout="30" {
			var wddx = "";
			cfwddx(action="CFML2WDDX", input=arguments.configMap, output="wddx");
			if(NOT findNoCase("<struct", wddx))
				throw(message="refusing to write corrupted neo-solr.xml", type="CCSTest.ConfigError");
			fileWrite(configPath, wddx);
		}
	}

	variables.SCALAR_FIELDS = "solrhost,solrhome,solrport,username,password,httpsenabled,solrhttpsport,solrwebapp,solrbuffersize";

	public string function getSolrServerSetting(required string settingName){
		if(listFindNoCase(variables.SCALAR_FIELDS, arguments.settingName))
			return getScalarSetting(arguments.settingName);
		return getLanguageSetting(arguments.settingName);
	}

	public string function setSolrServerSetting(required string settingName, required any settingValue){
		if(listFindNoCase(variables.SCALAR_FIELDS, arguments.settingName))
			return setScalarSetting(arguments.settingName, arguments.settingValue);
		return setLanguageSetting(arguments.settingName, arguments.settingValue);
	}

	private string function getScalarSetting(required string settingName){
		var cfg = loadConfigMap();
		var key = findStructKey(cfg, arguments.settingName);
		if(NOT structKeyExists(cfg, key))
			return "";
		return trim("" & cfg[key]);
	}

	private string function setScalarSetting(required string settingName, required any settingValue){
		var cfg = duplicate(loadConfigMap());
		var key = findStructKey(cfg, arguments.settingName);
		cfg[key] = isNumeric(arguments.settingValue) ? val(arguments.settingValue) : arguments.settingValue;
		saveConfigMap(cfg);
		return getScalarSetting(arguments.settingName);
	}

	/**
	* "Configure Indexing Languages" (New language / New language suffix / Add) manages entries
	* in the "languages" array, each a {suffix, name} struct — keyed here by suffix, the same
	* empty-then-populated pattern as an alias-keyed config (vectorstores, NoSQL datasources).
	*/
	private struct function findLanguageEntry(required array languages, required string suffix){
		for(var i = 1; i LTE arrayLen(arguments.languages); i++){
			if(structKeyExists(arguments.languages[i], "suffix") AND compareNoCase(trim("" & arguments.languages[i].suffix), arguments.suffix) EQ 0)
				return {index: i, entry: arguments.languages[i]};
		}
		return {};
	}

	public string function getLanguageSetting(required string suffix){
		var cfg = loadConfigMap();
		var langKey = findStructKey(cfg, "languages");
		if(NOT structKeyExists(cfg, langKey) OR NOT isArray(cfg[langKey]))
			return "";
		var found = findLanguageEntry(cfg[langKey], arguments.suffix);
		if(NOT structKeyExists(found, "entry"))
			return "";
		return trim("" & found.entry.name);
	}

	public string function setLanguageSetting(required string suffix, required any settingValue){
		var raw = trim("" & arguments.settingValue);
		var cfg = duplicate(loadConfigMap());
		var langKey = findStructKey(cfg, "languages");
		var languages = (structKeyExists(cfg, langKey) AND isArray(cfg[langKey])) ? cfg[langKey] : [];
		var found = findLanguageEntry(languages, arguments.suffix);

		if(NOT len(raw)){
			if(structKeyExists(found, "index"))
				arrayDeleteAt(languages, found.index);
		}
		else if(structKeyExists(found, "index")){
			languages[found.index].name = raw;
		}
		else {
			arrayAppend(languages, {"suffix": arguments.suffix, "name": raw});
		}

		cfg[langKey] = languages;
		saveConfigMap(cfg);
		return getLanguageSetting(arguments.suffix);
	}
}
