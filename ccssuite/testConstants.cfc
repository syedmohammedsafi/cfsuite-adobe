component {

	function init(){
		fileSeparator = findNoCase("windows", server.os.name) ? "\" : "/";
		
		this.TEST_FRAME = {};
		this.TEST_FRAME["CFSETTING"] = "setting";
		this.TEST_FRAME["SETTER_URL"] = "setUrl";
		this.TEST_FRAME["GETTER_URL"] = "getUrl";
		this.TEST_FRAME["PRIME_SET"] = "primeSet";
		this.TEST_FRAME["NONPRIME_SET"] = "nonPrimeSet";
		this.TEST_FRAME["PRIME_NODES_KEYLIST"] = "primeNodesKeys";
		this.TEST_FRAME["PRESET_VALUE"] = "preSetValue";
		this.TEST_FRAME["POSTSET_VALUE"] = "postSetValue";
		this.TEST_FRAME["API_AREA"] = "apiArea";

		this.TEST_FRAME["COMPOSITE_KEY_FIELD_SEPARATOR"] = "::";
		return this;
	}

}