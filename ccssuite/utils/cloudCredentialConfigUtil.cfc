/**
* Data & Services > Cloud Credentials admin page: "Add/Edit Cloud Credentials" (Credential Alias).
*
* CFIDE.adminapi.cloud.addCredential()/deleteCredential() reliably create/delete entries in
* neo-cloudcredential.xml, keyed by alias (confirmed via direct testing). addCredential() takes a
* single struct argument — the field names are NOT what the admin UI labels suggest: confirmed via
* direct testing that the real keys are alias/vendorName/region/accessKeyId/secretAccessKey/
* sessionToken (e.g. "vendor" and "accessKey" are rejected as unknown fields). accessKeyId and
* secretAccessKey are auto-encrypted on disk once written, same as the mail/Solr Server password
* fields elsewhere in this suite.
*
* Multi-node via active push, not organic CCS replication: confirmed via direct testing that a
* newly-added credential never appears anywhere in the prime node's own CCS version history
* (bin/ccsstore/.../<version>/neo-cloudcredential.xml is never created for this file, unlike
* neo-mail.xml which gets a fresh version on every change) — so real CCS does not track this file
* at all in this environment, the same situation confirmed for Web Services' neo-xmlrpc.xml.
* serverSettingsApiUtil.requiresPeerInstancePropagation() flags the "cloudCredentials" area so
* testDriver.cfc actively re-applies the same addCredential()/deleteCredential() call on each peer
* node directly, instead of passively waiting on CCS.
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
	* Fixed test credential body used whenever the alias is (re-)created — the tracked value for
	* this test is the alias's presence/absence, not any of these field values.
	*/
	private struct function buildTestCredential(required string alias){
		return {
			"alias" = arguments.alias,
			"vendorName" = "AWS",
			"region" = "us-east-1",
			"accessKeyId" = "AKIACCSTESTFAKEKEY",
			"secretAccessKey" = "ccsTestFakeSecret99",
			"sessionToken" = ""
		};
	}

	/**
	* Azure's Cloud Vendor has a completely different field set than AWS's — confirmed via direct
	* testing that addCredential() accepts alias/vendorName="Azure"/connectionString and persists
	* correctly (no region/accessKeyId/secretAccessKey/sessionToken needed or used for this vendor).
	* connectionString is auto-encrypted on disk (confirmed directly, same as AWS's Access Key/
	* Secret Key) but getCredential() decrypts it back to the real plaintext on read, so field tests
	* against it can use a plain exact-match comparison.
	*/
	private struct function buildAzureTestCredential(required string alias){
		return {
			"alias" = arguments.alias,
			"vendorName" = "Azure",
			"connectionString" = "DefaultEndpointsProtocol=https;AccountName=ccstest;AccountKey=ccsTestFakeAzureKey99;EndpointSuffix=core.windows.net"
		};
	}

	/**
	* GCP's Cloud Vendor has its own field set too — confirmed via direct testing that
	* addCredential() accepts alias/vendorName="GCP"/projectId/credentialJsonFilepath and persists
	* correctly. Both projectId and credentialJsonFilepath are stored in PLAIN TEXT in
	* neo-cloudcredential.xml (confirmed directly for both) — projectId is an identifier and
	* credentialJsonFilepath is just a filesystem path, neither is the actual secret (that lives
	* inside the JSON file itself, which this admin page never reads) — so field tests against
	* either use a plain exact-match comparison same as Cloud Vendor/AWS Region/AWS Session Token.
	*/
	private struct function buildGcpTestCredential(required string alias){
		return {
			"alias" = arguments.alias,
			"vendorName" = "GCP",
			"projectId" = "ccs-test-project",
			"credentialJsonFilepath" = "C:\ccssuite-test\ccs-test-key.json"
		};
	}

	public string function getCloudCredentialAliasSetting(required string alias){
		var runtime = getRuntime();
		try {
			runtime.api.getCredential(arguments.alias);
			return arguments.alias;
		}
		catch(any e){
			if(findNoCase("does not exist", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudCredentialAliasSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteCredential(arguments.alias);
				}
				catch(any e){
					if(NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.addCredential(buildTestCredential(arguments.alias));
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudCredentialAliasSetting(arguments.alias);
	}

	private void function deleteCredentialIfExists(required struct runtime, required string alias){
		try {
			arguments.runtime.api.deleteCredential(arguments.alias);
		}
		catch(any e){
			if(NOT findNoCase("does not exist", e.message))
				rethrow;
		}
	}

	/**
	* "Cloud Vendor" field test: the tracked value is the vendorName string for a fixed, dedicated
	* test alias ("CCSTestCloudVendor" — kept separate from "CCSTestCloudCredential" used by the
	* Credential Alias test so the two tests never interfere with each other, the same convention
	* used elsewhere in this suite, e.g. Web Services' Auth Type test using its own registration
	* name rather than reusing the Web Service Name test's). Only AWS-shaped credential fields are
	* exercised here (this admin build's only selectable Cloud Vendor in this environment), so the
	* tracked value is the vendor's presence/absence for this alias rather than cycling between
	* multiple vendors' completely different field sets.
	*/
	public string function getCloudVendorSetting(required string alias){
		var runtime = getRuntime();
		try {
			var credential = runtime.api.getCredential(arguments.alias);
			return structKeyExists(credential, "vendorName") ? trim("" & credential.vendorName) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudVendorSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteCredentialIfExists(runtime, arguments.alias);
			if(len(value)){
				var credential = buildTestCredential(arguments.alias);
				credential.vendorName = value;
				runtime.api.addCredential(credential);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudVendorSetting(arguments.alias);
	}

	/**
	* "AWS Region" field test: the tracked value is the region string for a fixed, dedicated test
	* alias ("CCSTestCloudRegion" — kept separate from "CCSTestCloudCredential"/"CCSTestCloudVendor"
	* so none of the three tests interfere with each other). Same create/delete-whole-credential
	* pattern as Cloud Vendor: AWS Region is a required field, so there's no "existing credential
	* with a blank region" state to toggle in place — each run either has no credential (empty) or
	* a freshly (re)created one carrying the target region.
	*/
	public string function getCloudRegionSetting(required string alias){
		var runtime = getRuntime();
		try {
			var credential = runtime.api.getCredential(arguments.alias);
			return structKeyExists(credential, "region") ? trim("" & credential.region) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudRegionSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteCredentialIfExists(runtime, arguments.alias);
			if(len(value)){
				var credential = buildTestCredential(arguments.alias);
				credential.region = value;
				runtime.api.addCredential(credential);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudRegionSetting(arguments.alias);
	}

	/**
	* "AWS Access Key" field test: the tracked value is the accessKeyId string for a fixed,
	* dedicated test alias ("CCSTestCloudAccessKey" — kept separate from the other Cloud
	* Credentials field tests so none of them interfere with each other). accessKeyId is
	* auto-encrypted on disk (confirmed directly: neo-cloudcredential.xml stores it as an opaque
	* blob, not the plaintext set here) — but unlike mail's password field elsewhere in this suite,
	* CFIDE.adminapi.cloud.getCredential() decrypts it back to the real plaintext on read (confirmed
	* via direct testing), so this can use a plain exact-match comparison instead of the
	* changed-to-non-empty leniency mail's password test needs.
	*/
	public string function getCloudAccessKeySetting(required string alias){
		var runtime = getRuntime();
		try {
			var credential = runtime.api.getCredential(arguments.alias);
			return structKeyExists(credential, "accessKeyId") ? trim("" & credential.accessKeyId) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudAccessKeySetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteCredentialIfExists(runtime, arguments.alias);
			if(len(value)){
				var credential = buildTestCredential(arguments.alias);
				credential.accessKeyId = value;
				runtime.api.addCredential(credential);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudAccessKeySetting(arguments.alias);
	}

	/**
	* "AWS Secret Key" field test: the tracked value is the secretAccessKey string for a fixed,
	* dedicated test alias ("CCSTestCloudSecretKey" — kept separate from the other Cloud
	* Credentials field tests so none of them interfere with each other). Same encryption
	* situation as AWS Access Key: secretAccessKey is auto-encrypted on disk (confirmed directly),
	* but getCredential() decrypts it back to the real plaintext on read (confirmed via the same
	* probe used for AWS Access Key), so this uses a plain exact-match comparison.
	*/
	public string function getCloudSecretKeySetting(required string alias){
		var runtime = getRuntime();
		try {
			var credential = runtime.api.getCredential(arguments.alias);
			return structKeyExists(credential, "secretAccessKey") ? trim("" & credential.secretAccessKey) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudSecretKeySetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteCredentialIfExists(runtime, arguments.alias);
			if(len(value)){
				var credential = buildTestCredential(arguments.alias);
				credential.secretAccessKey = value;
				runtime.api.addCredential(credential);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudSecretKeySetting(arguments.alias);
	}

	/**
	* "AWS Session Token" field test: the tracked value is the sessionToken string for a fixed,
	* dedicated test alias ("CCSTestCloudSessionToken" — kept separate from the other Cloud
	* Credentials field tests so none of them interfere with each other). Unlike Access Key/Secret
	* Key, Session Token is optional (buildTestCredential defaults it to "") and, confirmed via
	* direct testing, is stored in PLAIN TEXT in neo-cloudcredential.xml — not auto-encrypted like
	* the other two credential fields — so this uses a plain exact-match comparison same as
	* Cloud Vendor/AWS Region.
	*/
	public string function getCloudSessionTokenSetting(required string alias){
		var runtime = getRuntime();
		try {
			var credential = runtime.api.getCredential(arguments.alias);
			return structKeyExists(credential, "sessionToken") ? trim("" & credential.sessionToken) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setCloudSessionTokenSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteCredentialIfExists(runtime, arguments.alias);
			if(len(value)){
				var credential = buildTestCredential(arguments.alias);
				credential.sessionToken = value;
				runtime.api.addCredential(credential);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getCloudSessionTokenSetting(arguments.alias);
	}

	/**
	* "Azure Connection String" field test: the tracked value is the connectionString string for a
	* fixed, dedicated test alias ("CCSTestAzureConnectionString" — kept separate from every AWS
	* field test so none of them interfere with each other). Uses buildAzureTestCredential() rather
	* than buildTestCredential(), since this is a full Azure-vendor credential, not an AWS one with
	* one field swapped.
	*/
	public string function getAzureConnectionStringSetting(required string alias){
		var runtime = getRuntime();
		try {
			var credential = runtime.api.getCredential(arguments.alias);
			return structKeyExists(credential, "connectionString") ? trim("" & credential.connectionString) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setAzureConnectionStringSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteCredentialIfExists(runtime, arguments.alias);
			if(len(value)){
				var credential = buildAzureTestCredential(arguments.alias);
				credential.connectionString = value;
				runtime.api.addCredential(credential);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getAzureConnectionStringSetting(arguments.alias);
	}

	/**
	* "GCP Project Id" field test: the tracked value is the projectId string for a fixed, dedicated
	* test alias ("CCSTestGcpProjectId" — kept separate from every other Cloud Credentials field
	* test so none of them interfere with each other). Uses buildGcpTestCredential() rather than
	* buildTestCredential()/buildAzureTestCredential(), since this is a full GCP-vendor credential.
	*/
	public string function getGcpProjectIdSetting(required string alias){
		var runtime = getRuntime();
		try {
			var credential = runtime.api.getCredential(arguments.alias);
			return structKeyExists(credential, "projectId") ? trim("" & credential.projectId) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setGcpProjectIdSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteCredentialIfExists(runtime, arguments.alias);
			if(len(value)){
				var credential = buildGcpTestCredential(arguments.alias);
				credential.projectId = value;
				runtime.api.addCredential(credential);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getGcpProjectIdSetting(arguments.alias);
	}

	/**
	* "GCP Credential JSON Filepath" field test: the tracked value is the credentialJsonFilepath
	* string for a fixed, dedicated test alias ("CCSTestGcpCredentialJsonFilepath" — kept separate
	* from every other Cloud Credentials field test so none of them interfere with each other).
	* Uses buildGcpTestCredential() same as GCP Project Id.
	*/
	public string function getGcpCredentialJsonFilepathSetting(required string alias){
		var runtime = getRuntime();
		try {
			var credential = runtime.api.getCredential(arguments.alias);
			return structKeyExists(credential, "credentialJsonFilepath") ? trim("" & credential.credentialJsonFilepath) : "";
		}
		catch(any e){
			if(findNoCase("does not exist", e.message))
				return "";
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setGcpCredentialJsonFilepathSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			deleteCredentialIfExists(runtime, arguments.alias);
			if(len(value)){
				var credential = buildGcpTestCredential(arguments.alias);
				credential.credentialJsonFilepath = value;
				runtime.api.addCredential(credential);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getGcpCredentialJsonFilepathSetting(arguments.alias);
	}
}
