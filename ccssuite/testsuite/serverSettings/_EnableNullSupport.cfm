


<cfscript>
try{
import CFIDE.adminapi.*;

        //create the required CFCs
        admin = new administrator();
        runtime = new runtime();

        //login as admin to invoke the CFC API's
        admin.login("Adm1n$");

       writeoutput(runtime.setRuntimeProperty("enableNullSupport","true"));
	writeoutput(runtime.getRuntimeProperty("enableNullSupport"));
	}
	catch(any e ){
	
		writedump(e);
	}
		
</cfscript>

