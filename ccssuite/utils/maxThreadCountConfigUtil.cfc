/**
* Read/write for MaxThreadCountForParallelCalls setting in neo-runtime.xml.
*/
component output="false" {

	public function init(){
		return this;
	}

	private string function getConfigPath(){
		return server.coldfusion.rootdir & "/lib/neo-runtime.xml";
	}

	private struct function readConfigStruct(){
		var data = {}; // Initialize as an empty struct
		var configPath = getConfigPath();
		if(fileExists(configPath)){
			try {
				var wddxData = "";
				var fileContent = fileRead(configPath);
				if(len(trim(fileContent))){
					cfwddx(action="WDDX2CFML", input=fileContent, output="wddxData");
					if(isArray(wddxData) AND arrayLen(wddxData) GTE 15 AND isStruct(wddxData[15])){
						return wddxData[15];
					} else if(isStruct(wddxData)){
						return wddxData;
					}
				}
			} catch(any e){
				// If WDDX conversion fails (e.g., malformed XML), data remains an empty struct
			}
		}
		return data;
	}

	private void function writeConfigStruct(required struct config){
		var wddxOut = "";
		var configPath = getConfigPath();
		var fullConfig = [];
		if(fileExists(configPath)){
			try {
				cfwddx(action="WDDX2CFML", input=fileRead(configPath), output="fullConfig");
			} catch(any e){
				// ignore if file is malformed, we will overwrite it
			}
		}
		if(isArray(fullConfig) AND arrayLen(fullConfig) GTE 15) {
			fullConfig[15] = arguments.config;
			cfwddx(action="CFML2WDDX", input=fullConfig, output="wddxOut");
			fileWrite(configPath, wddxOut);
		}
	}

	private string function getConfigKey(){
		return "MaxThreadCountForParallelCalls";
	}

	public numeric function getMaxThreadCountForParallelCalls(){
		var config = readConfigStruct();
		var key = getConfigKey();
		if(structKeyExists(config, key))
			return val(config[key]);
		return 0;
	}

	public numeric function setMaxThreadCountForParallelCalls(required numeric count){
		var config = {};
		var fullConfig = readConfigStruct();
		if(isStruct(fullConfig)) {
			config = fullConfig;
		}
		var key = getConfigKey();
		config[key] = arguments.count;
		writeConfigStruct(config);
		return getMaxThreadCountForParallelCalls();
	}

}