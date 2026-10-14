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
}
