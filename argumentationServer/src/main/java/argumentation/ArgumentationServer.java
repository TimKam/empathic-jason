package main.java.argumentation;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import com.google.gson.*;
import fi.iki.elonen.NanoHTTPD;

import net.sf.tweety.arg.dung.CompleteReasoner;
import net.sf.tweety.arg.dung.DungTheory;
import net.sf.tweety.arg.dung.semantics.Extension;
import net.sf.tweety.arg.dung.syntax.Argument;
import net.sf.tweety.arg.dung.syntax.Attack;
import net.sf.tweety.logics.pl.sat.Sat4jSolver;
import net.sf.tweety.logics.pl.sat.SatSolver;

public class ArgumentationServer extends NanoHTTPD {
    JsonParser parser = new JsonParser();

    public ArgumentationServer() throws IOException {
        super(8080);
        start(NanoHTTPD.SOCKET_READ_TIMEOUT, false);
        System.out.println("\nRunning! Point your browsers to http://localhost:8080/ \n");
    }

    public static void main(String[] args) {
        try {
            new ArgumentationServer();
        } catch (IOException ioe) {
            System.err.println("Couldn't start server:\n" + ioe);
        }
    }

    @Override
    public Response serve(IHTTPSession session) {
        DungTheory theory = new DungTheory();
        Map<String, String> params = session.getParms();
        Map<String, Argument> arguments = new HashMap<>();
        for (Map.Entry<String, String> param : params.entrySet()) {
            String argumentId = param.getKey();
            System.out.println("Creating argument: " + argumentId);
            arguments.put(argumentId, new Argument(argumentId));
            theory.add(arguments.get(argumentId));
        }

        for (Map.Entry<String, String> param : params.entrySet()) {
            String argumentId = param.getKey();
            System.out.println("Launching attacks for argument: " + argumentId);
            JsonArray jAttacks = parser.parse(param.getValue()).getAsJsonArray();
            for (JsonElement jAttackedArg : jAttacks) {
                String attackedArg = jAttackedArg.getAsString();
                System.out.println("Attacking: " + attackedArg);
                theory.add(new Attack(arguments.get(argumentId), arguments.get(attackedArg)));
            }
        }

        System.out.println(theory);
        System.out.println();

        SatSolver.setDefaultSolver(new Sat4jSolver());

        Set<Extension> completeExtensions = new CompleteReasoner(theory).getExtensions();
        JsonArray jCompleteExtensions = new JsonArray();
        for (Extension extension : completeExtensions) {
            JsonArray jExtension = new JsonArray();
            for (Argument argument : extension) {
                jExtension.add(argument.toString());
            }
            jCompleteExtensions.add(jExtension);
        }
        System.out.println("Complete extensions: " + completeExtensions);

        return newFixedLengthResponse(jCompleteExtensions.toString());
    }
}