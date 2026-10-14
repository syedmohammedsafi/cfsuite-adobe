<cf_qatest id="t1">

<cfscript>
try{
import CFIDE.adminapi.*;

        //create the required CFCs
        admin = new administrator();
        runtime = new runtime();

        //login as admin to invoke the CFC API's
        admin.login("Adm1n$");

       writeoutput(runtime.setRuntimeProperty("postSizeLimit","25"));
	writeoutput(runtime.getRuntimeProperty("postSizeLimit"));
	}
	catch(any e ){
	
		writedump(e);
	}
		
</cfscript>

<cf_expectedresults>
25
</cf_expectedresults>
</cf_qatest>
<cf_qatest id="t2">

<cfscript>
try{
import CFIDE.adminapi.*;

        //create the required CFCs
        admin = new administrator();
        runtime = new runtime();

        //login as admin to invoke the CFC API's
        admin.login("Adm1n$");

       writeoutput(runtime.setRuntimeProperty("postParametersLimit","95"));
	writeoutput(runtime.getRuntimeProperty("postParametersLimit"));
	}
	catch(any e ){
	
		writedump(e);
	}
		
</cfscript>

<cf_expectedresults>
95
</cf_expectedresults>
</cf_qatest>
<cf_qatest id="t4">

<cfscript>
try{
import CFIDE.adminapi.*;

        //create the required CFCs
        admin = new administrator();
        runtime = new runtime();

        //login as admin to invoke the CFC API's
        admin.login("Adm1n$");

       writeoutput(runtime.setRuntimeProperty("requestThrottleThreshold","5"));
	writeoutput(runtime.getRuntimeProperty("requestThrottleThreshold"));
	}
	catch(any e ){
	
		writedump(e);
	}
		
</cfscript>

<cf_expectedresults>
5
</cf_expectedresults>
</cf_qatest>
<cf_qatest id="t3">

<cfscript>
try{
import CFIDE.adminapi.*;

        //create the required CFCs
        admin = new administrator();
        runtime = new runtime();

        //login as admin to invoke the CFC API's
        admin.login("Adm1n$");

       writeoutput(runtime.setRuntimeProperty("requestThrottleMemory","205"));
	writeoutput(runtime.getRuntimeProperty("requestThrottleMemory"));
	}
	catch(any e ){
	
		writedump(e);
	}
		
</cfscript>

<cf_expectedresults>
205
</cf_expectedresults>
</cf_qatest>

<cf_qatestENd stats="true">