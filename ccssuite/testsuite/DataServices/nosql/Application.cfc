component output="false" {
        this.name = "ccs-nosql-regression";
        this.enableRobustException = false;

        public boolean function onApplicationStart(){
                application.constants = new cfsuite.ccssuite.constants().init();
                application.testConstants = new cfsuite.ccssuite.testConstants().init();
                application.protocol = lCase(CGI.HTTPS) EQ "on" ? "https" : "http";
                application.ccsTestNodesScope = "currentPort";
                return true;
        }

        public void function onError(required any exception, required string eventName){
                cfheader(statusCode=500);
                cfcontent(type="text/plain", reset=true);
                writeOutput("NoSQL request failed; configuration and exception details withheld.");
        }
}