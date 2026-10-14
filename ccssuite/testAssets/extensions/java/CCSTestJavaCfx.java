import com.allaire.cfx.CustomTag;
import com.allaire.cfx.Request;
import com.allaire.cfx.Response;

public class CCSTestJavaCfx implements CustomTag {
	public void processRequest(Request request, Response response) throws Exception {
		String name = request.getAttribute("NAME");
		if(name == null || name.length() == 0)
			name = "CF";
		response.write("CCSTestJavaCfx:" + name);
	}
}
