import com.allaire.cfx.CustomTag;
import com.allaire.cfx.Request;
import com.allaire.cfx.Response;

public class CCSTestJavaCfxAlt implements CustomTag {
	public void processRequest(Request request, Response response) throws Exception {
		response.write("CCSTestJavaCfxAlt");
	}
}
