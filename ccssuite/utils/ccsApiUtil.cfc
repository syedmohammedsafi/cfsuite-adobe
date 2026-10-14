component {

	public function init(){
		return this;
	}

	private struct function getConstants(){
		if(isDefined("application") AND structKeyExists(application, "constants") AND isStruct(application.constants))
			return application.constants;
		if(NOT structKeyExists(request, "constants") OR NOT isStruct(request.constants))
			request.constants = new cfsuite.ccssuite.constants().init();
		return request.constants;
	}

	private void function ensureConstants(){
		getConstants();
	}

	public any function getSetting(required string settingName, required string apiArea, required string menuName){
		ensureConstants();
		switch(arguments.menuName){
			case "serverSettings":
				return new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().getSetting(arguments.settingName, arguments.apiArea);
			case "Debugging&Logging":
				return getDebuggingSetting(arguments.settingName, arguments.apiArea);
			case "AIservices":
				return getAiSetting(arguments.settingName, arguments.apiArea);
			case "PMT":
				return new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().getSetting(arguments.settingName, arguments.apiArea);
			case "Security":
				return getSecuritySetting(arguments.settingName, arguments.apiArea);
			case "extensions":
				return getExtensionsSetting(arguments.settingName, arguments.apiArea);
			case "eventGateways":
				return getEventGatewaysSetting(arguments.settingName, arguments.apiArea);
			case "DataServices":
				return getDataServicesSetting(arguments.settingName, arguments.apiArea);
			case "PackageManager":
                return new cfsuite.ccssuite.utils.packageManagerConfigUtil().init().getPackageManagerSetting(arguments.settingName);
			default:
				throw(message="Unknown menu name: #arguments.menuName#");
		}
	}

	public any function setSetting(required string settingName, required any settingValue, required string apiArea, required string menuName){
		ensureConstants();
		switch(arguments.menuName){
			case "serverSettings":
				return new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().setSetting(arguments.settingName, arguments.settingValue, arguments.apiArea);
			case "Debugging&Logging":
				return setDebuggingSetting(arguments.settingName, arguments.settingValue, arguments.apiArea);
			case "AIservices":
				return setAiSetting(arguments.settingName, arguments.settingValue, arguments.apiArea);
			case "PMT":
				return new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().setSetting(arguments.settingName, arguments.settingValue, arguments.apiArea);
			case "Security":
				return setSecuritySetting(arguments.settingName, arguments.settingValue, arguments.apiArea);
			case "extensions":
				return setExtensionsSetting(arguments.settingName, arguments.settingValue, arguments.apiArea);
			case "eventGateways":
				return setEventGatewaysSetting(arguments.settingName, arguments.settingValue, arguments.apiArea);
			case "DataServices":
				return setDataServicesSetting(arguments.settingName, arguments.settingValue, arguments.apiArea);
			case "PackageManager":
                return new cfsuite.ccssuite.utils.packageManagerConfigUtil().init().setPackageManagerSetting(arguments.settingName, arguments.settingValue);
			default:
				throw(message="Unknown menu name: #arguments.menuName#");
		}
	}

	// DATA & SERVICES
	private any function getDataServicesSetting(required string settingName, required string apiArea){
		switch(arguments.apiArea){
			case "datasources":
				return new cfsuite.ccssuite.utils.datasourceConfigUtil().init().getSetting(arguments.settingName);
			case "pdfServices":
				return new cfsuite.ccssuite.utils.pdfServiceConfigUtil().init().getSetting(arguments.settingName);
			case "nosql":
				return new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init().getSetting(arguments.settingName);
			case "nosqlDatasources":
				return new cfsuite.ccssuite.utils.nosqlDatasourceConfigUtil().init().getNoSQLSetting(arguments.settingName);
			case "coldfusionCollections":
				return new cfsuite.ccssuite.utils.coldfusionCollectionsConfigUtil().init().getCollectionSetting(arguments.settingName);
			case "solrServer":
				return new cfsuite.ccssuite.utils.solrServerConfigUtil().init().getSolrServerSetting(arguments.settingName);
			case "webServices":
				if(lCase(arguments.settingName) EQ "wsversion")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().getWSVersionSetting();
				if(lCase(arguments.settingName) EQ "ccstestwebservicename")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().getWebServiceNameSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestwebserviceauthtype")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().getWebServiceAuthTypeSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestwebservicetimeout")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().getWebServiceTimeoutSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestwebserviceproxyserver")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().getWebServiceProxyServerSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestwebserviceproxyport")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().getWebServiceProxyPortSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestwebserviceproxyusername")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().getWebServiceProxyUsernameSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestwebserviceproxypassword")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().getWebServiceProxyPasswordSetting(arguments.settingName);
				return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().getWebServiceMappingSetting(arguments.settingName);
			case "restServices":
				if(lCase(arguments.settingName) EQ "ccstestrestservicehost")
					return new cfsuite.ccssuite.utils.restServicesConfigUtil().init().getRestServiceHostSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestrestservicemapping")
					return new cfsuite.ccssuite.utils.restServicesConfigUtil().init().getRestServiceMappingSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestrestserviceisdefault")
					return new cfsuite.ccssuite.utils.restServicesConfigUtil().init().getRestServiceIsDefaultSetting(arguments.settingName);
				return new cfsuite.ccssuite.utils.restServicesConfigUtil().init().getRestServiceRootPathSetting(arguments.settingName);
			case "cloudCredentials":
				if(lCase(arguments.settingName) EQ "ccstestcloudvendor")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().getCloudVendorSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudregion")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().getCloudRegionSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudaccesskey")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().getCloudAccessKeySetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudsecretkey")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().getCloudSecretKeySetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudsessiontoken")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().getCloudSessionTokenSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestazureconnectionstring")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().getAzureConnectionStringSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestgcpprojectid")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().getGcpProjectIdSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestgcpcredentialjsonfilepath")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().getGcpCredentialJsonFilepathSetting(arguments.settingName);
				return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().getCloudCredentialAliasSetting(arguments.settingName);
			case "cloudConfiguration":
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigservicename")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigServiceNameSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigapicallattempttimeout")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigApiCallAttemptTimeoutSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigapicalltimeout")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigApiCallTimeoutSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigpathstyleaccess")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigPathStyleAccessEnabledSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigacceleratemode")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigAccelerateModeEnabledSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigdualstack")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigDualStackEnabledSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigchecksumvalidation")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigChecksumValidationEnabledSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigchunkedencoding")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigChunkedEncodingEnabledSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigconnacqtimeout")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigConnectionAcquisitionTimeoutSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigconnmaxidle")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigConnectionMaxIdleTimeSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigconntimeout")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigConnectionTimeoutSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigconnttl")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigConnectionTimeToLiveSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigexpectcontinue")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigExpectContinueEnabledSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigmaxconnections")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigMaxConnectionsSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigsockettimeout")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigSocketTimeoutSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfignonproxyhosts")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigNonProxyHostsSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigntlmdomain")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigNtlmDomainSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigntlmworkstation")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigNtlmWorkstationSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigproxyusername")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigProxyUsernameSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigproxypassword")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigProxyPasswordSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigproxyendpoint")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigProxyEndpointSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfignumretries")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigNumRetriesSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigretryconditiontype")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigRetryConditionTypeSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigretryconditions")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigRetryConditionsSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigretrycondition1statuscodes")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigRetryCondition1StatusCodesSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigretrycondition2statuscodes")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigRetryCondition2StatusCodesSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigbackoffstrategytype")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigBackoffStrategyTypeSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigbackoffbasedelay")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigBackoffBaseDelaySetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigbackoffmaxbackofftime")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigBackoffMaxBackoffTimeSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigbackofffixeddelay")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigBackoffFixedDelaySetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigthrottlebackoffstrategytype")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigThrottleBackoffStrategyTypeSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigthrottlebackoffbasedelay")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigThrottleBackoffBaseDelaySetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigthrottlebackoffmaxbackofftime")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigThrottleBackoffMaxBackoffTimeSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigthrottlebackofffixeddelay")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigThrottleBackoffFixedDelaySetting(arguments.settingName);
				return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().getCloudConfigAliasSetting(arguments.settingName);
			case "graphql":
				if(lCase(arguments.settingName) EQ "ccstestgraphqlservicename")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().getGraphqlServiceNameSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestgraphqlrootpackage")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().getGraphqlRootPackageNameSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestgraphqlschemapath")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().getGraphqlSchemaPathSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestgraphqlschemapathenabled")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().getGraphqlSchemaPathEnabledSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestgraphqlserviceurl")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().getGraphqlServiceUrlSetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestgraphqlheaderkey")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().getGraphqlHeaderKeySetting(arguments.settingName);
				if(lCase(arguments.settingName) EQ "ccstestgraphqlheadervalue")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().getGraphqlHeaderValueSetting(arguments.settingName);
				return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().getGraphqlClientAliasSetting(arguments.settingName);
			default:
				throw(message="Unsupported Data & Services area: #arguments.apiArea#");
		}
	}

	private any function setDataServicesSetting(required string settingName, required any settingValue, required string apiArea){
		switch(arguments.apiArea){
			case "datasources":
				return new cfsuite.ccssuite.utils.datasourceConfigUtil().init().setSetting(arguments.settingName, arguments.settingValue);
			case "pdfServices":
				return new cfsuite.ccssuite.utils.pdfServiceConfigUtil().init().setSetting(arguments.settingName, arguments.settingValue);
			case "nosql":
				return new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init().setSetting(arguments.settingName, arguments.settingValue);
			case "nosqlDatasources":
				return new cfsuite.ccssuite.utils.nosqlDatasourceConfigUtil().init().setNoSQLSetting(arguments.settingName, arguments.settingValue);
			case "coldfusionCollections":
				return new cfsuite.ccssuite.utils.coldfusionCollectionsConfigUtil().init().setCollectionSetting(arguments.settingName, arguments.settingValue);
			case "solrServer":
				return new cfsuite.ccssuite.utils.solrServerConfigUtil().init().setSolrServerSetting(arguments.settingName, arguments.settingValue);
			case "webServices":
				if(lCase(arguments.settingName) EQ "wsversion")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().setWSVersionSetting(arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestwebservicename")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().setWebServiceNameSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestwebserviceauthtype")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().setWebServiceAuthTypeSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestwebservicetimeout")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().setWebServiceTimeoutSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestwebserviceproxyserver")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().setWebServiceProxyServerSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestwebserviceproxyport")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().setWebServiceProxyPortSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestwebserviceproxyusername")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().setWebServiceProxyUsernameSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestwebserviceproxypassword")
					return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().setWebServiceProxyPasswordSetting(arguments.settingName, arguments.settingValue);
				return new cfsuite.ccssuite.utils.webServicesConfigUtil().init().setWebServiceMappingSetting(arguments.settingName, arguments.settingValue);
			case "restServices":
				if(lCase(arguments.settingName) EQ "ccstestrestservicehost")
					return new cfsuite.ccssuite.utils.restServicesConfigUtil().init().setRestServiceHostSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestrestservicemapping")
					return new cfsuite.ccssuite.utils.restServicesConfigUtil().init().setRestServiceMappingSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestrestserviceisdefault")
					return new cfsuite.ccssuite.utils.restServicesConfigUtil().init().setRestServiceIsDefaultSetting(arguments.settingName, arguments.settingValue);
				return new cfsuite.ccssuite.utils.restServicesConfigUtil().init().setRestServiceRootPathSetting(arguments.settingName, arguments.settingValue);
			case "cloudCredentials":
				if(lCase(arguments.settingName) EQ "ccstestcloudvendor")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().setCloudVendorSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudregion")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().setCloudRegionSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudaccesskey")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().setCloudAccessKeySetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudsecretkey")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().setCloudSecretKeySetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudsessiontoken")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().setCloudSessionTokenSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestazureconnectionstring")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().setAzureConnectionStringSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestgcpprojectid")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().setGcpProjectIdSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestgcpcredentialjsonfilepath")
					return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().setGcpCredentialJsonFilepathSetting(arguments.settingName, arguments.settingValue);
				return new cfsuite.ccssuite.utils.cloudCredentialConfigUtil().init().setCloudCredentialAliasSetting(arguments.settingName, arguments.settingValue);
			case "cloudConfiguration":
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigservicename")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigServiceNameSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigapicallattempttimeout")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigApiCallAttemptTimeoutSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigapicalltimeout")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigApiCallTimeoutSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigpathstyleaccess")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigPathStyleAccessEnabledSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigacceleratemode")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigAccelerateModeEnabledSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigdualstack")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigDualStackEnabledSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigchecksumvalidation")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigChecksumValidationEnabledSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigchunkedencoding")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigChunkedEncodingEnabledSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigconnacqtimeout")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigConnectionAcquisitionTimeoutSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigconnmaxidle")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigConnectionMaxIdleTimeSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigconntimeout")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigConnectionTimeoutSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigconnttl")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigConnectionTimeToLiveSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigexpectcontinue")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigExpectContinueEnabledSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigmaxconnections")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigMaxConnectionsSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigsockettimeout")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigSocketTimeoutSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfignonproxyhosts")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigNonProxyHostsSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigntlmdomain")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigNtlmDomainSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigntlmworkstation")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigNtlmWorkstationSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigproxyusername")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigProxyUsernameSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigproxypassword")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigProxyPasswordSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigproxyendpoint")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigProxyEndpointSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfignumretries")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigNumRetriesSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigretryconditiontype")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigRetryConditionTypeSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigretryconditions")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigRetryConditionsSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigretrycondition1statuscodes")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigRetryCondition1StatusCodesSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigretrycondition2statuscodes")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigRetryCondition2StatusCodesSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigbackoffstrategytype")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigBackoffStrategyTypeSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigbackoffbasedelay")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigBackoffBaseDelaySetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigbackoffmaxbackofftime")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigBackoffMaxBackoffTimeSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigbackofffixeddelay")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigBackoffFixedDelaySetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigthrottlebackoffstrategytype")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigThrottleBackoffStrategyTypeSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigthrottlebackoffbasedelay")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigThrottleBackoffBaseDelaySetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigthrottlebackoffmaxbackofftime")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigThrottleBackoffMaxBackoffTimeSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestcloudconfigthrottlebackofffixeddelay")
					return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigThrottleBackoffFixedDelaySetting(arguments.settingName, arguments.settingValue);
				return new cfsuite.ccssuite.utils.cloudConfigConfigUtil().init().setCloudConfigAliasSetting(arguments.settingName, arguments.settingValue);
			case "graphql":
				if(lCase(arguments.settingName) EQ "ccstestgraphqlservicename")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().setGraphqlServiceNameSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestgraphqlrootpackage")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().setGraphqlRootPackageNameSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestgraphqlschemapath")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().setGraphqlSchemaPathSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestgraphqlschemapathenabled")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().setGraphqlSchemaPathEnabledSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestgraphqlserviceurl")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().setGraphqlServiceUrlSetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestgraphqlheaderkey")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().setGraphqlHeaderKeySetting(arguments.settingName, arguments.settingValue);
				if(lCase(arguments.settingName) EQ "ccstestgraphqlheadervalue")
					return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().setGraphqlHeaderValueSetting(arguments.settingName, arguments.settingValue);
				return new cfsuite.ccssuite.utils.graphqlConfigUtil().init().setGraphqlClientAliasSetting(arguments.settingName, arguments.settingValue);
			default:
				throw(message="Unsupported Data & Services area: #arguments.apiArea#");
		}
	}

	// DEBUGGING & LOGGING
	private any function getDebuggingSetting(required string settingName, required string apiArea){
		if(arguments.apiArea EQ "systemProbes")
			return new cfsuite.ccssuite.utils.systemProbesConfigUtil().init().getSetting(arguments.settingName);
		var debugUtil = new cfsuite.ccssuite.utils.debuggingConfigUtil().init();
		var logUtil = new cfsuite.ccssuite.utils.loggingConfigUtil().init();

		switch(arguments.settingName){
			case "LogSlowRequests":
				return logUtil.getLogSlowRequests() ? "YES" : "NO";
			case "LogRequestTimeLimit":
				return logUtil.getLogRequestTimeLimit();
			case "MaxArchives":
				return logUtil.getMaxArchives();
			case "MaxFileSize":
				return logUtil.getMaxFileSize();
			case "debuggingIpAddress":
				return debugUtil.getDebuggingIpAddress();
			case "ajax_enabled":
				return debugUtil.getAjaxDebuggingEnabled() ? "YES" : "NO";
			case "cfstat":
				return debugUtil.getCfstatEnabled() ? "YES" : "NO";
			case "cfstatHost":
				return debugUtil.getCfstatHost();
			case "cfconnectorport":
				return debugUtil.getConnectorPort();
			case "database":
				return debugUtil.getDatabaseActivityEnabled() ? "YES" : "NO";
			case "debug_template":
				return debugUtil.getDebugTemplate();
			case "exception":
				return debugUtil.getExceptionInfoEnabled() ? "YES" : "NO";
			case "flashformcompileerrors":
				return debugUtil.getFlashFormCompileErrorsEnabled() ? "YES" : "NO";
			case "general":
				return debugUtil.getGeneralDebugInfoEnabled() ? "YES" : "NO";
			case "cfmetrics.pullfreq":
				return debugUtil.getMetricsFrequency();
			case "cfmetrics":
				return debugUtil.getMetricsLoggingEnabled() ? "YES" : "NO";
			case "template":
				return debugUtil.getReportExecutionTimesEnabled() ? "YES" : "NO";
			case "enabled":
				return debugUtil.getRequestDebuggingEnabled() ? "YES" : "NO";
			case "robust_enabled":
				return debugUtil.getRobustExceptionEnabled() ? "YES" : "NO";
			case "template_highlight_minimum":
				return debugUtil.getTemplateHighlightMinimum();
			case "template_mode":
				return debugUtil.getTemplateMode();
			case "timer":
				return debugUtil.getTimerInfoEnabled() ? "YES" : "NO";
			case "trace":
				return debugUtil.getTracingInfoEnabled() ? "YES" : "NO";
			case "variables":
				return debugUtil.getVariablesEnabled() ? "YES" : "NO";
			case "variables_scopes":
				return debugUtil.getVariablesScopes();
			case "developerProfile":
				return debugUtil.getDeveloperProfileEnabled() ? "YES" : "NO";
			default:
				throw(message="Unsupported debugging setting: " & arguments.settingName);
		}
	}

	private any function setDebuggingSetting(required string settingName, required any settingValue, required string apiArea){
		if(arguments.apiArea EQ "systemProbes")
			return new cfsuite.ccssuite.utils.systemProbesConfigUtil().init().setSetting(arguments.settingName, arguments.settingValue);
		var debugUtil = new cfsuite.ccssuite.utils.debuggingConfigUtil().init();
		var logUtil = new cfsuite.ccssuite.utils.loggingConfigUtil().init();

		switch(arguments.settingName){
			case "LogSlowRequests":
				return logUtil.setLogSlowRequests(arguments.settingValue) ? "YES" : "NO";
			case "LogRequestTimeLimit":
				return logUtil.setLogRequestTimeLimit(val(arguments.settingValue));
			case "MaxArchives":
				return logUtil.setMaxArchives(val(arguments.settingValue));
			case "MaxFileSize":
				return logUtil.setMaxFileSize(val(arguments.settingValue));
			case "debuggingIpAddress":
				return debugUtil.setDebuggingIpAddress(arguments.settingValue);
			case "ajax_enabled":
				return debugUtil.setAjaxDebuggingEnabled(arguments.settingValue) ? "YES" : "NO";
			case "cfstat":
				return debugUtil.setCfstatEnabled(arguments.settingValue) ? "YES" : "NO";
			case "cfstatHost":
				return debugUtil.setCfstatHost(arguments.settingValue);
			case "cfconnectorport":
				return debugUtil.setConnectorPort(arguments.settingValue);
			case "database":
				return debugUtil.setDatabaseActivityEnabled(arguments.settingValue) ? "YES" : "NO";
			case "debug_template":
				return debugUtil.setDebugTemplate(arguments.settingValue);
			case "exception":
				return debugUtil.setExceptionInfoEnabled(arguments.settingValue) ? "YES" : "NO";
			case "flashformcompileerrors":
				return debugUtil.setFlashFormCompileErrorsEnabled(arguments.settingValue) ? "YES" : "NO";
			case "general":
				return debugUtil.setGeneralDebugInfoEnabled(arguments.settingValue) ? "YES" : "NO";
			case "cfmetrics.pullfreq":
				return debugUtil.setMetricsFrequency(val(arguments.settingValue));
			case "cfmetrics":
				return debugUtil.setMetricsLoggingEnabled(arguments.settingValue) ? "YES" : "NO";
			case "template":
				return debugUtil.setReportExecutionTimesEnabled(arguments.settingValue) ? "YES" : "NO";
			case "enabled":
				return debugUtil.setRequestDebuggingEnabled(arguments.settingValue) ? "YES" : "NO";
			case "robust_enabled":
				return debugUtil.setRobustExceptionEnabled(arguments.settingValue) ? "YES" : "NO";
			case "template_highlight_minimum":
				return debugUtil.setTemplateHighlightMinimum(val(arguments.settingValue));
			case "template_mode":
				return debugUtil.setTemplateMode(arguments.settingValue);
			case "timer":
				return debugUtil.setTimerInfoEnabled(arguments.settingValue) ? "YES" : "NO";
			case "trace":
				return debugUtil.setTracingInfoEnabled(arguments.settingValue) ? "YES" : "NO";
			case "variables":
				return debugUtil.setVariablesEnabled(arguments.settingValue) ? "YES" : "NO";
			case "variables_scopes":
				return debugUtil.setVariablesScopes(arguments.settingValue);
			case "developerProfile":
				return debugUtil.setDeveloperProfileEnabled(arguments.settingValue) ? "YES" : "NO";
			default:
				throw(message="Unsupported debugging setting: " & arguments.settingName);
		}
	}

	// AI SERVICES
	private any function getAiSetting(required string settingName, required string apiArea){
		switch(arguments.apiArea){
			case "embeddingModels":
				return new cfsuite.ccssuite.utils.embeddingConfigUtil().init().getEmbeddingSetting(arguments.settingName);
			case "LLMs":
				return new cfsuite.ccssuite.utils.llmConfigUtil().init().getLLMSetting(arguments.settingName);
			case "MCPservers":
				return new cfsuite.ccssuite.utils.mcpConfigUtil().init().getMCPSetting(arguments.settingName);
			case "vectorstores":
				return new cfsuite.ccssuite.utils.vectorstoreConfigUtil().init().getVectorStoreSetting(arguments.settingName);
			case "RAG":
				// RAG has no settings of its own; it consumes Vector Store configs, which are
				// now always read/written through the live VectorStoreService.
				return new cfsuite.ccssuite.utils.vectorstoreConfigUtil().init().getVectorStoreSetting(arguments.settingName);
			default:
				if(arguments.settingName == "mcpServers") {
					return new cfsuite.ccssuite.utils.mcpConfigUtil().init().getMCPSetting(arguments.settingName);
				} else if(findNoCase("embedding", arguments.settingName)) {
					return new cfsuite.ccssuite.utils.embeddingConfigUtil().init().getEmbeddingSetting(arguments.settingName);
				} else if(findNoCase("llm", arguments.settingName)) {
					return new cfsuite.ccssuite.utils.llmConfigUtil().init().getLLMSetting(arguments.settingName);
				} else {
					return new cfsuite.ccssuite.utils.vectorstoreConfigUtil().init().getVectorStoreSetting(arguments.settingName);
				}
		}
	}

	private any function setAiSetting(required string settingName, required any settingValue, required string apiArea){
		switch(arguments.apiArea){
			case "embeddingModels":
				return new cfsuite.ccssuite.utils.embeddingConfigUtil().init().setEmbeddingSetting(arguments.settingName, arguments.settingValue);
			case "LLMs":
				return new cfsuite.ccssuite.utils.llmConfigUtil().init().setLLMSetting(arguments.settingName, arguments.settingValue);
			case "MCPservers":
				new cfsuite.ccssuite.utils.mcpConfigUtil().init().setMCPSetting(arguments.settingName, arguments.settingValue);
				return arguments.settingValue;
			case "vectorstores":
				new cfsuite.ccssuite.utils.vectorstoreConfigUtil().init().setVectorStoreSetting(arguments.settingName, arguments.settingValue);
				return arguments.settingValue;
			case "RAG":
				// Writes go through the same Vector Store storage; RAG has no separate config.
				new cfsuite.ccssuite.utils.vectorstoreConfigUtil().init().setVectorStoreSetting(arguments.settingName, arguments.settingValue);
				return arguments.settingValue;
			default:
				if(arguments.settingName == "mcpServers") {
					new cfsuite.ccssuite.utils.mcpConfigUtil().init().setMCPSetting(arguments.settingName, arguments.settingValue);
				} else if(findNoCase("embedding", arguments.settingName)) {
					new cfsuite.ccssuite.utils.embeddingConfigUtil().init().setEmbeddingSetting(arguments.settingName, arguments.settingValue);
				} else if(findNoCase("llm", arguments.settingName)) {
					new cfsuite.ccssuite.utils.llmConfigUtil().init().setLLMSetting(arguments.settingName, arguments.settingValue);
				} else {
					new cfsuite.ccssuite.utils.vectorstoreConfigUtil().init().setVectorStoreSetting(arguments.settingName, arguments.settingValue);
				}
				return arguments.settingValue;
		}
	}

	// SECURITY
	private any function getSecuritySetting(required string settingName, required string apiArea){
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		var admin = adminUtil.createAdministrator();
		adminUtil.login(getConstants().CF_CONFIG);

		try {
			switch(arguments.apiArea){
				case "AllowIPaddress":
					return trim(getOrSetAllowedAdminIPList());
				case "administrator":
					return new cfsuite.ccssuite.utils.securityConfigUtil().init().getSecuritySetting(arguments.settingName, arguments.apiArea);
				case "rds":
					return new cfsuite.ccssuite.utils.securityConfigUtil().init().getSecuritySetting(arguments.settingName, arguments.apiArea);
				case "sandboxSecurity":
					return new cfsuite.ccssuite.utils.securityConfigUtil().init().getSecuritySetting(arguments.settingName, arguments.apiArea);
				case "IDPConfig":
					return new cfsuite.ccssuite.utils.idpConfigUtil().init().getIDPSetting(arguments.settingName);
				case "secureprofile":
					var security = createObject("component", "CFIDE.adminapi.security");
					return security.isSecureProfile() ? "YES" : "NO";
				case "spconfig":
					return new cfsuite.ccssuite.utils.spConfigUtil().init().getSPSetting(arguments.settingName);
				case "settings":
				default:
					if(arguments.settingName == "secureprofile") {
						var security = createObject("component", "CFIDE.adminapi.security");
						return security.isSecureProfile() ? "YES" : "NO";
					} else if(arguments.settingName == "TestIDPAlias") {
						return new cfsuite.ccssuite.utils.idpConfigUtil().init().getIDPSetting(arguments.settingName);
					} else if(arguments.settingName == "TestSPAlias") {
						return new cfsuite.ccssuite.utils.spConfigUtil().init().getSPSetting(arguments.settingName);
					} else if(arguments.settingName == "adminIPList") {
						return trim(getOrSetAllowedAdminIPList());
					} else {
						var security = createObject("component", "CFIDE.adminapi.security");
						if (arguments.settingName EQ "challengeStore" OR arguments.settingName EQ "challengeTtl" OR arguments.settingName EQ "datasource") {
							var config = security.getPasskeyConfig();
							return trim(config[arguments.settingName]);
						} else if (arguments.settingName EQ "clientCertAuthEnabled" OR arguments.settingName EQ "clientCertRootAdminEnabled" OR arguments.settingName EQ "clientCertUseCGI" OR arguments.settingName EQ "clientCertSubjectHeader" OR arguments.settingName EQ "clientCertMatchCriteria") {
							var config = security.getClientCertConfig();
							var keyName = "";
							if (arguments.settingName EQ "clientCertAuthEnabled") keyName = "enabled";
							else if (arguments.settingName EQ "clientCertRootAdminEnabled") keyName = "rootAdminEnabled";
							else if (arguments.settingName EQ "clientCertUseCGI") keyName = "useCGI";
							else if (arguments.settingName EQ "clientCertSubjectHeader") keyName = "subjectHeader";
							else if (arguments.settingName EQ "clientCertMatchCriteria") keyName = "matchCriteria";
							return trim(config[keyName]);
						} else {
							throw(message="Unsupported security setting: " & arguments.settingName);
						}
					}
			}
		}
		finally {
			adminUtil.logout(admin);
		}
	}

	private any function setSecuritySetting(required string settingName, required any settingValue, required string apiArea){
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		var admin = adminUtil.createAdministrator();
		adminUtil.login(getConstants().CF_CONFIG);

		try {
			switch(arguments.apiArea){
				case "AllowIPaddress":
					return trim(getOrSetAllowedAdminIPList(arguments.settingValue));
				case "administrator":
					return new cfsuite.ccssuite.utils.securityConfigUtil().init().setSecuritySetting(arguments.settingName, arguments.settingValue, arguments.apiArea);
				case "rds":
					return new cfsuite.ccssuite.utils.securityConfigUtil().init().setSecuritySetting(arguments.settingName, arguments.settingValue, arguments.apiArea);
				case "sandboxSecurity":
					return new cfsuite.ccssuite.utils.securityConfigUtil().init().setSecuritySetting(arguments.settingName, arguments.settingValue, arguments.apiArea);
				case "IDPConfig":
					new cfsuite.ccssuite.utils.idpConfigUtil().init().setIDPSetting(arguments.settingName, arguments.settingValue);
					return new cfsuite.ccssuite.utils.idpConfigUtil().init().getIDPSetting(arguments.settingName);
				case "secureprofile":
					var security = createObject("component", "CFIDE.adminapi.security");
					var valToSet = false;
					if (isBoolean(arguments.settingValue)) {
						valToSet = arguments.settingValue;
					} else if (arguments.settingValue EQ "YES" OR arguments.settingValue EQ "yes") {
						valToSet = true;
					}
					if (valToSet) {
						security.enableSecureProfile();
					} else {
						security.disableSecureProfile();
					}
					return security.isSecureProfile() ? "YES" : "NO";
				case "spconfig":
					new cfsuite.ccssuite.utils.spConfigUtil().init().setSPSetting(arguments.settingName, arguments.settingValue);
					return new cfsuite.ccssuite.utils.spConfigUtil().init().getSPSetting(arguments.settingName);
				case "settings":
				default:
					if(arguments.settingName == "secureprofile") {
						var security = createObject("component", "CFIDE.adminapi.security");
						var valToSet = false;
						if (isBoolean(arguments.settingValue)) {
							valToSet = arguments.settingValue;
						} else if (arguments.settingValue EQ "YES" OR arguments.settingValue EQ "yes") {
							valToSet = true;
						}
						if (valToSet) {
							security.enableSecureProfile();
						} else {
							security.disableSecureProfile();
						}
						return security.isSecureProfile() ? "YES" : "NO";
					} else if(arguments.settingName == "TestIDPAlias") {
						new cfsuite.ccssuite.utils.idpConfigUtil().init().setIDPSetting(arguments.settingName, arguments.settingValue);
						return new cfsuite.ccssuite.utils.idpConfigUtil().init().getIDPSetting(arguments.settingName);
					} else if(arguments.settingName == "TestSPAlias") {
						new cfsuite.ccssuite.utils.spConfigUtil().init().setSPSetting(arguments.settingName, arguments.settingValue);
						return new cfsuite.ccssuite.utils.spConfigUtil().init().getSPSetting(arguments.settingName);
					} else if(arguments.settingName == "adminIPList") {
						return trim(getOrSetAllowedAdminIPList(arguments.settingValue));
					} else {
						var security = createObject("component", "CFIDE.adminapi.security");
						if (arguments.settingName EQ "challengeStore" OR arguments.settingName EQ "challengeTtl" OR arguments.settingName EQ "datasource") {
							var config = security.getPasskeyConfig();
							config[arguments.settingName] = arguments.settingValue;
							security.setPasskeyConfig(config);
							var configNew = security.getPasskeyConfig();
							return trim(configNew[arguments.settingName]);
						} else if (arguments.settingName EQ "clientCertAuthEnabled" OR arguments.settingName EQ "clientCertRootAdminEnabled" OR arguments.settingName EQ "clientCertUseCGI" OR arguments.settingName EQ "clientCertSubjectHeader" OR arguments.settingName EQ "clientCertMatchCriteria") {
							var config = security.getClientCertConfig();
							var keyName = "";
							if (arguments.settingName EQ "clientCertAuthEnabled") keyName = "enabled";
							else if (arguments.settingName EQ "clientCertRootAdminEnabled") keyName = "rootAdminEnabled";
							else if (arguments.settingName EQ "clientCertUseCGI") keyName = "useCGI";
							else if (arguments.settingName EQ "clientCertSubjectHeader") keyName = "subjectHeader";
							else if (arguments.settingName EQ "clientCertMatchCriteria") keyName = "matchCriteria";

							var valToSet = arguments.settingValue;
							if (keyName EQ "enabled" OR keyName EQ "rootAdminEnabled" OR keyName EQ "useCGI") {
								valToSet = isBoolean(valToSet) ? javaCast("boolean", valToSet) : false;
							}
							config[keyName] = valToSet;

							if (keyName EQ "enabled") {
								if (valToSet EQ true) {
									if (NOT config.useCGI AND len(trim(config.subjectHeader)) EQ 0) {
										config.subjectHeader = "SSL_CLIENT_S_DN";
									}
								} else {
									if (config.subjectHeader EQ "SSL_CLIENT_S_DN") {
										config.subjectHeader = "";
									}
								}
							}

							security.setClientCertConfig(config);
							var configNew = security.getClientCertConfig();
							return trim(configNew[keyName]);
						} else {
							throw(message="Unsupported security setting: " & arguments.settingName);
						}
					}
			}
		}
		finally {
			adminUtil.logout(admin);
		}
	}

	private string function getOrSetAllowedAdminIPList(string valToSet = "") {
		var tempPath = server.coldfusion.rootdir & "/wwwroot/CFIDE/tempSetter.cfm";
		var tempContent = "<cfscript>" &
			"try {" &
			"	adminObj = createObject('component', 'CFIDE.adminapi.administrator');" &
			"	adminObj.login('password');" &
			"	serviceFactory = createObject('java', 'coldfusion.server.ServiceFactory');" &
			"	secService = serviceFactory.getSecurityService();" &
			"	if (isDefined('URL.setValueTo')) {" &
			"		val = URL.setValueTo;" &
			"		list = listToArray(val);" &
			"		if (arrayFindNoCase(list, '127.0.0.1') EQ 0) {" &
			"			arrayPrepend(list, '127.0.0.1');" &
			"		}" &
			"		if (arrayFindNoCase(list, '::1') EQ 0) {" &
			"			arrayAppend(list, '::1');" &
			"		}" &
			"		finalVal = arrayToList(list);" &
			"		secService.setAllowedAdminIPList(finalVal);" &
			"	}" &
			"	writeOutput('SUCCESS:' & secService.getAllowedAdminIPList());" &
			"} catch (any e) {" &
			"	writeOutput('ERROR:' & e.message & ' / ' & e.detail);" &
			"}" &
			"</cfscript>";
		
		fileWrite(tempPath, tempContent);
		
		var httpUrl = "http://localhost:8500/CFIDE/tempSetter.cfm";
		if (len(arguments.valToSet)) {
			httpUrl &= "?setValueTo=" & urlEncodedFormat(arguments.valToSet);
		}
		
		var httpService = new http();
		httpService.setUrl(httpUrl);
		httpService.setMethod("GET");
		httpService.setTimeout(10);
		var httpResult = httpService.send().getPrefix();
		
		// Clean up the temp file immediately
		try {
			fileDelete(tempPath);
		} catch (any e) {}
		
		var resultText = trim(httpResult.fileContent);
		if (left(resultText, 8) EQ "SUCCESS:") {
			return mid(resultText, 9, len(resultText) - 8);
		} else {
			throw(message="Failed to get/set allowed admin IP list: " & resultText);
		}
	}

	private any function getExtensionsSetting(required string settingName, required string apiArea){
		return new cfsuite.ccssuite.utils.extensionsConfigUtil().init().getExtensionsSetting(arguments.settingName);
	}

	private any function setExtensionsSetting(required string settingName, required any settingValue, required string apiArea){
		return new cfsuite.ccssuite.utils.extensionsConfigUtil().init().setExtensionsSetting(arguments.settingName, arguments.settingValue);
	}

	private any function getEventGatewaysSetting(required string settingName, required string apiArea){
		return new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init().getEventGatewaysSetting(arguments.settingName);
	}

	private any function setEventGatewaysSetting(required string settingName, required any settingValue, required string apiArea){
		return new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init().setEventGatewaysSetting(arguments.settingName, arguments.settingValue);
	}
}
