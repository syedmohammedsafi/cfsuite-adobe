/**
* Read/write Performance Monitoring Toolset settings through the live
* coldfusion.monitor.Configuration singleton and coldfusion.server.MonitoringService
* (the same objects CFIDE/administrator/pms/index.cfm uses), rather than editing
* neo-monitoring.xml directly — MonitoringService.reload() is required for a hostname
* change to actually take effect and persist, and Configuration.INSTANCE always
* reflects the live value with no restart needed.
*/
component output="false" {

	public function init(){
		return this;
	}

	private any function getConfiguration(){
		return createObject("java", "coldfusion.monitor.Configuration").INSTANCE;
	}

	private any function getMonitoringService(){
		return createObject("java", "coldfusion.server.ServiceFactory").getMonitoringService(true);
	}

	public string function getMonitoringSetting(required string settingName){
		var config = getConfiguration();
		switch(lCase(trim(arguments.settingName))){
			case "hostname":
				return trim("" & config.getServerHostName());
			case "displayname":
				return trim("" & config.getDisplayName());
			case "instanceport":
				return trim("" & config.getInstancePort());
			case "httpsenabled":
				return config.isHttpsEnabled() ? "YES" : "NO";
			case "ismonitoringenabled":
				return config.isMonitoringEnabled() ? "YES" : "NO";
			case "uuid":
				return trim("" & config.getUuid());
			case "pmtdashboardurl":
				return trim("" & config.getPMTDashboardUrl());
			case "isdatastoreconnected":
				return isDatastoreConnected() ? "YES" : "NO";
			default:
				throw(message="Unsupported monitoring setting: " & arguments.settingName, type="CCSTest.ConfigError");
		}
	}

	private boolean function isDatastoreConnected(){
		try {
			return NOT isNull(getMonitoringService().getDatastoreClient());
		}
		catch(any e){
			return false;
		}
	}

	public string function setMonitoringSetting(required string settingName, required any settingValue){
		var config = getConfiguration();
		switch(lCase(trim(arguments.settingName))){
			case "hostname":
				getMonitoringService().reload(
					trim("" & arguments.settingValue),
					javaCast("int", val(config.getInstancePort())),
					"",
					trim("" & config.getPMTDashboardUrl()),
					config.isHttpsEnabled()
				);
				return getMonitoringSetting("hostname");
			default:
				throw(message="Unsupported monitoring setting: " & arguments.settingName, type="CCSTest.ConfigError");
		}
	}
}
