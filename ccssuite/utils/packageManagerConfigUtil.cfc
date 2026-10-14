/**
* Read/write CF Administrator "Package Manager > Settings" fields through the live
* coldfusion.server.UpdateService singleton (the same object CFIDE/administrator/updates/_settings.cfm
* uses), so tests exercise the real getter/setter path rather than editing neo_updates.xml directly.
* store() persists the in-memory change back to neo_updates.xml, which CCS syncs to peer nodes in the
* same cluster + environment (confirmed empirically — not on the same file list a static string dump of
* CentralConfigClientUtil.class would suggest).
*/
component output="false" {

	public function init(){
		return this;
	}

	private any function getUpdateService(){
		return createObject("java", "coldfusion.server.UpdateService").getInstance();
	}

	public any function getPackageManagerSetting(required string settingName){
		var svc = getUpdateService();
		switch(lCase(trim(arguments.settingName))){
			case "autocheck":
				return svc.isAutoCheck() ? "true" : "false";
			case "checkperiodically":
				return svc.isCheckPeriodically() ? "true" : "false";
			case "checkinterval":
				return trim("" & svc.getInterval());
			case "siteurl":
				return trim("" & svc.getUrl());
			case "packagessiteurl":
				return trim("" & svc.getPackagesurl());
			case "proxyhost":
				return trim("" & svc.getProxyHost());
			case "proxyport":
				return trim("" & svc.getProxyPort());
			case "proxyusername":
				return trim("" & svc.getProxyUsername());
			case "proxypassword":
				return trim("" & svc.getProxyPassword());
			case "notificationemails":
				return trim("" & svc.getEmails());
			case "notificationfromemail":
				return trim("" & svc.getFromEmail());
			default:
				throw(message="Unsupported Package Manager setting: " & arguments.settingName, type="CCSTest.ConfigError");
		}
	}

	public any function setPackageManagerSetting(required string settingName, required any settingValue){
		var svc = getUpdateService();
		switch(lCase(trim(arguments.settingName))){
			case "autocheck":
				svc.setAutoCheck(javaCast("boolean", isBooleanTrue(arguments.settingValue)));
				break;
			case "checkperiodically":
				svc.setCheckPeriodically(javaCast("boolean", isBooleanTrue(arguments.settingValue)));
				break;
			case "checkinterval":
				svc.setInterval(javaCast("int", val(arguments.settingValue)));
				break;
			case "siteurl":
				svc.setUrl(trim("" & arguments.settingValue));
				break;
			case "packagessiteurl":
				svc.setPackagesurl(trim("" & arguments.settingValue));
				break;
			case "proxyhost":
				svc.setProxyHost(trim("" & arguments.settingValue));
				break;
			case "proxyport":
				svc.setProxyPort(javaCast("int", val(arguments.settingValue)));
				break;
			case "proxyusername":
				svc.setProxyUsername(trim("" & arguments.settingValue));
				break;
			case "proxypassword":
				svc.setProxyPassword(trim("" & arguments.settingValue));
				break;
			case "notificationemails":
				svc.setEmails(trim("" & arguments.settingValue));
				break;
			case "notificationfromemail":
				svc.setFromEmail(trim("" & arguments.settingValue));
				break;
			default:
				throw(message="Unsupported Package Manager setting: " & arguments.settingName, type="CCSTest.ConfigError");
		}
		svc.store();
		return getPackageManagerSetting(arguments.settingName);
	}

	private boolean function isBooleanTrue(required any value){
		if(isBoolean(arguments.value))
			return arguments.value;
		return listFindNoCase("true,yes,1", lCase(trim("" & arguments.value))) GT 0;
	}

}
