/**
* Data & Services > GraphQL admin page: "GraphQL Client Configuration" (Configuration Alias) and
* "GraphQL Service Configuration" (Service Name).
*
* SERVICE CONFIGURATIONS ARE IN-MEMORY ONLY, NOT FILE-PERSISTED: confirmed via direct testing —
* a registered service (e.g. the "CCSTestGraphqlService" fixture below) is retrievable via
* getServiceConfiguration() across many separate requests, yet never appears as its own entry
* anywhere in neo-graphql-config.xml or its CCS version history (bin/ccsstore/.../<version>/
* neo-graphql-config.xml only ever records CLIENT configuration ADDITION/DELETION entries). This
* is a genuine difference from Client Configurations, which ARE file-persisted. Since active push
* calls setServiceConfiguration()/deleteServiceConfiguration() directly on each node's own request
* (not relying on any file replication), this doesn't block using the same active-push mechanism —
* it just means a Service Configuration test's "existing value" is scoped to the current JVM's
* uptime on each node, same as any other in-memory admin API state this suite already deals with.
*
* CFIDE.adminapi.graphql.setClientConfiguration()/getClientConfiguration()/
* deleteClientConfiguration() reliably create/read/delete entries in neo-graphql-config.xml, keyed
* by client name (confirmed via direct testing). setClientConfiguration() takes named arguments,
* not a struct — CLIENT_NAME and SERVICE_NAME (confirmed via direct testing; a struct argument is
* rejected with "CLIENT_NAME argument ... not of type String").
*
* setClientConfiguration() validates that SERVICE_NAME refers to an already-registered GraphQL
* Service Configuration ("Specified service config doesn't exist" otherwise) — unlike Cloud
* Credentials/Cloud Configuration, a Client Configuration can't be registered standalone. A
* dedicated test Service Configuration ("CCSTestGraphqlService") is lazily created on whichever
* node runs the set, satisfying this requirement without needing a real reachable GraphQL endpoint
* — confirmed via direct testing that setServiceConfiguration() does NOT attempt to reach
* SERVICE_URL (unlike Web Services' setWebService(), which fetches the WSDL and hangs/fails on an
* unreachable one); it just validates required parameters and stores the values.
*
* Multi-node via active push, not organic CCS replication: confirmed via direct testing that a
* newly-added client configuration creates a real CCS version on the prime node
* (bin/ccsstore/.../<version>/neo-graphql-config.xml with an "ADDITION" changes.txt entry — so CCS
* does register the change, unlike Cloud Credentials where no version is ever created at all) but
* never appears in a peer node's own neo-graphql-config.xml even after ~80 seconds of direct
* polling, with no error logged on the peer either. So this needs the same active-push mechanism
* used for Cloud Credentials/Web Services/AI Services/extensions/security, rather than passively
* waiting on CCS.
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
			api = createObject("component", "CFIDE.adminapi.graphql")
		};
	}

	variables.TEST_SERVICE_NAME = "CCSTestGraphqlService";

	/**
	* setClientConfiguration() requires an already-registered service to point at. Idempotently
	* ensures a dedicated test service config exists on whichever node this runs on — created fresh
	* per-node rather than relying on it being synced/shared, since this util has no reliable way to
	* know a peer node's replication state at set-time.
	*/
	private void function ensureTestServiceConfigPresent(required struct runtime){
		// getServiceConfiguration() does NOT throw for a missing name (unlike getClientConfiguration) —
		// confirmed via direct testing that it returns null instead, so existence must be checked
		// with isNull() rather than try/catch.
		var existing = arguments.runtime.api.getServiceConfiguration(variables.TEST_SERVICE_NAME);
		if(isNull(existing)){
			try {
				arguments.runtime.api.setServiceConfiguration(
					SERVICE_NAME = variables.TEST_SERVICE_NAME,
					SERVICE_URL = "http://localhost/ccssuite-test/schema.graphql",
					ROOT_PACKAGE_NAME = "root"
				);
			}
			catch(any e){
				// setServiceConfiguration() is NOT idempotent — confirmed via direct testing that a
				// second call for the same name throws "already exists" rather than updating/no-op'ing.
				// The check above is check-then-act, not atomic, so a second concurrent caller on this
				// same node (e.g. two overlapping test runs) can lose this exact race; the desired end
				// state (service present) is still achieved either way, so this is safe to swallow.
				if(NOT findNoCase("already exists", e.message))
					rethrow;
			}
		}
	}

	public string function getGraphqlClientAliasSetting(required string alias){
		var runtime = getRuntime();
		try {
			runtime.api.getClientConfiguration(arguments.alias);
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

	public string function setGraphqlClientAliasSetting(required string alias, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteClientConfiguration(arguments.alias);
				}
				catch(any e){
					if(NOT findNoCase("does not exist", e.message) AND NOT findNoCase("not found", e.message))
						rethrow;
				}
			}
			else {
				ensureTestServiceConfigPresent(runtime);
				runtime.api.setClientConfiguration(CLIENT_NAME=arguments.alias, SERVICE_NAME=variables.TEST_SERVICE_NAME);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getGraphqlClientAliasSetting(arguments.alias);
	}

	/**
	* "Service Name" field test: the tracked value is a dedicated test service name
	* ("CCSTestGraphqlServiceName" — kept separate from "CCSTestGraphqlService", the fixture used
	* internally by the Configuration Alias test, so the two never interfere with each other).
	* deleteServiceConfiguration() throws "Servicename absent in Config." for a missing name
	* (confirmed via direct testing) and setServiceConfiguration() throws "already exists" for a
	* duplicate (confirmed via direct testing, same non-idempotent behavior as the fixture above) —
	* both are swallowed here for the same reason: this util has no atomic check-then-act guarantee
	* against a second overlapping caller, and the desired end state is reached either way.
	*/
	public string function getGraphqlServiceNameSetting(required string serviceName){
		var runtime = getRuntime();
		try {
			var existing = runtime.api.getServiceConfiguration(arguments.serviceName);
			return isNull(existing) ? "" : arguments.serviceName;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setGraphqlServiceNameSetting(required string serviceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteServiceConfiguration(arguments.serviceName);
				}
				catch(any e){
					if(NOT findNoCase("absent", e.message) AND NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				try {
					runtime.api.setServiceConfiguration(
						SERVICE_NAME = arguments.serviceName,
						SERVICE_URL = "http://localhost/ccssuite-test/schema.graphql",
						ROOT_PACKAGE_NAME = "root"
					);
				}
				catch(any e){
					if(NOT findNoCase("already exists", e.message))
						rethrow;
				}
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getGraphqlServiceNameSetting(arguments.serviceName);
	}

	/**
	* "Root Package Name" field test: the tracked value is the root_package_name string for a
	* fixed, dedicated test service — the settingName passed in ("CCSTestGraphqlRootPackage", kept
	* separate from "CCSTestGraphqlService"/"CCSTestGraphqlServiceName" used by the other two
	* GraphQL tests) doubles as that service's identity, the same convention Cloud Credentials'
	* field tests use (e.g. "CCSTestCloudRegion"). ROOT_PACKAGE_NAME is a required field with no
	* blank state, so this cycles between two values ("root"/"rootPackage2") using the same
	* delete-then-recreate pattern as Cloud Configuration's Service Name field test, rather than
	* toggling presence/absence.
	*/
	public string function getGraphqlRootPackageNameSetting(required string serviceName){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfiguration(arguments.serviceName);
			return (isNull(config) OR NOT structKeyExists(config, "root_package_name")) ? "" : trim("" & config.root_package_name);
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setGraphqlRootPackageNameSetting(required string serviceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			try {
				runtime.api.deleteServiceConfiguration(arguments.serviceName);
			}
			catch(any e){
				if(NOT findNoCase("absent", e.message) AND NOT findNoCase("does not exist", e.message))
					rethrow;
			}
			if(len(value)){
				try {
					runtime.api.setServiceConfiguration(
						SERVICE_NAME = arguments.serviceName,
						SERVICE_URL = "http://localhost/ccssuite-test/schema.graphql",
						ROOT_PACKAGE_NAME = value
					);
				}
				catch(any e){
					if(NOT findNoCase("already exists", e.message))
						rethrow;
				}
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getGraphqlRootPackageNameSetting(arguments.serviceName);
	}

	/**
	* "Schema Path" field test: the tracked value is the schema_path string for a fixed, dedicated
	* test service ("CCSTestGraphqlSchemaPath" — kept separate from "CCSTestGraphqlService"/
	* "CCSTestGraphqlServiceName"/"CCSTestGraphqlRootPackage" used by the other GraphQL tests).
	*
	* "Schema Path Enabled" itself has NO backend representation — confirmed via direct testing
	* (dumping the complete, unfiltered key list of a schema-path-based service config returns only
	* service_name/root_package_name/schema_path; no enabled/schemaPathEnabled key exists in any
	* casing) and via the real admin UI source (CFIDE/administrator/graphql/service.cfm's
	* gql_schemaPathEnabled variable is used purely client-side, to decide whether the form sends
	* SCHEMA_PATH or SERVICE_URL — it's never itself transmitted to or stored by the backend).
	* SCHEMA_PATH and SERVICE_URL are mutually exclusive on the wire: a service created with
	* SCHEMA_PATH set (and no SERVICE_URL) persists and reads back correctly on its own, which is
	* what this test actually exercises — the real, storable setting behind the checkbox.
	*/
	public string function getGraphqlSchemaPathSetting(required string serviceName){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfiguration(arguments.serviceName);
			return (isNull(config) OR NOT structKeyExists(config, "schema_path")) ? "" : trim("" & config.schema_path);
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setGraphqlSchemaPathSetting(required string serviceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			try {
				runtime.api.deleteServiceConfiguration(arguments.serviceName);
			}
			catch(any e){
				if(NOT findNoCase("absent", e.message) AND NOT findNoCase("does not exist", e.message))
					rethrow;
			}
			if(len(value)){
				try {
					runtime.api.setServiceConfiguration(
						SERVICE_NAME = arguments.serviceName,
						SCHEMA_PATH = value,
						ROOT_PACKAGE_NAME = "root"
					);
				}
				catch(any e){
					if(NOT findNoCase("already exists", e.message))
						rethrow;
				}
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getGraphqlSchemaPathSetting(arguments.serviceName);
	}

	/**
	* "Service URL" field test: the tracked value is the service_url string for a fixed, dedicated
	* test service ("CCSTestGraphqlServiceUrl" — kept separate from the other GraphQL test
	* fixtures). Mirrors Schema Path's test exactly, just for the other side of that mutually
	* exclusive pair — confirmed via direct testing that setServiceConfiguration() does not attempt
	* to reach SERVICE_URL, so a fake, unreachable URL is safe here (no hang/reachability risk,
	* unlike Web Services' setWebService()).
	*/
	public string function getGraphqlServiceUrlSetting(required string serviceName){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfiguration(arguments.serviceName);
			return (isNull(config) OR NOT structKeyExists(config, "service_url")) ? "" : trim("" & config.service_url);
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setGraphqlServiceUrlSetting(required string serviceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			try {
				runtime.api.deleteServiceConfiguration(arguments.serviceName);
			}
			catch(any e){
				if(NOT findNoCase("absent", e.message) AND NOT findNoCase("does not exist", e.message))
					rethrow;
			}
			if(len(value)){
				try {
					runtime.api.setServiceConfiguration(
						SERVICE_NAME = arguments.serviceName,
						SERVICE_URL = value,
						ROOT_PACKAGE_NAME = "root"
					);
				}
				catch(any e){
					if(NOT findNoCase("already exists", e.message))
						rethrow;
				}
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getGraphqlServiceUrlSetting(arguments.serviceName);
	}

	/**
	* "Schema Path Enabled" field test: for a fixed, dedicated test service
	* ("CCSTestGraphqlSchemaPathEnabled" — kept separate from the other GraphQL test fixtures),
	* tracks whether the service is currently registered in "schema path mode" (schema_path
	* populated, no service_url) versus "service URL mode" (service_url populated, no schema_path).
	* This mutual exclusivity IS the real, persisted expression of the admin UI's "Schema Path
	* Enabled" checkbox — confirmed via direct testing that no literal enabled/schemaPathEnabled
	* boolean field exists anywhere in the stored config (see getGraphqlSchemaPathSetting's doc
	* comment above for the full evidence). There is no dedicated boolean to read/write, so this
	* cycles "true" (schema path mode) / "false" (service URL mode) by recreating the whole service
	* with whichever field corresponds each time, rather than flipping a stored flag.
	*/
	public string function getGraphqlSchemaPathEnabledSetting(required string serviceName){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfiguration(arguments.serviceName);
			if(isNull(config))
				return "";
			return structKeyExists(config, "schema_path") ? "true" : "false";
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setGraphqlSchemaPathEnabledSetting(required string serviceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			try {
				runtime.api.deleteServiceConfiguration(arguments.serviceName);
			}
			catch(any e){
				if(NOT findNoCase("absent", e.message) AND NOT findNoCase("does not exist", e.message))
					rethrow;
			}
			if(len(value)){
				var schemaPathEnabled = listFindNoCase("true,yes,1", value) GT 0;
				try {
					if(schemaPathEnabled){
						runtime.api.setServiceConfiguration(
							SERVICE_NAME = arguments.serviceName,
							SCHEMA_PATH = "schema/ccsTestEnabledPath.json",
							ROOT_PACKAGE_NAME = "root"
						);
					}
					else {
						runtime.api.setServiceConfiguration(
							SERVICE_NAME = arguments.serviceName,
							SERVICE_URL = "http://localhost/ccssuite-test/schema.graphql",
							ROOT_PACKAGE_NAME = "root"
						);
					}
				}
				catch(any e){
					if(NOT findNoCase("already exists", e.message))
						rethrow;
				}
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getGraphqlSchemaPathEnabledSetting(arguments.serviceName);
	}

	variables.TEST_HEADER_KEY = "CCSTestHeaderKey";
	variables.TEST_HEADER_VALUE = "ccsTestHeaderValue";

	/**
	* "Header Key" field test (HTTP Headers section of Add GraphQL Service Configuration): the
	* tracked value is the presence/absence of a fixed test header key ("CCSTestHeaderKey", mapped
	* to a fixed value "ccsTestHeaderValue") in the HEADERS struct of a fixed, dedicated test
	* service ("CCSTestGraphqlHeaderKey" — kept separate from the other GraphQL test fixtures).
	* Confirmed via direct testing that HEADERS is a real, storable struct parameter on
	* setServiceConfiguration() — round-trips exactly as given (e.g. {Authorization: "Bearer ..."})
	* — unlike setClientConfiguration(), where passing HEADERS is silently accepted but never
	* persisted (confirmed via direct testing: the returned client config never includes a headers
	* key when set this way, even though a client created through the real admin UI can have one —
	* that entry is populated by some other path this suite doesn't need to reproduce here, since
	* this test only needs the Service Configuration's own well-behaved HEADERS parameter).
	*/
	public string function getGraphqlHeaderKeySetting(required string serviceName){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfiguration(arguments.serviceName);
			if(isNull(config) OR NOT structKeyExists(config, "headers") OR NOT isStruct(config.headers))
				return "";
			return structKeyExists(config.headers, variables.TEST_HEADER_KEY) ? variables.TEST_HEADER_KEY : "";
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setGraphqlHeaderKeySetting(required string serviceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			try {
				runtime.api.deleteServiceConfiguration(arguments.serviceName);
			}
			catch(any e){
				if(NOT findNoCase("absent", e.message) AND NOT findNoCase("does not exist", e.message))
					rethrow;
			}
			if(len(value)){
				var headers = {};
				headers[variables.TEST_HEADER_KEY] = variables.TEST_HEADER_VALUE;
				try {
					runtime.api.setServiceConfiguration(
						SERVICE_NAME = arguments.serviceName,
						SERVICE_URL = "http://localhost/ccssuite-test/schema.graphql",
						ROOT_PACKAGE_NAME = "root",
						HEADERS = headers
					);
				}
				catch(any e){
					if(NOT findNoCase("already exists", e.message))
						rethrow;
				}
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getGraphqlHeaderKeySetting(arguments.serviceName);
	}

	/**
	* "Header Value" field test (HTTP Headers section of Add GraphQL Service Configuration): the
	* tracked value is the VALUE mapped to a fixed test header key ("CCSTestHeaderKey") in the
	* HEADERS struct of a fixed, dedicated test service ("CCSTestGraphqlHeaderValue" — kept separate
	* from "CCSTestGraphqlHeaderKey" and the other GraphQL test fixtures so none interfere with each
	* other). Cycles the value ("ccsTestHeaderValue1"/"ccsTestHeaderValue2") using the same
	* delete-then-recreate pattern as Root Package Name / Service URL, rather than toggling
	* presence/absence — same HEADERS behavior confirmed for the Header Key test above applies here.
	*/
	public string function getGraphqlHeaderValueSetting(required string serviceName){
		var runtime = getRuntime();
		try {
			var config = runtime.api.getServiceConfiguration(arguments.serviceName);
			if(isNull(config) OR NOT structKeyExists(config, "headers") OR NOT isStruct(config.headers))
				return "";
			return structKeyExists(config.headers, variables.TEST_HEADER_KEY) ? trim("" & config.headers[variables.TEST_HEADER_KEY]) : "";
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setGraphqlHeaderValueSetting(required string serviceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			try {
				runtime.api.deleteServiceConfiguration(arguments.serviceName);
			}
			catch(any e){
				if(NOT findNoCase("absent", e.message) AND NOT findNoCase("does not exist", e.message))
					rethrow;
			}
			if(len(value)){
				var headers = {};
				headers[variables.TEST_HEADER_KEY] = value;
				try {
					runtime.api.setServiceConfiguration(
						SERVICE_NAME = arguments.serviceName,
						SERVICE_URL = "http://localhost/ccssuite-test/schema.graphql",
						ROOT_PACKAGE_NAME = "root",
						HEADERS = headers
					);
				}
				catch(any e){
					if(NOT findNoCase("already exists", e.message))
						rethrow;
				}
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getGraphqlHeaderValueSetting(arguments.serviceName);
	}
}
