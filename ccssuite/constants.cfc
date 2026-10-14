component {

	function init(){
		this.CCS_CONFIG = {};
		this.CF_CONFIG = {};
		this.SYS_CONFIG = {};

		this.CCS_CONFIG["SERVER"] = "server";
		this.CCS_CONFIG["HOSTNAME"] = "hostname";
		this.CCS_CONFIG["PORT"] = "port";
		this.CCS_CONFIG["ENVIRONMENT"] = "environment";
		this.CCS_CONFIG["CURRENT_VERSION"] = "currentversion";
		this.CCS_CONFIG["CLUSTER"] = "cluster";
		this.CCS_CONFIG["ENABLED"] = "enabled";
		this.CCS_CONFIG["JEE_CONTEXT"] = "jeecontext";

		// Must match CF Administrator login
		this.CF_CONFIG["CF_ADMIN_USERID"] = "admin";
		this.CF_CONFIG["CF_ADMIN_PASSWORD"] = "password";
		this.CF_CONFIG["HTTP_STATUS_CODE_SUCCESS"] = "200 OK";

		this.SYS_CONFIG["FILE_SEPARATOR"] = findNoCase("windows", server.os.name) ? "\" : "/";

		return this;
	}

}