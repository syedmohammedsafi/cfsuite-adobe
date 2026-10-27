/**
* Data & Services > Cloud Configuration admin page: "Add/Edit Cloud Service Configuration"
* (Config Alias).
*
* CFIDE.adminapi.cloud.addServiceConfig()/getServiceConfig()/deleteServiceConfig() reliably
* create/read/delete entries in neo-cloud-config.xml, keyed by alias (confirmed via direct
* testing). addServiceConfig() takes a single struct argument with only two real fields —
* confirmed via direct testing that "alias" and "serviceName" are the only accepted keys; the
* admin UI's "Cloud Vendor" dropdown is a client-side filter for which Service Name options are
* shown and is NOT itself a stored field (passing vendorName/vendor/cloudVendor is rejected as an
* unknown field).
*
* Multi-node via ORGANIC CCS replication, unlike Cloud Credentials: confirmed via direct testing
* that adding a config alias on the prime node creates a real CCS version
* (bin/ccsstore/.../<version>/neo-cloud-config.xml with an "ADDITION" changes.txt entry) and the
* new alias appears in a peer node's own neo-cloud-config.xml on disk shortly after, with no
* active push involved — the same passive-replication behavior mail's basic scalar fields (server,
* port, username) have, not the "CCS never tracks this file" situation Cloud Credentials is in.
* So this does NOT need requiresPeerInstancePropagation().
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
			api = createObject("component", "CFIDE.adminapi.cloud")
		};
	}

	/**
	* Fixed test config body used whenever the alias is (re-)created — the tracked value for this
	* test is the alias's presence/absence, not the Service Name field.
	*/
	private struct function buildTestConfig(required string alias){
		return {
			"alias" = arguments.alias,
			"serviceName" = "S3"
		};
	}

	public string function getCloudConfigAliasSetting(required string alias){
		var runtime = getRuntime();
		try {
			runtime.api.getServiceConfig(arguments.alias);
			return arguments.alias;
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigAliasSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteServiceConfig(arguments.alias);
				}
				catch(any e){
					if(NOT findNoCase("does not exist", e.message) AND NOT findNoCase("not found", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.addServiceConfig(buildTestConfig(arguments.alias));
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigAliasSetting(arguments.alias);
	}

	private void function deleteServiceConfigIfExists(required struct runtime, required string alias){
		try {
			arguments.runtime.api.deleteServiceConfig(arguments.alias);
		}
		catch(any e){
			if(NOT findNoCase("does not exist", e.message) AND NOT findNoCase("not found", e.message))
				rethrow;
		}
	}

	/**
	* "Service Name" field test: the tracked value is the serviceName string for a fixed, dedicated
	* test alias ("CCSTestCloudConfigServiceName" — kept separate from "CCSTestCloudConfigAlias" used
	* by the Config Alias test so the two tests never interfere with each other, the same convention
	* Cloud Credentials' field tests use). Cycles between two of AWS's real Service Name dropdown
	* options ("S3"/"SQS") rather than toggling presence/absence, since serviceName is a required
	* field with no blank state — each run either has no config (empty) or a freshly (re)created one
	* carrying the target service name, same delete-then-recreate pattern as Cloud Credentials' field
	* tests (addServiceConfig has no documented in-place update semantics exercised elsewhere in this
	* suite, so this follows the already-proven pattern instead of using modifyServiceConfig()).
	*/
	public string function getCloudConfigServiceNameSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			return structKeyExists(config, "serviceName") ? trim("" & config.serviceName) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigServiceNameSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({ "alias" = arguments.alias, "serviceName" = value });
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigServiceNameSetting(arguments.alias);
	}

	/**
	* "API Call Attempt Timeout" field test (AWS S3 advanced settings, Request Config section): the
	* tracked value is clientOverrideConfig.apiCallAttemptTimeout for a fixed, dedicated test alias
	* ("CCSTestCloudConfigApiCallAttemptTimeout" — kept separate from the other Cloud Configuration
	* test fixtures). Confirmed via direct testing that addServiceConfig() accepts a nested
	* clientOverrideConfig struct — {alias, serviceName, clientOverrideConfig:{apiCallAttemptTimeout}}
	* round-trips exactly (top-level keys apiCallAttemptTimeout/requestConfig/requestConfiguration
	* are all rejected as unknown fields; only the nested clientOverrideConfig.apiCallAttemptTimeout
	* path works). Cycles between two duration strings ("10s"/"20s") using the same
	* delete-then-recreate pattern as Service Name, since there's no blank-but-registered state.
	*/
	public string function getCloudConfigApiCallAttemptTimeoutSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			return structKeyExists(config.clientOverrideConfig, "apiCallAttemptTimeout") ? trim("" & config.clientOverrideConfig.apiCallAttemptTimeout) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigApiCallAttemptTimeoutSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = { "apiCallAttemptTimeout" = value }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigApiCallAttemptTimeoutSetting(arguments.alias);
	}

	/**
	* "API Call Timeout" field test (AWS S3 advanced settings, Request Config section): mirrors
	* API Call Attempt Timeout exactly, tracking clientOverrideConfig.apiCallTimeout instead —
	* confirmed via the same direct testing (nested clientOverrideConfig struct required; top-level
	* key rejected). Dedicated test alias "CCSTestCloudConfigApiCallTimeout" keeps this separate
	* from the other Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigApiCallTimeoutSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			return structKeyExists(config.clientOverrideConfig, "apiCallTimeout") ? trim("" & config.clientOverrideConfig.apiCallTimeout) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigApiCallTimeoutSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = { "apiCallTimeout" = value }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigApiCallTimeoutSetting(arguments.alias);
	}

	/**
	* "Path Style Access Enabled" field test (AWS S3 advanced settings, S3 specific section): the
	* tracked value is s3Configuration.pathStyleAccessEnabled for a fixed, dedicated test alias
	* ("CCSTestCloudConfigPathStyleAccess" — kept separate from the other Cloud Configuration test
	* fixtures). Confirmed via direct testing that addServiceConfig() requires a nested
	* s3Configuration struct (mirrors clientOverrideConfig's requirement for the timeout fields) and
	* stores the value as a real boolean, not a string.
	*/
	public string function getCloudConfigPathStyleAccessEnabledSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "s3Configuration") OR NOT isStruct(config.s3Configuration))
				return "";
			if(NOT structKeyExists(config.s3Configuration, "pathStyleAccessEnabled"))
				return "";
			// "" & true stringifies as "YES" not "true" — normalize explicitly so this matches the
			// "true"/"false" cycling value in serverSettingsTestUtil.cfc.
			return config.s3Configuration.pathStyleAccessEnabled ? "true" : "false";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigPathStyleAccessEnabledSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"s3Configuration" = { "pathStyleAccessEnabled" = (listFindNoCase("true,yes,1", value) GT 0) }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigPathStyleAccessEnabledSetting(arguments.alias);
	}

	/**
	* "Accelerate Mode Enabled" field test (AWS S3 advanced settings, S3 specific section): mirrors
	* Path Style Access Enabled exactly, tracking s3Configuration.accelerateModeEnabled instead.
	* Dedicated test alias "CCSTestCloudConfigAccelerateMode" keeps this separate from the other
	* Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigAccelerateModeEnabledSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "s3Configuration") OR NOT isStruct(config.s3Configuration))
				return "";
			if(NOT structKeyExists(config.s3Configuration, "accelerateModeEnabled"))
				return "";
			return config.s3Configuration.accelerateModeEnabled ? "true" : "false";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigAccelerateModeEnabledSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"s3Configuration" = { "accelerateModeEnabled" = (listFindNoCase("true,yes,1", value) GT 0) }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigAccelerateModeEnabledSetting(arguments.alias);
	}

	/**
	* "Dual Stack Enabled" field test (AWS S3 advanced settings, S3 specific section): mirrors
	* Accelerate Mode Enabled exactly, tracking s3Configuration.dualStackEnabled instead. Dedicated
	* test alias "CCSTestCloudConfigDualStack" keeps this separate from the other Cloud
	* Configuration test fixtures.
	*/
	public string function getCloudConfigDualStackEnabledSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "s3Configuration") OR NOT isStruct(config.s3Configuration))
				return "";
			if(NOT structKeyExists(config.s3Configuration, "dualStackEnabled"))
				return "";
			return config.s3Configuration.dualStackEnabled ? "true" : "false";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigDualStackEnabledSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"s3Configuration" = { "dualStackEnabled" = (listFindNoCase("true,yes,1", value) GT 0) }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigDualStackEnabledSetting(arguments.alias);
	}

	/**
	* "Checksum Validation Enabled" field test (AWS S3 advanced settings, S3 specific section):
	* mirrors Dual Stack Enabled exactly, tracking s3Configuration.checksumValidationEnabled
	* instead. Dedicated test alias "CCSTestCloudConfigChecksumValidation" keeps this separate from
	* the other Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigChecksumValidationEnabledSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "s3Configuration") OR NOT isStruct(config.s3Configuration))
				return "";
			if(NOT structKeyExists(config.s3Configuration, "checksumValidationEnabled"))
				return "";
			return config.s3Configuration.checksumValidationEnabled ? "true" : "false";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigChecksumValidationEnabledSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"s3Configuration" = { "checksumValidationEnabled" = (listFindNoCase("true,yes,1", value) GT 0) }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigChecksumValidationEnabledSetting(arguments.alias);
	}

	/**
	* "Chunked Encoding Enabled" field test (AWS S3 advanced settings, S3 specific section):
	* mirrors Checksum Validation Enabled exactly, tracking s3Configuration.chunkedEncodingEnabled
	* instead. Dedicated test alias "CCSTestCloudConfigChunkedEncoding" keeps this separate from
	* the other Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigChunkedEncodingEnabledSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "s3Configuration") OR NOT isStruct(config.s3Configuration))
				return "";
			if(NOT structKeyExists(config.s3Configuration, "chunkedEncodingEnabled"))
				return "";
			return config.s3Configuration.chunkedEncodingEnabled ? "true" : "false";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigChunkedEncodingEnabledSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"s3Configuration" = { "chunkedEncodingEnabled" = (listFindNoCase("true,yes,1", value) GT 0) }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigChunkedEncodingEnabledSetting(arguments.alias);
	}

	/**
	* "Connection Acquisition Timeout" field test (AWS S3 advanced settings, Client Config
	* section): the tracked value is httpClientConfig.connectionAcquisitionTimeout for a fixed,
	* dedicated test alias ("CCSTestCloudConfigConnAcqTimeout" — kept separate from the other Cloud
	* Configuration test fixtures). Same nested-struct pattern as clientOverrideConfig/
	* s3Configuration, different top-level key (httpClientConfig, Client Config section).
	*/
	public string function getCloudConfigConnectionAcquisitionTimeoutSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			return structKeyExists(config.httpClientConfig, "connectionAcquisitionTimeout") ? trim("" & config.httpClientConfig.connectionAcquisitionTimeout) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigConnectionAcquisitionTimeoutSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "connectionAcquisitionTimeout" = value }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigConnectionAcquisitionTimeoutSetting(arguments.alias);
	}

	/**
	* "Connection Max Idle Time" field test (AWS S3 advanced settings, Client Config section):
	* mirrors Connection Acquisition Timeout exactly, tracking
	* httpClientConfig.connectionMaxIdleTime instead. Dedicated test alias
	* "CCSTestCloudConfigConnMaxIdle" keeps this separate from the other Cloud Configuration test
	* fixtures.
	*/
	public string function getCloudConfigConnectionMaxIdleTimeSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			return structKeyExists(config.httpClientConfig, "connectionMaxIdleTime") ? trim("" & config.httpClientConfig.connectionMaxIdleTime) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigConnectionMaxIdleTimeSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "connectionMaxIdleTime" = value }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigConnectionMaxIdleTimeSetting(arguments.alias);
	}

	/**
	* "Connection Timeout" field test (AWS S3 advanced settings, Client Config section): mirrors
	* Connection Max Idle Time exactly, tracking httpClientConfig.connectionTimeout instead.
	* Dedicated test alias "CCSTestCloudConfigConnTimeout" keeps this separate from the other
	* Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigConnectionTimeoutSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			return structKeyExists(config.httpClientConfig, "connectionTimeout") ? trim("" & config.httpClientConfig.connectionTimeout) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigConnectionTimeoutSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "connectionTimeout" = value }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigConnectionTimeoutSetting(arguments.alias);
	}

	/**
	* "Connection Time to Live" field test (AWS S3 advanced settings, Client Config section):
	* mirrors Connection Timeout exactly, tracking httpClientConfig.connectionTimeToLive instead.
	* Dedicated test alias "CCSTestCloudConfigConnTTL" keeps this separate from the other Cloud
	* Configuration test fixtures.
	*/
	public string function getCloudConfigConnectionTimeToLiveSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			return structKeyExists(config.httpClientConfig, "connectionTimeToLive") ? trim("" & config.httpClientConfig.connectionTimeToLive) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigConnectionTimeToLiveSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "connectionTimeToLive" = value }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigConnectionTimeToLiveSetting(arguments.alias);
	}

	/**
	* "Expect continue enabled" field test (AWS S3 advanced settings, Client Config section): the
	* tracked value is httpClientConfig.expectContinueEnabled (real boolean) for a fixed, dedicated
	* test alias ("CCSTestCloudConfigExpectContinue" — kept separate from the other Cloud
	* Configuration test fixtures).
	*/
	public string function getCloudConfigExpectContinueEnabledSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			if(NOT structKeyExists(config.httpClientConfig, "expectContinueEnabled"))
				return "";
			return config.httpClientConfig.expectContinueEnabled ? "true" : "false";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigExpectContinueEnabledSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "expectContinueEnabled" = (listFindNoCase("true,yes,1", value) GT 0) }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigExpectContinueEnabledSetting(arguments.alias);
	}

	/**
	* "Max connections" field test (AWS S3 advanced settings, Client Config section): the tracked
	* value is httpClientConfig.maxConnections (numeric, not a duration string like the other
	* Client Config fields) for a fixed, dedicated test alias ("CCSTestCloudConfigMaxConnections"
	* — kept separate from the other Cloud Configuration test fixtures).
	*/
	public string function getCloudConfigMaxConnectionsSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			return structKeyExists(config.httpClientConfig, "maxConnections") ? trim("" & config.httpClientConfig.maxConnections) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigMaxConnectionsSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "maxConnections" = val(value) }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigMaxConnectionsSetting(arguments.alias);
	}

	/**
	* "Socket Timeout" field test (AWS S3 advanced settings, Client Config section): mirrors
	* Connection Timeout exactly, tracking httpClientConfig.socketTimeout instead. Dedicated test
	* alias "CCSTestCloudConfigSocketTimeout" keeps this separate from the other Cloud
	* Configuration test fixtures. Last of the Client Config section.
	*/
	public string function getCloudConfigSocketTimeoutSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			return structKeyExists(config.httpClientConfig, "socketTimeout") ? trim("" & config.httpClientConfig.socketTimeout) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigSocketTimeoutSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "socketTimeout" = value }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigSocketTimeoutSetting(arguments.alias);
	}

	/**
	* "Non proxy hosts" field test (AWS S3 advanced settings, Client Config - Proxy section): the
	* tracked value is httpClientConfig.proxyConfiguration.nonProxyHosts for a fixed, dedicated
	* test alias ("CCSTestCloudConfigNonProxyHosts" — kept separate from the other Cloud
	* Configuration test fixtures). Double-nested struct (Proxy Configuration nests under Client
	* Config) — confirmed via direct testing. nonProxyHosts is an ARRAY, not a string — passing a
	* plain string throws "Object of type class java.lang.String cannot be used as an array"; a
	* single-element array round-trips correctly.
	*/
	public string function getCloudConfigNonProxyHostsSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			if(NOT structKeyExists(config.httpClientConfig, "proxyConfiguration") OR NOT isStruct(config.httpClientConfig.proxyConfiguration))
				return "";
			var proxyConfig = config.httpClientConfig.proxyConfiguration;
			if(NOT structKeyExists(proxyConfig, "nonProxyHosts") OR NOT isArray(proxyConfig.nonProxyHosts) OR NOT arrayLen(proxyConfig.nonProxyHosts))
				return "";
			return trim("" & proxyConfig.nonProxyHosts[1]);
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigNonProxyHostsSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "proxyConfiguration" = { "nonProxyHosts" = [value] } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigNonProxyHostsSetting(arguments.alias);
	}

	/**
	* "Ntlm Domain" field test (AWS S3 advanced settings, Client Config - Proxy section): the
	* tracked value is httpClientConfig.proxyConfiguration.ntlmdomain (plain string, unlike
	* nonProxyHosts' array) for a fixed, dedicated test alias
	* ("CCSTestCloudConfigNtlmDomain" — kept separate from the other Cloud Configuration test
	* fixtures). Same double-nested struct as Non proxy hosts.
	*/
	public string function getCloudConfigNtlmDomainSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			if(NOT structKeyExists(config.httpClientConfig, "proxyConfiguration") OR NOT isStruct(config.httpClientConfig.proxyConfiguration))
				return "";
			var proxyConfig = config.httpClientConfig.proxyConfiguration;
			return structKeyExists(proxyConfig, "ntlmdomain") ? trim("" & proxyConfig.ntlmdomain) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigNtlmDomainSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "proxyConfiguration" = { "ntlmdomain" = value } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigNtlmDomainSetting(arguments.alias);
	}

	/**
	* "Ntlm Workstation" field test (AWS S3 advanced settings, Client Config - Proxy section):
	* mirrors Ntlm Domain exactly, tracking httpClientConfig.proxyConfiguration.ntlmWorkstation
	* instead. Dedicated test alias "CCSTestCloudConfigNtlmWorkstation" keeps this separate from
	* the other Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigNtlmWorkstationSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			if(NOT structKeyExists(config.httpClientConfig, "proxyConfiguration") OR NOT isStruct(config.httpClientConfig.proxyConfiguration))
				return "";
			var proxyConfig = config.httpClientConfig.proxyConfiguration;
			return structKeyExists(proxyConfig, "ntlmWorkstation") ? trim("" & proxyConfig.ntlmWorkstation) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigNtlmWorkstationSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "proxyConfiguration" = { "ntlmWorkstation" = value } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigNtlmWorkstationSetting(arguments.alias);
	}

	/**
	* "Username" field test (AWS S3 advanced settings, Client Config - Proxy section): mirrors
	* Ntlm Domain exactly, tracking httpClientConfig.proxyConfiguration.username instead.
	* Dedicated test alias "CCSTestCloudConfigProxyUsername" keeps this separate from the other
	* Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigProxyUsernameSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			if(NOT structKeyExists(config.httpClientConfig, "proxyConfiguration") OR NOT isStruct(config.httpClientConfig.proxyConfiguration))
				return "";
			var proxyConfig = config.httpClientConfig.proxyConfiguration;
			return structKeyExists(proxyConfig, "username") ? trim("" & proxyConfig.username) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigProxyUsernameSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "proxyConfiguration" = { "username" = value } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigProxyUsernameSetting(arguments.alias);
	}

	/**
	* "Password" field test (AWS S3 advanced settings, Client Config - Proxy section): mirrors
	* Proxy Username exactly, tracking httpClientConfig.proxyConfiguration.password instead.
	* Confirmed via direct testing that this is stored/returned in PLAIN TEXT (no auto-encryption,
	* unlike mail's password field or Cloud Credentials' AWS Secret Key), so a plain exact-match
	* comparison is safe. Dedicated test alias "CCSTestCloudConfigProxyPassword" keeps this
	* separate from the other Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigProxyPasswordSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			if(NOT structKeyExists(config.httpClientConfig, "proxyConfiguration") OR NOT isStruct(config.httpClientConfig.proxyConfiguration))
				return "";
			var proxyConfig = config.httpClientConfig.proxyConfiguration;
			return structKeyExists(proxyConfig, "password") ? trim("" & proxyConfig.password) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigProxyPasswordSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "proxyConfiguration" = { "password" = value } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigProxyPasswordSetting(arguments.alias);
	}

	/**
	* "Endpoint" field test (AWS S3 advanced settings, Client Config - Proxy section): mirrors
	* Proxy Username exactly, tracking httpClientConfig.proxyConfiguration.endpoint instead.
	* Dedicated test alias "CCSTestCloudConfigProxyEndpoint" keeps this separate from the other
	* Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigProxyEndpointSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "httpClientConfig") OR NOT isStruct(config.httpClientConfig))
				return "";
			if(NOT structKeyExists(config.httpClientConfig, "proxyConfiguration") OR NOT isStruct(config.httpClientConfig.proxyConfiguration))
				return "";
			var proxyConfig = config.httpClientConfig.proxyConfiguration;
			return structKeyExists(proxyConfig, "endpoint") ? trim("" & proxyConfig.endpoint) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigProxyEndpointSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"httpClientConfig" = { "proxyConfiguration" = { "endpoint" = value } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigProxyEndpointSetting(arguments.alias);
	}

	/**
	* "Number of Retries" field test (AWS S3 advanced settings, Request Config section): the tracked
	* value is clientOverrideConfig.retryPolicy.numRetries for a fixed, dedicated test alias
	* ("CCSTestCloudConfigNumRetries" — kept separate from the other Cloud Configuration test
	* fixtures). Same nested-struct requirement as API Call Attempt/Call Timeout, one level deeper —
	* confirmed via direct testing that addServiceConfig() requires the numRetries key nested under
	* clientOverrideConfig.retryPolicy (a top-level or clientOverrideConfig-level numRetries key is
	* rejected as unknown). Cycles between two plain integers ("3"/"5"), same delete-then-recreate
	* pattern as the other clientOverrideConfig fields.
	*/
	public string function getCloudConfigNumRetriesSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			return structKeyExists(retryPolicy, "numRetries") ? trim("" & retryPolicy.numRetries) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigNumRetriesSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = { "retryPolicy" = { "numRetries" = value } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigNumRetriesSetting(arguments.alias);
	}

	/**
	* "Retry conditions" AND/OR dropdown field test (AWS S3 advanced settings, Request Config
	* section): the tracked value is clientOverrideConfig.retryPolicy.retryCondition.type for a
	* fixed, dedicated test alias ("CCSTestCloudConfigRetryConditionType"). Confirmed via direct
	* testing that retryCondition.type can be set on its own, without a conditions array, so this
	* field is tested independently of the two Condition rows below. Cycles between the dropdown's
	* two real values ("AND"/"OR").
	*/
	public string function getCloudConfigRetryConditionTypeSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			if(NOT structKeyExists(retryPolicy, "retryCondition") OR NOT isStruct(retryPolicy.retryCondition))
				return "";
			return structKeyExists(retryPolicy.retryCondition, "type") ? trim("" & retryPolicy.retryCondition.type) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigRetryConditionTypeSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = { "retryPolicy" = { "retryCondition" = { "type" = value } } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigRetryConditionTypeSetting(arguments.alias);
	}

	/**
	* "Retry conditions" Condition 1 + Condition 2 rows field test (AWS S3 advanced settings,
	* Request Config section, shown when the AND/OR dropdown above has a value): both rows only
	* ever offer one real type in the admin UI ("Status Codes" -> StatusCode), so there is no second
	* value to cycle either row to individually — confirmed via direct testing that the backend
	* itself does not validate the type string at all (any string is accepted), so a "second value"
	* would be fabricated, not something reachable from the admin UI. Tracked instead as presence of
	* the pair as a whole for a fixed, dedicated test alias ("CCSTestCloudConfigRetryConditions"):
	* absent (no conditions array) vs. both rows present with type=StatusCode, mirroring the
	* create/remove pattern used for Config Alias registration elsewhere in this suite.
	*/
	public string function getCloudConfigRetryConditionsSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			if(NOT structKeyExists(retryPolicy, "retryCondition") OR NOT isStruct(retryPolicy.retryCondition))
				return "";
			if(NOT structKeyExists(retryPolicy.retryCondition, "conditions") OR NOT isArray(retryPolicy.retryCondition.conditions))
				return "";
			var conditions = retryPolicy.retryCondition.conditions;
			if(arrayLen(conditions) NEQ 2)
				return "";
			return trim("" & conditions[1].type) & "," & trim("" & conditions[2].type);
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigRetryConditionsSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = {
						"retryPolicy" = {
							"retryCondition" = {
								"type" = "AND",
								"conditions" = [
									{ "type" = "StatusCode", "statusCodes" = "500,503" },
									{ "type" = "StatusCode", "statusCodes" = "429" }
								]
							}
						}
					}
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigRetryConditionsSetting(arguments.alias);
	}

	/**
	* "Retry conditions" Condition 1's Status Codes text box (next to the fixed "Status Codes"
	* dropdown) field test: the tracked value is
	* clientOverrideConfig.retryPolicy.retryCondition.conditions[1].statusCodes for a fixed,
	* dedicated test alias ("CCSTestCloudConfigRetryCondition1StatusCodes"). Condition 2's row is
	* filled with a fixed placeholder ("999") so the array always has the 2 entries the admin API
	* requires once "AND"/"OR" is chosen. Cycles between two comma-separated code lists.
	*/
	public string function getCloudConfigRetryCondition1StatusCodesSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			if(NOT structKeyExists(retryPolicy, "retryCondition") OR NOT isStruct(retryPolicy.retryCondition))
				return "";
			if(NOT structKeyExists(retryPolicy.retryCondition, "conditions") OR NOT isArray(retryPolicy.retryCondition.conditions))
				return "";
			var conditions = retryPolicy.retryCondition.conditions;
			if(arrayLen(conditions) LT 1)
				return "";
			return structKeyExists(conditions[1], "statusCodes") ? trim("" & conditions[1].statusCodes) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigRetryCondition1StatusCodesSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = {
						"retryPolicy" = {
							"retryCondition" = {
								"type" = "AND",
								"conditions" = [
									{ "type" = "StatusCode", "statusCodes" = value },
									{ "type" = "StatusCode", "statusCodes" = "999" }
								]
							}
						}
					}
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigRetryCondition1StatusCodesSetting(arguments.alias);
	}

	/**
	* "Retry conditions" Condition 2's Status Codes text box field test: mirrors Condition 1's
	* Status Codes exactly, tracking conditions[2].statusCodes instead, with Condition 1's row
	* filled with a fixed placeholder ("999"). Dedicated test alias
	* "CCSTestCloudConfigRetryCondition2StatusCodes" keeps this separate from the other Cloud
	* Configuration test fixtures.
	*/
	public string function getCloudConfigRetryCondition2StatusCodesSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			if(NOT structKeyExists(retryPolicy, "retryCondition") OR NOT isStruct(retryPolicy.retryCondition))
				return "";
			if(NOT structKeyExists(retryPolicy.retryCondition, "conditions") OR NOT isArray(retryPolicy.retryCondition.conditions))
				return "";
			var conditions = retryPolicy.retryCondition.conditions;
			if(arrayLen(conditions) LT 2)
				return "";
			return structKeyExists(conditions[2], "statusCodes") ? trim("" & conditions[2].statusCodes) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigRetryCondition2StatusCodesSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = {
						"retryPolicy" = {
							"retryCondition" = {
								"type" = "AND",
								"conditions" = [
									{ "type" = "StatusCode", "statusCodes" = "999" },
									{ "type" = "StatusCode", "statusCodes" = value }
								]
							}
						}
					}
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigRetryCondition2StatusCodesSetting(arguments.alias);
	}

	/**
	* "Backoff Strategy" dropdown field test (AWS S3 advanced settings, Request Config section):
	* the tracked value is clientOverrideConfig.retryPolicy.backoffStrategy.type for a fixed,
	* dedicated test alias ("CCSTestCloudConfigBackoffStrategyType"). Confirmed via direct testing
	* that backoffStrategy.type can be set on its own, without a strategy struct. Cycles between two
	* of the dropdown's real values ("EqualJitter"/"FullJitter").
	*/
	public string function getCloudConfigBackoffStrategyTypeSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			if(NOT structKeyExists(retryPolicy, "backoffStrategy") OR NOT isStruct(retryPolicy.backoffStrategy))
				return "";
			return structKeyExists(retryPolicy.backoffStrategy, "type") ? trim("" & retryPolicy.backoffStrategy.type) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigBackoffStrategyTypeSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = { "retryPolicy" = { "backoffStrategy" = { "type" = value } } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigBackoffStrategyTypeSetting(arguments.alias);
	}

	/**
	* "Base Delay" field test (AWS S3 advanced settings, Request Config section, shown for the
	* Equal/Full Jitter backoff strategies): the tracked value is
	* clientOverrideConfig.retryPolicy.backoffStrategy.strategy.baseDelay for a fixed, dedicated
	* test alias ("CCSTestCloudConfigBackoffBaseDelay"). Paired with type="EqualJitter" so the
	* config matches what the admin UI would actually send when this field is visible.
	*/
	public string function getCloudConfigBackoffBaseDelaySetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			if(NOT structKeyExists(retryPolicy, "backoffStrategy") OR NOT isStruct(retryPolicy.backoffStrategy))
				return "";
			if(NOT structKeyExists(retryPolicy.backoffStrategy, "strategy") OR NOT isStruct(retryPolicy.backoffStrategy.strategy))
				return "";
			var strategy = retryPolicy.backoffStrategy.strategy;
			return structKeyExists(strategy, "baseDelay") ? trim("" & strategy.baseDelay) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigBackoffBaseDelaySetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = { "retryPolicy" = { "backoffStrategy" = { "type" = "EqualJitter", "strategy" = { "baseDelay" = value } } } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigBackoffBaseDelaySetting(arguments.alias);
	}

	/**
	* "Max Backoff Time" field test: mirrors Base Delay exactly, tracking
	* clientOverrideConfig.retryPolicy.backoffStrategy.strategy.maxBackoffTime instead, paired with
	* the same type="EqualJitter". Dedicated test alias "CCSTestCloudConfigBackoffMaxBackoffTime"
	* keeps this separate from the other Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigBackoffMaxBackoffTimeSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			if(NOT structKeyExists(retryPolicy, "backoffStrategy") OR NOT isStruct(retryPolicy.backoffStrategy))
				return "";
			if(NOT structKeyExists(retryPolicy.backoffStrategy, "strategy") OR NOT isStruct(retryPolicy.backoffStrategy.strategy))
				return "";
			var strategy = retryPolicy.backoffStrategy.strategy;
			return structKeyExists(strategy, "maxBackoffTime") ? trim("" & strategy.maxBackoffTime) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigBackoffMaxBackoffTimeSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = { "retryPolicy" = { "backoffStrategy" = { "type" = "EqualJitter", "strategy" = { "maxBackoffTime" = value } } } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigBackoffMaxBackoffTimeSetting(arguments.alias);
	}

	/**
	* "Fixed Delay" field test (shown for the Fixed Delay backoff strategy): the tracked value is
	* clientOverrideConfig.retryPolicy.backoffStrategy.strategy.fixedDelay for a fixed, dedicated
	* test alias ("CCSTestCloudConfigBackoffFixedDelay"). Paired with type="FixedDelay" so the
	* config matches what the admin UI would actually send when this field is visible.
	*/
	public string function getCloudConfigBackoffFixedDelaySetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			if(NOT structKeyExists(retryPolicy, "backoffStrategy") OR NOT isStruct(retryPolicy.backoffStrategy))
				return "";
			if(NOT structKeyExists(retryPolicy.backoffStrategy, "strategy") OR NOT isStruct(retryPolicy.backoffStrategy.strategy))
				return "";
			var strategy = retryPolicy.backoffStrategy.strategy;
			return structKeyExists(strategy, "fixedDelay") ? trim("" & strategy.fixedDelay) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigBackoffFixedDelaySetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = { "retryPolicy" = { "backoffStrategy" = { "type" = "FixedDelay", "strategy" = { "fixedDelay" = value } } } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigBackoffFixedDelaySetting(arguments.alias);
	}

	/**
	* "Throttle Backoff Strategy" dropdown field test: mirrors Backoff Strategy Type exactly,
	* tracking clientOverrideConfig.retryPolicy.throttlingBackoffStrategy.type instead of
	* backoffStrategy.type (a separate strategy the AWS S3 admin UI applies specifically to
	* throttling-related retries). Dedicated test alias "CCSTestCloudConfigThrottleBackoffStrategyType"
	* keeps this separate from the other Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigThrottleBackoffStrategyTypeSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			if(NOT structKeyExists(retryPolicy, "throttlingBackoffStrategy") OR NOT isStruct(retryPolicy.throttlingBackoffStrategy))
				return "";
			return structKeyExists(retryPolicy.throttlingBackoffStrategy, "type") ? trim("" & retryPolicy.throttlingBackoffStrategy.type) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigThrottleBackoffStrategyTypeSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = { "retryPolicy" = { "throttlingBackoffStrategy" = { "type" = value } } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigThrottleBackoffStrategyTypeSetting(arguments.alias);
	}

	/**
	* "Base Delay" field test for the Throttle Backoff Strategy (shown for Equal/Full Jitter): mirrors
	* Backoff Strategy's Base Delay exactly, tracking
	* clientOverrideConfig.retryPolicy.throttlingBackoffStrategy.strategy.baseDelay instead, paired
	* with type="EqualJitter". Dedicated test alias "CCSTestCloudConfigThrottleBackoffBaseDelay"
	* keeps this separate from the other Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigThrottleBackoffBaseDelaySetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			if(NOT structKeyExists(retryPolicy, "throttlingBackoffStrategy") OR NOT isStruct(retryPolicy.throttlingBackoffStrategy))
				return "";
			if(NOT structKeyExists(retryPolicy.throttlingBackoffStrategy, "strategy") OR NOT isStruct(retryPolicy.throttlingBackoffStrategy.strategy))
				return "";
			var strategy = retryPolicy.throttlingBackoffStrategy.strategy;
			return structKeyExists(strategy, "baseDelay") ? trim("" & strategy.baseDelay) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigThrottleBackoffBaseDelaySetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = { "retryPolicy" = { "throttlingBackoffStrategy" = { "type" = "EqualJitter", "strategy" = { "baseDelay" = value } } } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigThrottleBackoffBaseDelaySetting(arguments.alias);
	}

	/**
	* "Max Backoff Time" field test for the Throttle Backoff Strategy: mirrors Throttle Backoff Base
	* Delay exactly, tracking
	* clientOverrideConfig.retryPolicy.throttlingBackoffStrategy.strategy.maxBackoffTime instead.
	* Dedicated test alias "CCSTestCloudConfigThrottleBackoffMaxBackoffTime" keeps this separate from
	* the other Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigThrottleBackoffMaxBackoffTimeSetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			if(NOT structKeyExists(retryPolicy, "throttlingBackoffStrategy") OR NOT isStruct(retryPolicy.throttlingBackoffStrategy))
				return "";
			if(NOT structKeyExists(retryPolicy.throttlingBackoffStrategy, "strategy") OR NOT isStruct(retryPolicy.throttlingBackoffStrategy.strategy))
				return "";
			var strategy = retryPolicy.throttlingBackoffStrategy.strategy;
			return structKeyExists(strategy, "maxBackoffTime") ? trim("" & strategy.maxBackoffTime) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigThrottleBackoffMaxBackoffTimeSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = { "retryPolicy" = { "throttlingBackoffStrategy" = { "type" = "EqualJitter", "strategy" = { "maxBackoffTime" = value } } } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigThrottleBackoffMaxBackoffTimeSetting(arguments.alias);
	}

	/**
	* "Fixed Delay" field test for the Throttle Backoff Strategy (shown for the Fixed Delay
	* strategy): mirrors Backoff Strategy's Fixed Delay exactly, tracking
	* clientOverrideConfig.retryPolicy.throttlingBackoffStrategy.strategy.fixedDelay instead, paired
	* with type="FixedDelay". Dedicated test alias "CCSTestCloudConfigThrottleBackoffFixedDelay"
	* keeps this separate from the other Cloud Configuration test fixtures.
	*/
	public string function getCloudConfigThrottleBackoffFixedDelaySetting(required string alias){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.alias);
			if(NOT structKeyExists(config, "clientOverrideConfig") OR NOT isStruct(config.clientOverrideConfig))
				return "";
			if(NOT structKeyExists(config.clientOverrideConfig, "retryPolicy") OR NOT isStruct(config.clientOverrideConfig.retryPolicy))
				return "";
			var retryPolicy = config.clientOverrideConfig.retryPolicy;
			if(NOT structKeyExists(retryPolicy, "throttlingBackoffStrategy") OR NOT isStruct(retryPolicy.throttlingBackoffStrategy))
				return "";
			if(NOT structKeyExists(retryPolicy.throttlingBackoffStrategy, "strategy") OR NOT isStruct(retryPolicy.throttlingBackoffStrategy.strategy))
				return "";
			var strategy = retryPolicy.throttlingBackoffStrategy.strategy;
			return structKeyExists(strategy, "fixedDelay") ? trim("" & strategy.fixedDelay) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudConfigThrottleBackoffFixedDelaySetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.alias);
			if(len(value)){
				runtime.api.addServiceConfig({
					"alias" = arguments.alias,
					"serviceName" = "S3",
					"clientOverrideConfig" = { "retryPolicy" = { "throttlingBackoffStrategy" = { "type" = "FixedDelay", "strategy" = { "fixedDelay" = value } } } }
				});
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudConfigThrottleBackoffFixedDelaySetting(arguments.alias);
	}

	/**
	* Generic field definition registry for expanded Cloud Configuration services:
	* AWS SQS, AWS SNS, AWS DynamoDB, Azure Blob, Azure Service Bus, GCP Firestore, GCP Storage, GCP PubSub.
	*/
	private struct function getExpandedFieldDefinitions(){
		var defs = {};
		defs["ccstestcloudconfigsqsapicallattempttimeout"] = { "setting": "CCSTestCloudConfigSqsApiCallAttemptTimeout", "service": "SQS", "path": "clientOverrideConfig.apiCallAttemptTimeout", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigsqsapicalltimeout"] = { "setting": "CCSTestCloudConfigSqsApiCallTimeout", "service": "SQS", "path": "clientOverrideConfig.apiCallTimeout", "type": "string", "val1": "30s", "val2": "60s" };
		defs["ccstestcloudconfigsqsconnectionacquisitiontimeout"] = { "setting": "CCSTestCloudConfigSqsConnectionAcquisitionTimeout", "service": "SQS", "path": "httpClientConfig.connectionAcquisitionTimeout", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigsqsconnectionmaxidletime"] = { "setting": "CCSTestCloudConfigSqsConnectionMaxIdleTime", "service": "SQS", "path": "httpClientConfig.connectionMaxIdleTime", "type": "string", "val1": "30s", "val2": "60s" };
		defs["ccstestcloudconfigsqsconnectiontimeout"] = { "setting": "CCSTestCloudConfigSqsConnectionTimeout", "service": "SQS", "path": "httpClientConfig.connectionTimeout", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigsqsconnectiontimetolive"] = { "setting": "CCSTestCloudConfigSqsConnectionTimeToLive", "service": "SQS", "path": "httpClientConfig.connectionTimeToLive", "type": "string", "val1": "60s", "val2": "120s" };
		defs["ccstestcloudconfigsqsexpectcontinueenabled"] = { "setting": "CCSTestCloudConfigSqsExpectContinueEnabled", "service": "SQS", "path": "httpClientConfig.expectContinueEnabled", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigsqsmaxconnections"] = { "setting": "CCSTestCloudConfigSqsMaxConnections", "service": "SQS", "path": "httpClientConfig.maxConnections", "type": "number", "val1": "50", "val2": "100" };
		defs["ccstestcloudconfigsqssockettimeout"] = { "setting": "CCSTestCloudConfigSqsSocketTimeout", "service": "SQS", "path": "httpClientConfig.socketTimeout", "type": "string", "val1": "30s", "val2": "60s" };
		defs["ccstestcloudconfigsqsuseidleconnectionreaper"] = { "setting": "CCSTestCloudConfigSqsUseIdleConnectionReaper", "service": "SQS", "path": "httpClientConfig.useIdleConnectionReaper", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigsqsnonproxyhosts"] = { "setting": "CCSTestCloudConfigSqsNonProxyHosts", "service": "SQS", "path": "httpClientConfig.proxyConfiguration.nonProxyHosts", "type": "array", "val1": "localhost", "val2": "127.0.0.1" };
		defs["ccstestcloudconfigsqsntlmdomain"] = { "setting": "CCSTestCloudConfigSqsNtlmDomain", "service": "SQS", "path": "httpClientConfig.proxyConfiguration.ntlmdomain", "type": "string", "val1": "CCSTESTDOMAIN1", "val2": "CCSTESTDOMAIN2" };
		defs["ccstestcloudconfigsqsntlmworkstation"] = { "setting": "CCSTestCloudConfigSqsNtlmWorkstation", "service": "SQS", "path": "httpClientConfig.proxyConfiguration.ntlmWorkstation", "type": "string", "val1": "CCSTESTWS1", "val2": "CCSTESTWS2" };
		defs["ccstestcloudconfigsqsproxyusername"] = { "setting": "CCSTestCloudConfigSqsProxyUsername", "service": "SQS", "path": "httpClientConfig.proxyConfiguration.username", "type": "string", "val1": "ccsProxyUser1", "val2": "ccsProxyUser2" };
		defs["ccstestcloudconfigsqsproxypassword"] = { "setting": "CCSTestCloudConfigSqsProxyPassword", "service": "SQS", "path": "httpClientConfig.proxyConfiguration.password", "type": "string", "val1": "ccsProxyPass1", "val2": "ccsProxyPass2" };
		defs["ccstestcloudconfigsqsproxyendpoint"] = { "setting": "CCSTestCloudConfigSqsProxyEndpoint", "service": "SQS", "path": "httpClientConfig.proxyConfiguration.endpoint", "type": "string", "val1": "http://proxy1.ccssuite-test.local:8080", "val2": "http://proxy2.ccssuite-test.local:8080" };
		defs["ccstestcloudconfigsqspreemptivebasicauthenabled"] = { "setting": "CCSTestCloudConfigSqsPreemptiveBasicAuthEnabled", "service": "SQS", "path": "httpClientConfig.proxyConfiguration.preemptiveBasicAuthenticationEnabled", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigsqsnumretries"] = { "setting": "CCSTestCloudConfigSqsNumRetries", "service": "SQS", "path": "clientOverrideConfig.retryPolicy.numRetries", "type": "number", "val1": "3", "val2": "5" };
		defs["ccstestcloudconfigsnsapicallattempttimeout"] = { "setting": "CCSTestCloudConfigSnsApiCallAttemptTimeout", "service": "SNS", "path": "clientOverrideConfig.apiCallAttemptTimeout", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigsnsapicalltimeout"] = { "setting": "CCSTestCloudConfigSnsApiCallTimeout", "service": "SNS", "path": "clientOverrideConfig.apiCallTimeout", "type": "string", "val1": "30s", "val2": "60s" };
		defs["ccstestcloudconfigsnsconnectionacquisitiontimeout"] = { "setting": "CCSTestCloudConfigSnsConnectionAcquisitionTimeout", "service": "SNS", "path": "httpClientConfig.connectionAcquisitionTimeout", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigsnsconnectionmaxidletime"] = { "setting": "CCSTestCloudConfigSnsConnectionMaxIdleTime", "service": "SNS", "path": "httpClientConfig.connectionMaxIdleTime", "type": "string", "val1": "30s", "val2": "60s" };
		defs["ccstestcloudconfigsnsconnectiontimeout"] = { "setting": "CCSTestCloudConfigSnsConnectionTimeout", "service": "SNS", "path": "httpClientConfig.connectionTimeout", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigsnsconnectiontimetolive"] = { "setting": "CCSTestCloudConfigSnsConnectionTimeToLive", "service": "SNS", "path": "httpClientConfig.connectionTimeToLive", "type": "string", "val1": "60s", "val2": "120s" };
		defs["ccstestcloudconfigsnsexpectcontinueenabled"] = { "setting": "CCSTestCloudConfigSnsExpectContinueEnabled", "service": "SNS", "path": "httpClientConfig.expectContinueEnabled", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigsnsmaxconnections"] = { "setting": "CCSTestCloudConfigSnsMaxConnections", "service": "SNS", "path": "httpClientConfig.maxConnections", "type": "number", "val1": "50", "val2": "100" };
		defs["ccstestcloudconfigsnssockettimeout"] = { "setting": "CCSTestCloudConfigSnsSocketTimeout", "service": "SNS", "path": "httpClientConfig.socketTimeout", "type": "string", "val1": "30s", "val2": "60s" };
		defs["ccstestcloudconfigsnsuseidleconnectionreaper"] = { "setting": "CCSTestCloudConfigSnsUseIdleConnectionReaper", "service": "SNS", "path": "httpClientConfig.useIdleConnectionReaper", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigsnsnonproxyhosts"] = { "setting": "CCSTestCloudConfigSnsNonProxyHosts", "service": "SNS", "path": "httpClientConfig.proxyConfiguration.nonProxyHosts", "type": "array", "val1": "localhost", "val2": "127.0.0.1" };
		defs["ccstestcloudconfigsnsntlmdomain"] = { "setting": "CCSTestCloudConfigSnsNtlmDomain", "service": "SNS", "path": "httpClientConfig.proxyConfiguration.ntlmdomain", "type": "string", "val1": "CCSTESTDOMAIN1", "val2": "CCSTESTDOMAIN2" };
		defs["ccstestcloudconfigsnsntlmworkstation"] = { "setting": "CCSTestCloudConfigSnsNtlmWorkstation", "service": "SNS", "path": "httpClientConfig.proxyConfiguration.ntlmWorkstation", "type": "string", "val1": "CCSTESTWS1", "val2": "CCSTESTWS2" };
		defs["ccstestcloudconfigsnsproxyusername"] = { "setting": "CCSTestCloudConfigSnsProxyUsername", "service": "SNS", "path": "httpClientConfig.proxyConfiguration.username", "type": "string", "val1": "ccsProxyUser1", "val2": "ccsProxyUser2" };
		defs["ccstestcloudconfigsnsproxypassword"] = { "setting": "CCSTestCloudConfigSnsProxyPassword", "service": "SNS", "path": "httpClientConfig.proxyConfiguration.password", "type": "string", "val1": "ccsProxyPass1", "val2": "ccsProxyPass2" };
		defs["ccstestcloudconfigsnsproxyendpoint"] = { "setting": "CCSTestCloudConfigSnsProxyEndpoint", "service": "SNS", "path": "httpClientConfig.proxyConfiguration.endpoint", "type": "string", "val1": "http://proxy1.ccssuite-test.local:8080", "val2": "http://proxy2.ccssuite-test.local:8080" };
		defs["ccstestcloudconfigsnspreemptivebasicauthenabled"] = { "setting": "CCSTestCloudConfigSnsPreemptiveBasicAuthEnabled", "service": "SNS", "path": "httpClientConfig.proxyConfiguration.preemptiveBasicAuthenticationEnabled", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigsnsnumretries"] = { "setting": "CCSTestCloudConfigSnsNumRetries", "service": "SNS", "path": "clientOverrideConfig.retryPolicy.numRetries", "type": "number", "val1": "3", "val2": "5" };
		defs["ccstestcloudconfigdynamoapicallattempttimeout"] = { "setting": "CCSTestCloudConfigDynamoApiCallAttemptTimeout", "service": "DYNAMODB", "path": "clientOverrideConfig.apiCallAttemptTimeout", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigdynamoapicalltimeout"] = { "setting": "CCSTestCloudConfigDynamoApiCallTimeout", "service": "DYNAMODB", "path": "clientOverrideConfig.apiCallTimeout", "type": "string", "val1": "30s", "val2": "60s" };
		defs["ccstestcloudconfigdynamoconnectionacquisitiontimeout"] = { "setting": "CCSTestCloudConfigDynamoConnectionAcquisitionTimeout", "service": "DYNAMODB", "path": "httpClientConfig.connectionAcquisitionTimeout", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigdynamoconnectionmaxidletime"] = { "setting": "CCSTestCloudConfigDynamoConnectionMaxIdleTime", "service": "DYNAMODB", "path": "httpClientConfig.connectionMaxIdleTime", "type": "string", "val1": "30s", "val2": "60s" };
		defs["ccstestcloudconfigdynamoconnectiontimeout"] = { "setting": "CCSTestCloudConfigDynamoConnectionTimeout", "service": "DYNAMODB", "path": "httpClientConfig.connectionTimeout", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigdynamoconnectiontimetolive"] = { "setting": "CCSTestCloudConfigDynamoConnectionTimeToLive", "service": "DYNAMODB", "path": "httpClientConfig.connectionTimeToLive", "type": "string", "val1": "60s", "val2": "120s" };
		defs["ccstestcloudconfigdynamoexpectcontinueenabled"] = { "setting": "CCSTestCloudConfigDynamoExpectContinueEnabled", "service": "DYNAMODB", "path": "httpClientConfig.expectContinueEnabled", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigdynamomaxconnections"] = { "setting": "CCSTestCloudConfigDynamoMaxConnections", "service": "DYNAMODB", "path": "httpClientConfig.maxConnections", "type": "number", "val1": "50", "val2": "100" };
		defs["ccstestcloudconfigdynamosockettimeout"] = { "setting": "CCSTestCloudConfigDynamoSocketTimeout", "service": "DYNAMODB", "path": "httpClientConfig.socketTimeout", "type": "string", "val1": "30s", "val2": "60s" };
		defs["ccstestcloudconfigdynamouseidleconnectionreaper"] = { "setting": "CCSTestCloudConfigDynamoUseIdleConnectionReaper", "service": "DYNAMODB", "path": "httpClientConfig.useIdleConnectionReaper", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigdynamononproxyhosts"] = { "setting": "CCSTestCloudConfigDynamoNonProxyHosts", "service": "DYNAMODB", "path": "httpClientConfig.proxyConfiguration.nonProxyHosts", "type": "array", "val1": "localhost", "val2": "127.0.0.1" };
		defs["ccstestcloudconfigdynamontlmdomain"] = { "setting": "CCSTestCloudConfigDynamoNtlmDomain", "service": "DYNAMODB", "path": "httpClientConfig.proxyConfiguration.ntlmdomain", "type": "string", "val1": "CCSTESTDOMAIN1", "val2": "CCSTESTDOMAIN2" };
		defs["ccstestcloudconfigdynamontlmworkstation"] = { "setting": "CCSTestCloudConfigDynamoNtlmWorkstation", "service": "DYNAMODB", "path": "httpClientConfig.proxyConfiguration.ntlmWorkstation", "type": "string", "val1": "CCSTESTWS1", "val2": "CCSTESTWS2" };
		defs["ccstestcloudconfigdynamoproxyusername"] = { "setting": "CCSTestCloudConfigDynamoProxyUsername", "service": "DYNAMODB", "path": "httpClientConfig.proxyConfiguration.username", "type": "string", "val1": "ccsProxyUser1", "val2": "ccsProxyUser2" };
		defs["ccstestcloudconfigdynamoproxypassword"] = { "setting": "CCSTestCloudConfigDynamoProxyPassword", "service": "DYNAMODB", "path": "httpClientConfig.proxyConfiguration.password", "type": "string", "val1": "ccsProxyPass1", "val2": "ccsProxyPass2" };
		defs["ccstestcloudconfigdynamoproxyendpoint"] = { "setting": "CCSTestCloudConfigDynamoProxyEndpoint", "service": "DYNAMODB", "path": "httpClientConfig.proxyConfiguration.endpoint", "type": "string", "val1": "http://proxy1.ccssuite-test.local:8080", "val2": "http://proxy2.ccssuite-test.local:8080" };
		defs["ccstestcloudconfigdynamopreemptivebasicauthenabled"] = { "setting": "CCSTestCloudConfigDynamoPreemptiveBasicAuthEnabled", "service": "DYNAMODB", "path": "httpClientConfig.proxyConfiguration.preemptiveBasicAuthenticationEnabled", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigdynamonumretries"] = { "setting": "CCSTestCloudConfigDynamoNumRetries", "service": "DYNAMODB", "path": "clientOverrideConfig.retryPolicy.numRetries", "type": "number", "val1": "3", "val2": "5" };
		defs["ccstestcloudconfigblobconcreqcount"] = { "setting": "CCSTestCloudConfigBlobConcReqCount", "service": "AZURE_BLOB", "path": "options.concurrentRequestCount", "type": "number", "val1": "5", "val2": "10" };
		defs["ccstestcloudconfigblobsingleblobputthresholdinbytes"] = { "setting": "CCSTestCloudConfigBlobSingleBlobPutThresholdInBytes", "service": "AZURE_BLOB", "path": "options.singleBlobPutThresholdInBytes", "type": "number", "val1": "2097152", "val2": "4194304" };
		defs["ccstestcloudconfigblobtimeoutintervalinms"] = { "setting": "CCSTestCloudConfigBlobTimeoutIntervalInMs", "service": "AZURE_BLOB", "path": "options.timeoutIntervalInMs", "type": "number", "val1": "1000", "val2": "2000" };
		defs["ccstestcloudconfigblobmaximumexecutiontimeinms"] = { "setting": "CCSTestCloudConfigBlobMaximumExecutionTimeInMs", "service": "AZURE_BLOB", "path": "options.maximumExecutionTimeInMs", "type": "number", "val1": "3000", "val2": "5000" };
		defs["ccstestcloudconfigbloblocationmode"] = { "setting": "CCSTestCloudConfigBlobLocationMode", "service": "AZURE_BLOB", "path": "options.locationMode", "type": "string", "val1": "PRIMARY_ONLY", "val2": "SECONDARY_ONLY" };
		defs["ccstestcloudconfigblobusetranscontentmd5"] = { "setting": "CCSTestCloudConfigBlobUseTransContentMD5", "service": "AZURE_BLOB", "path": "options.useTransactionalContentMD5", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigblobdisablecontentmd5validation"] = { "setting": "CCSTestCloudConfigBlobDisableContentMD5Validation", "service": "AZURE_BLOB", "path": "options.disableContentMD5Validation", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigblobstoreblobcontentmd5"] = { "setting": "CCSTestCloudConfigBlobStoreBlobContentMD5", "service": "AZURE_BLOB", "path": "options.storeBlobContentMD5", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigblobabsorbconditionalerrorsonretry"] = { "setting": "CCSTestCloudConfigBlobAbsorbConditionalErrorsOnRetry", "service": "AZURE_BLOB", "path": "options.absorbConditionalErrorsOnRetry", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigblobskipetaglocking"] = { "setting": "CCSTestCloudConfigBlobSkipEtagLocking", "service": "AZURE_BLOB", "path": "options.skipEtagLocking", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigblobretrypolicytype"] = { "setting": "CCSTestCloudConfigBlobRetryPolicyType", "service": "AZURE_BLOB", "path": "options.retryPolicyFactory.retryPolicyType", "type": "string", "val1": "LINEAR", "val2": "EXPONENTIAL" };
		defs["ccstestcloudconfigblobdeltabackoffintervalinms"] = { "setting": "CCSTestCloudConfigBlobDeltaBackoffIntervalInMs", "service": "AZURE_BLOB", "path": "options.retryPolicyFactory.deltaBackoffIntervalInMs", "type": "number", "val1": "100", "val2": "200" };
		defs["ccstestcloudconfigblobmaximumattempts"] = { "setting": "CCSTestCloudConfigBlobMaximumAttempts", "service": "AZURE_BLOB", "path": "options.retryPolicyFactory.maximumAttempts", "type": "number", "val1": "3", "val2": "5" };
		defs["ccstestcloudconfigblobresolvedminbackoff"] = { "setting": "CCSTestCloudConfigBlobResolvedMinBackoff", "service": "AZURE_BLOB", "path": "options.retryPolicyFactory.resolvedMinBackoff", "type": "number", "val1": "100", "val2": "200" };
		defs["ccstestcloudconfigblobresolvedmaxbackoff"] = { "setting": "CCSTestCloudConfigBlobResolvedMaxBackoff", "service": "AZURE_BLOB", "path": "options.retryPolicyFactory.resolvedMaxBackoff", "type": "number", "val1": "1000", "val2": "2000" };
		defs["ccstestcloudconfigblobenablelogging"] = { "setting": "CCSTestCloudConfigBlobEnableLogging", "service": "AZURE_BLOB", "path": "context.enableLogging", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigsboptimeout"] = { "setting": "CCSTestCloudConfigSbOpTimeout", "service": "SERVICE_BUS", "path": "operationTimeout", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigsbretrypolicytype"] = { "setting": "CCSTestCloudConfigSbRetryPolicyType", "service": "SERVICE_BUS", "path": "retryPolicy", "type": "string", "val1": "NoRetry", "val2": "Default" };
		defs["ccstestcloudconfigfshost"] = { "setting": "CCSTestCloudConfigFsHost", "service": "FIRESTORE", "path": "host", "type": "string", "val1": "firestore.googleapis.com:443", "val2": "firestore2.googleapis.com:443" };
		defs["ccstestcloudconfigfsdatabaseid"] = { "setting": "CCSTestCloudConfigFsDatabaseId", "service": "FIRESTORE", "path": "databaseId", "type": "string", "val1": "default", "val2": "customdb" };
		defs["ccstestcloudconfigfsemulatorhost"] = { "setting": "CCSTestCloudConfigFsEmulatorHost", "service": "FIRESTORE", "path": "emulatorHost", "type": "string", "val1": "localhost:8080", "val2": "localhost:8081" };
		defs["ccstestcloudconfigfsinitialretrydelay"] = { "setting": "CCSTestCloudConfigFsInitialRetryDelay", "service": "FIRESTORE", "path": "retrySettings.initialRetryDelay", "type": "string", "val1": "1s", "val2": "2s" };
		defs["ccstestcloudconfigfsmaxretrydelay"] = { "setting": "CCSTestCloudConfigFsMaxRetryDelay", "service": "FIRESTORE", "path": "retrySettings.maxRetryDelay", "type": "string", "val1": "32s", "val2": "64s" };
		defs["ccstestcloudconfigfsretrydelaymultiplier"] = { "setting": "CCSTestCloudConfigFsRetryDelayMultiplier", "service": "FIRESTORE", "path": "retrySettings.retryDelayMultiplier", "type": "number", "val1": "2.0", "val2": "3.0" };
		defs["ccstestcloudconfigfsinitialrpctimeout"] = { "setting": "CCSTestCloudConfigFsInitialRpcTimeout", "service": "FIRESTORE", "path": "retrySettings.initialRpcTimeout", "type": "string", "val1": "50s", "val2": "60s" };
		defs["ccstestcloudconfigfsmaxrpctimeout"] = { "setting": "CCSTestCloudConfigFsMaxRpcTimeout", "service": "FIRESTORE", "path": "retrySettings.maxRpcTimeout", "type": "string", "val1": "50s", "val2": "60s" };
		defs["ccstestcloudconfigfsrpctimeoutmultiplier"] = { "setting": "CCSTestCloudConfigFsRpcTimeoutMultiplier", "service": "FIRESTORE", "path": "retrySettings.rpcTimeoutMultiplier", "type": "number", "val1": "1.0", "val2": "1.5" };
		defs["ccstestcloudconfigfsmaxattempts"] = { "setting": "CCSTestCloudConfigFsMaxAttempts", "service": "FIRESTORE", "path": "retrySettings.maxAttempts", "type": "number", "val1": "6", "val2": "10" };
		defs["ccstestcloudconfigfstotaltimeout"] = { "setting": "CCSTestCloudConfigFsTotalTimeout", "service": "FIRESTORE", "path": "retrySettings.totalTimeout", "type": "string", "val1": "50s", "val2": "100s" };
		defs["ccstestcloudconfigfskeepalivetime"] = { "setting": "CCSTestCloudConfigFsKeepAliveTime", "service": "FIRESTORE", "path": "channelProvider.keepAliveTime", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigfskeepalivetimeout"] = { "setting": "CCSTestCloudConfigFsKeepAliveTimeout", "service": "FIRESTORE", "path": "channelProvider.keepAliveTimeout", "type": "string", "val1": "20s", "val2": "30s" };
		defs["ccstestcloudconfigfskeepalivewithoutcalls"] = { "setting": "CCSTestCloudConfigFsKeepAliveWithoutCalls", "service": "FIRESTORE", "path": "channelProvider.keepAliveWithoutCalls", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigfsmaxinboundmessagesize"] = { "setting": "CCSTestCloudConfigFsMaxInboundMessageSize", "service": "FIRESTORE", "path": "channelProvider.maxInboundMessageSize", "type": "number", "val1": "4194304", "val2": "8388608" };
		defs["ccstestcloudconfigstoragehost"] = { "setting": "CCSTestCloudConfigStorageHost", "service": "STORAGE", "path": "host", "type": "string", "val1": "https://storage.googleapis.com", "val2": "https://storage2.googleapis.com" };
		defs["ccstestcloudconfigstorageconnecttimeout"] = { "setting": "CCSTestCloudConfigStorageConnectTimeout", "service": "STORAGE", "path": "transportOptions.connectTimeout", "type": "number", "val1": "5000", "val2": "10000" };
		defs["ccstestcloudconfigstoragereadtimeout"] = { "setting": "CCSTestCloudConfigStorageReadTimeout", "service": "STORAGE", "path": "transportOptions.readTimeout", "type": "number", "val1": "10000", "val2": "20000" };
		defs["ccstestcloudconfigstorageinitialretrydelay"] = { "setting": "CCSTestCloudConfigStorageInitialRetryDelay", "service": "STORAGE", "path": "retrySettings.initialRetryDelay", "type": "string", "val1": "1s", "val2": "2s" };
		defs["ccstestcloudconfigstoragemaxretrydelay"] = { "setting": "CCSTestCloudConfigStorageMaxRetryDelay", "service": "STORAGE", "path": "retrySettings.maxRetryDelay", "type": "string", "val1": "32s", "val2": "64s" };
		defs["ccstestcloudconfigstorageretrydelaymultiplier"] = { "setting": "CCSTestCloudConfigStorageRetryDelayMultiplier", "service": "STORAGE", "path": "retrySettings.retryDelayMultiplier", "type": "number", "val1": "2.0", "val2": "3.0" };
		defs["ccstestcloudconfigstorageinitialrpctimeout"] = { "setting": "CCSTestCloudConfigStorageInitialRpcTimeout", "service": "STORAGE", "path": "retrySettings.initialRpcTimeout", "type": "string", "val1": "50s", "val2": "60s" };
		defs["ccstestcloudconfigstoragemaxrpctimeout"] = { "setting": "CCSTestCloudConfigStorageMaxRpcTimeout", "service": "STORAGE", "path": "retrySettings.maxRpcTimeout", "type": "string", "val1": "50s", "val2": "60s" };
		defs["ccstestcloudconfigstoragerpctimeoutmultiplier"] = { "setting": "CCSTestCloudConfigStorageRpcTimeoutMultiplier", "service": "STORAGE", "path": "retrySettings.rpcTimeoutMultiplier", "type": "number", "val1": "1.0", "val2": "1.5" };
		defs["ccstestcloudconfigstoragemaxattempts"] = { "setting": "CCSTestCloudConfigStorageMaxAttempts", "service": "STORAGE", "path": "retrySettings.maxAttempts", "type": "number", "val1": "6", "val2": "10" };
		defs["ccstestcloudconfigstoragetotaltimeout"] = { "setting": "CCSTestCloudConfigStorageTotalTimeout", "service": "STORAGE", "path": "retrySettings.totalTimeout", "type": "string", "val1": "50s", "val2": "100s" };
		defs["ccstestcloudconfigpubsubpublisherendpoint"] = { "setting": "CCSTestCloudConfigPubsubPublisherEndpoint", "service": "PUBSUB", "path": "publisherSettings.endpoint", "type": "string", "val1": "pubsub.googleapis.com:443", "val2": "pubsub2.googleapis.com:443" };
		defs["ccstestcloudconfigpubsubiscompressionenabled"] = { "setting": "CCSTestCloudConfigPubsubIsCompressionEnabled", "service": "PUBSUB", "path": "publisherSettings.enableCompression", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigpubsubcompressionbytesthreshold"] = { "setting": "CCSTestCloudConfigPubsubCompressionBytesThreshold", "service": "PUBSUB", "path": "publisherSettings.compressionBytesThreshold", "type": "number", "val1": "1024", "val2": "2048" };
		defs["ccstestcloudconfigpubsubismessageorderingenabled"] = { "setting": "CCSTestCloudConfigPubsubIsMessageOrderingEnabled", "service": "PUBSUB", "path": "publisherSettings.enableMessageOrdering", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigpubsubexecutorproviderthreadcount"] = { "setting": "CCSTestCloudConfigPubsubExecutorProviderThreadCount", "service": "PUBSUB", "path": "publisherSettings.executorProvider.threadCount", "type": "number", "val1": "4", "val2": "8" };
		defs["ccstestcloudconfigpubsubexecutorproviderthreadnameprefix"] = { "setting": "CCSTestCloudConfigPubsubExecutorProviderThreadNamePrefix", "service": "PUBSUB", "path": "publisherSettings.executorProvider.threadNamePrefix", "type": "string", "val1": "pub-exec", "val2": "pub-worker" };
		defs["ccstestcloudconfigpubsubisbatchingsettingsenabled"] = { "setting": "CCSTestCloudConfigPubsubIsBatchingSettingsEnabled", "service": "PUBSUB", "path": "publisherSettings.batchingSettings.enable", "type": "boolean", "val1": "true", "val2": "false" };
		defs["ccstestcloudconfigpubsubbatchingsettingsdelaythreshold"] = { "setting": "CCSTestCloudConfigPubsubBatchingSettingsDelayThreshold", "service": "PUBSUB", "path": "publisherSettings.batchingSettings.delayThreshold", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigpubsubbatchingsettingselementcountthreshold"] = { "setting": "CCSTestCloudConfigPubsubBatchingSettingsElementCountThreshold", "service": "PUBSUB", "path": "publisherSettings.batchingSettings.elementCountThreshold", "type": "number", "val1": "100", "val2": "200" };
		defs["ccstestcloudconfigpubsubbatchingsettingsrequestbytethreshold"] = { "setting": "CCSTestCloudConfigPubsubBatchingSettingsRequestByteThreshold", "service": "PUBSUB", "path": "publisherSettings.batchingSettings.requestByteThreshold", "type": "number", "val1": "1024", "val2": "2048" };
		defs["ccstestcloudconfigpubsubflowcontrolsettingslimitexceededbehavior"] = { "setting": "CCSTestCloudConfigPubsubFlowControlSettingsLimitExceededBehavior", "service": "PUBSUB", "path": "publisherSettings.batchingSettings.flowControlSettings.limitExceededBehavior", "type": "string", "val1": "Ignore", "val2": "Block" };
		defs["ccstestcloudconfigpubsubflowcontrolsettingsmaxoutstandingelementcount"] = { "setting": "CCSTestCloudConfigPubsubFlowControlSettingsMaxOutstandingElementCount", "service": "PUBSUB", "path": "publisherSettings.batchingSettings.flowControlSettings.maxOutstandingElementCount", "type": "number", "val1": "1000", "val2": "2000" };
		defs["ccstestcloudconfigpubsubflowcontrolsettingsmaxoutstandingrequestbytes"] = { "setting": "CCSTestCloudConfigPubsubFlowControlSettingsMaxOutstandingRequestBytes", "service": "PUBSUB", "path": "publisherSettings.batchingSettings.flowControlSettings.maxOutstandingRequestBytes", "type": "number", "val1": "10000", "val2": "20000" };
		defs["ccstestcloudconfigpubsubinitialretrydelay"] = { "setting": "CCSTestCloudConfigPubsubInitialRetryDelay", "service": "PUBSUB", "path": "publisherSettings.retrySettings.initialRetryDelay", "type": "string", "val1": "1s", "val2": "2s" };
		defs["ccstestcloudconfigpubsubmaxretrydelay"] = { "setting": "CCSTestCloudConfigPubsubMaxRetryDelay", "service": "PUBSUB", "path": "publisherSettings.retrySettings.maxRetryDelay", "type": "string", "val1": "32s", "val2": "64s" };
		defs["ccstestcloudconfigpubsubretrydelaymultiplier"] = { "setting": "CCSTestCloudConfigPubsubRetryDelayMultiplier", "service": "PUBSUB", "path": "publisherSettings.retrySettings.retryDelayMultiplier", "type": "number", "val1": "2.0", "val2": "3.0" };
		defs["ccstestcloudconfigpubsubinitialrpctimeout"] = { "setting": "CCSTestCloudConfigPubsubInitialRpcTimeout", "service": "PUBSUB", "path": "publisherSettings.retrySettings.initialRpcTimeout", "type": "string", "val1": "50s", "val2": "60s" };
		defs["ccstestcloudconfigpubsubmaxrpctimeout"] = { "setting": "CCSTestCloudConfigPubsubMaxRpcTimeout", "service": "PUBSUB", "path": "publisherSettings.retrySettings.maxRpcTimeout", "type": "string", "val1": "50s", "val2": "60s" };
		defs["ccstestcloudconfigpubsubrpctimeoutmultiplier"] = { "setting": "CCSTestCloudConfigPubsubRpcTimeoutMultiplier", "service": "PUBSUB", "path": "publisherSettings.retrySettings.rpcTimeoutMultiplier", "type": "number", "val1": "1.0", "val2": "1.5" };
		defs["ccstestcloudconfigpubsubmaxattempts"] = { "setting": "CCSTestCloudConfigPubsubMaxAttempts", "service": "PUBSUB", "path": "publisherSettings.retrySettings.maxAttempts", "type": "number", "val1": "6", "val2": "10" };
		defs["ccstestcloudconfigpubsubtotaltimeout"] = { "setting": "CCSTestCloudConfigPubsubTotalTimeout", "service": "PUBSUB", "path": "publisherSettings.retrySettings.totalTimeout", "type": "string", "val1": "50s", "val2": "100s" };
		defs["ccstestcloudconfigpubsubsubscriberendpoint"] = { "setting": "CCSTestCloudConfigPubsubSubscriberEndpoint", "service": "PUBSUB", "path": "subscriberSettings.endpoint", "type": "string", "val1": "pubsub.googleapis.com:443", "val2": "pubsub2.googleapis.com:443" };
		defs["ccstestcloudconfigpubsubparallelpullcount"] = { "setting": "CCSTestCloudConfigPubsubParallelPullCount", "service": "PUBSUB", "path": "subscriberSettings.parallelPullCount", "type": "number", "val1": "2", "val2": "4" };
		defs["ccstestcloudconfigpubsubsubexecutorproviderthreadcount"] = { "setting": "CCSTestCloudConfigPubsubSubExecutorProviderThreadCount", "service": "PUBSUB", "path": "subscriberSettings.executorProvider.threadCount", "type": "number", "val1": "4", "val2": "8" };
		defs["ccstestcloudconfigpubsubsubexecutorproviderthreadnameprefix"] = { "setting": "CCSTestCloudConfigPubsubSubExecutorProviderThreadNamePrefix", "service": "PUBSUB", "path": "subscriberSettings.executorProvider.threadNamePrefix", "type": "string", "val1": "sub-exec", "val2": "sub-worker" };
		defs["ccstestcloudconfigpubsubsubsystemexecutorproviderthreadcount"] = { "setting": "CCSTestCloudConfigPubsubSubSystemExecutorProviderThreadCount", "service": "PUBSUB", "path": "subscriberSettings.systemExecutorProvider.threadCount", "type": "number", "val1": "2", "val2": "4" };
		defs["ccstestcloudconfigpubsubsubsystemexecutorproviderthreadnameprefix"] = { "setting": "CCSTestCloudConfigPubsubSubSystemExecutorProviderThreadNamePrefix", "service": "PUBSUB", "path": "subscriberSettings.systemExecutorProvider.threadNamePrefix", "type": "string", "val1": "sys-exec", "val2": "sys-worker" };
		defs["ccstestcloudconfigpubsubmaxackextensionperiod"] = { "setting": "CCSTestCloudConfigPubsubMaxAckExtensionPeriod", "service": "PUBSUB", "path": "subscriberSettings.maxAckExtensionPeriod", "type": "string", "val1": "600s", "val2": "1200s" };
		defs["ccstestcloudconfigpubsubmindurationperackextensionperiod"] = { "setting": "CCSTestCloudConfigPubsubMinDurationPerAckExtensionPeriod", "service": "PUBSUB", "path": "subscriberSettings.minDurationPerAckExtensionPeriod", "type": "string", "val1": "10s", "val2": "20s" };
		defs["ccstestcloudconfigpubsubmaxdurationperackextensionperiod"] = { "setting": "CCSTestCloudConfigPubsubMaxDurationPerAckExtensionPeriod", "service": "PUBSUB", "path": "subscriberSettings.maxDurationPerAckExtensionPeriod", "type": "string", "val1": "60s", "val2": "120s" };
		defs["ccstestcloudconfigpubsubsubflowcontrolsettingslimitexceededbehavior"] = { "setting": "CCSTestCloudConfigPubsubSubFlowControlSettingsLimitExceededBehavior", "service": "PUBSUB", "path": "subscriberSettings.flowControlSettings.limitExceededBehavior", "type": "string", "val1": "Block", "val2": "Ignore" };
		defs["ccstestcloudconfigpubsubsubflowcontrolsettingsmaxoutstandingelementcount"] = { "setting": "CCSTestCloudConfigPubsubSubFlowControlSettingsMaxOutstandingElementCount", "service": "PUBSUB", "path": "subscriberSettings.flowControlSettings.maxOutstandingElementCount", "type": "number", "val1": "500", "val2": "1000" };
		defs["ccstestcloudconfigpubsubsubflowcontrolsettingsmaxoutstandingrequestbytes"] = { "setting": "CCSTestCloudConfigPubsubSubFlowControlSettingsMaxOutstandingRequestBytes", "service": "PUBSUB", "path": "subscriberSettings.flowControlSettings.maxOutstandingRequestBytes", "type": "number", "val1": "50000", "val2": "100000" };
		defs["ccstestcloudconfigpubsubuselegacyflowcontrol"] = { "setting": "CCSTestCloudConfigPubsubUseLegacyFlowControl", "service": "PUBSUB", "path": "subscriberSettings.useLegacyFlowControl", "type": "boolean", "val1": "true", "val2": "false" };
		return defs;
	}

	public boolean function hasFieldDefinition(required string settingName){
		return structKeyExists(getExpandedFieldDefinitions(), lCase(trim(arguments.settingName)));
	}

	public struct function getFieldDefinition(required string settingName){
		var defs = getExpandedFieldDefinitions();
		var key = lCase(trim(arguments.settingName));
		return structKeyExists(defs, key) ? defs[key] : {};
	}

	public string function getPresetValue(required string settingName, required any currentValue){
		var def = getFieldDefinition(arguments.settingName);
		if(structIsEmpty(def))
			return "";
		var cur = trim("" & arguments.currentValue);
		return (cur EQ def.val1) ? def.val2 : def.val1;
	}

	public string function getGenericCloudSetting(required string settingName){
		var def = getFieldDefinition(arguments.settingName);
		if(structIsEmpty(def))
			return "";
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfig(arguments.settingName);
			var cur = config;
			var parts = listToArray(def.path, ".");
			for(var p in parts){
				if(NOT isStruct(cur) OR NOT structKeyExists(cur, p))
					return "";
				cur = cur[p];
			}
			if(def.type == "boolean")
				return cur ? "true" : "false";
			if(def.type == "array")
				return (isArray(cur) AND arrayLen(cur)) ? trim("" & cur[1]) : "";
			return trim("" & cur);
		}
		catch(any e){
			if(findNoCase("does not exist", e.message) OR findNoCase("not found", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setGenericCloudSetting(required string settingName, required any settingValue){
		var def = getFieldDefinition(arguments.settingName);
		if(structIsEmpty(def))
			return "";
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteServiceConfigIfExists(runtime, arguments.settingName);
			if(len(value)){
				var payload = {
					"alias" = arguments.settingName,
					"serviceName" = def.service
				};
				if(def.service == "AZURE_BLOB"){
					payload["options"] = {
						"locationMode" = "PRIMARY_ONLY",
						"retryPolicyFactory" = {
							"retryPolicyType" = "LINEAR",
							"deltaBackoffIntervalInMs" = 100,
							"maximumAttempts" = 3
						}
					};
				}
				else if(def.service == "FIRESTORE"){
					payload["host"] = "firestore.googleapis.com:443";
				}
				else if(def.service == "STORAGE"){
					payload["host"] = "https://storage.googleapis.com";
					payload["storageRetryStrategy"] = "DEFAULT";
				}
				else if(def.service == "PUBSUB"){
					payload["subscriberSettings"] = {
						"maxAckExtensionPeriod" = "600s",
						"minDurationPerAckExtensionPeriod" = "10s",
						"maxDurationPerAckExtensionPeriod" = "60s",
						"flowControlSettings" = {
							"limitExceededBehavior" = "Block",
							"maxOutstandingElementCount" = 500,
							"maxOutstandingRequestBytes" = 50000
						}
					};
					if(findNoCase("batchingSettings", def.path) OR findNoCase("flowControlSettings", def.path)){
						payload["publisherSettings"] = {
							"batchingSettings" = {
								"flowControlSettings" = {
									"limitExceededBehavior" = "Ignore",
									"maxOutstandingElementCount" = 1000,
									"maxOutstandingRequestBytes" = 10000
								}
							}
						};
					}
				}

				var parts = listToArray(def.path, ".");
				var cur = payload;
				for(var i = 1; i < arrayLen(parts); i++){
					var p = parts[i];
					if(NOT structKeyExists(cur, p) OR NOT isStruct(cur[p]))
						cur[p] = {};
					cur = cur[p];
				}
				var lastKey = parts[arrayLen(parts)];
				if(def.type == "boolean")
					cur[lastKey] = (listFindNoCase("true,yes,1", value) GT 0);
				else if(def.type == "number")
					cur[lastKey] = val(value);
				else if(def.type == "array")
					cur[lastKey] = [value];
				else
					cur[lastKey] = value;

				runtime.api.addServiceConfig(payload);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getGenericCloudSetting(arguments.settingName);
	}

}
