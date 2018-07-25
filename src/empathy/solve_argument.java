// Internal action code for project empathic_example.mas2j

package empathy;

import jason.*;
import jason.asSemantics.*;
import jason.asSyntax.*;

import org.apache.http.*;
import org.apache.http.client.HttpClient;
import org.apache.http.client.ResponseHandler;
import org.apache.http.impl.client.BasicResponseHandler;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.client.utils.URIBuilder;
import org.apache.http.client.methods.*;

import com.google.gson.*;

import java.util.List;

public class solve_argument extends DefaultInternalAction {

    @Override
    public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
        // execute the internal action
        HttpClient client = new DefaultHttpClient();
        URIBuilder builder = new URIBuilder("http://localhost:8080");
        JsonParser parser = new JsonParser();

        ListTerm tArguments = (ListTerm) args[0];
        Term handoverArg = args[1];
        // construct request
        ListTerm tValidArgumentNames = ListTermImpl.parseList("[]");
        for (Term tArgument : tArguments) {
            ListTerm tExtension = (ListTerm) tArgument;
            List<Term> lExtension = tExtension.getAsList();
            String argName = lExtension.get(0).toString()
                    .replaceAll("^\"|\"$", "")
                    .replaceAll("\"", "\\\"");
            System.out.println(argName);
            tValidArgumentNames.append(lExtension.get(0));
            lExtension.remove(0);
            String arguments = tExtension.get(1).toString();
            builder.setParameter(argName, arguments);
        }

        ts.getAg().getLogger().info("executing internal action 'empathy.solve_argument'");
        if (false) { // just to show how to throw another kind of exception
            throw new JasonException("not implemented!");
        }

        HttpGet request = new HttpGet(builder.build());
        ResponseHandler<String> handler = new BasicResponseHandler();
        // send request and handle response
        HttpResponse response = client.execute(request);
        System.out.println("Response code: "
                + response.getStatusLine().getStatusCode());
        String body = handler.handleResponse(response);
        System.out.println("Response body: "
                + body);
        JsonArray jBody = parser.parse(body).getAsJsonArray();
        ListTerm tCompleteExtensions = ListTermImpl.parseList("[]");
        for (JsonElement jArgs : jBody) {
            ListTerm tExtension = ListTermImpl.parseList("[]");
            for (JsonElement jArg : jArgs.getAsJsonArray()) {
                StringTerm tArg = StringTermImpl.parseString(jArg.toString());
                tExtension.append(tArg);
            }
            tCompleteExtensions.append(tExtension);
        }

        for (Term tExtension : tCompleteExtensions) {
            for (Term arg : (ListTerm) tExtension) {
                tValidArgumentNames.remove(arg);
            }
        }
        return un.unifies(tValidArgumentNames, handoverArg);
    }
}