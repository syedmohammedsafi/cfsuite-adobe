/**
* Read/write the Charting "Disk cache location" (CACHEPATH) directly from neo-graphing.xml.
* CFIDE.adminapi.runtime.setChartProperty("CachePath", ...) silently no-ops for every value
* tried (get works, set doesn't take effect), so this bypasses the Admin API for writes.
*/
component output="false" {

	public function init(){
		return this;
	}

	private string function getNeoGraphingPath(){
		return server.coldfusion.rootdir & "\lib\neo-graphing.xml";
	}

	private array function readConfigArray(){
		var content = fileRead(getNeoGraphingPath());
		var cfmlData = "";
		cfwddx(action="WDDX2CFML", input=content, output="cfmlData");
		if(NOT isArray(cfmlData) OR arrayLen(cfmlData) LT 1 OR NOT isStruct(cfmlData[1]))
			throw(message="neo-graphing.xml format is invalid", type="CCSTest.ConfigError");
		return cfmlData;
	}

	private void function writeConfigArray(required array configArray){
		var wddxOut = "";
		cfwddx(action="CFML2WDDX", input=arguments.configArray, output="wddxOut");
		fileWrite(getNeoGraphingPath(), wddxOut);
	}

	public string function getCachePath(){
		var configArray = readConfigArray();
		var config = configArray[1];
		return structKeyExists(config, "CACHEPATH") ? trim("" & config["CACHEPATH"]) : "";
	}

	public string function setCachePath(required string path){
		var configArray = readConfigArray();
		configArray[1]["CACHEPATH"] = arguments.path;
		writeConfigArray(configArray);
		return getCachePath();
	}

}
