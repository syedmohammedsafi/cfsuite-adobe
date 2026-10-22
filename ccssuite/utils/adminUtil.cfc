/**
* Admin API login helper — checks login result and supports CF 2025 username + password.
*/
component {

	public function init(){
		return this;
	}

	public any function createAdministrator(){
		return createObject("component", "CFIDE.adminapi.administrator");
	}

	/**
	* @return true when authenticated for this request
	*/
	public boolean function login(required struct cfConfig){
		var admin = createAdministrator();
		var password = cfConfig.CF_ADMIN_PASSWORD;
		var userId = structKeyExists(cfConfig, "CF_ADMIN_USERID") ? trim(cfConfig.CF_ADMIN_USERID) : "";
		if(NOT len(password))
			throw(message="CF_ADMIN_PASSWORD is empty in constants.cfc", type="CCSTest.ConfigError");

		var ok = false;
		if(len(userId))
			ok = admin.login(adminPassword=password, adminUserId=userId);
		else
			ok = admin.login(password);

		if(NOT ok){
			// Self-heal: if an interrupted test left the admin password as ccsTestAdminPass99, log in and restore to password
			var testPasswords = ["ccsTestAdminPass99", "admin"];
			for(var altPwd in testPasswords){
				var altOk = len(userId)
					? admin.login(adminPassword=altPwd, adminUserId=userId)
					: admin.login(altPwd);
				if(altOk){
					try {
						var ss = createObject("java", "coldfusion.server.ServiceFactory").getSecurityService();
						ss.setAdminPassword(password);
					} catch(any ex){}
					ok = true;
					break;
				}
			}
		}

		if(NOT ok){
			var who = len(userId) ? "user #userId#" : "administrator";
			throw(
				message="Admin API login failed for #who# — password in constants.cfc does not match CF Administrator.",
				detail="Log into http://localhost:#cgi.server_port#/CFIDE/administrator with the same username and password. Then update constants.cfc and add ?reinit=1 to any ccssuite URL.",
				type="CCSTest.AdminLoginFailed"
			);
		}
		return true;
	}

	public void function logout(required any admin){
		if(isObject(arguments.admin)){
			try { arguments.admin.logout(); } catch(any x) {}
		}
	}

}
