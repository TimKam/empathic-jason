package main.java.argumentation;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Collection;

import com.google.gson.*;
import fi.iki.elonen.NanoHTTPD;

import net.sf.tweety.arg.dung.reasoner.AbstractExtensionReasoner;
import net.sf.tweety.arg.dung.reasoner.SimpleCompleteReasoner;
import net.sf.tweety.arg.dung.reasoner.SimpleGroundedReasoner;
import net.sf.tweety.arg.dung.reasoner.SimpleIdealReasoner;
import net.sf.tweety.arg.dung.reasoner.SimplePreferredReasoner;
import net.sf.tweety.arg.dung.reasoner.SimpleStableReasoner;
import net.sf.tweety.arg.dung.reasoner.SimpleSemiStableReasoner;
import net.sf.tweety.arg.dung.semantics.Extension;
import net.sf.tweety.arg.dung.syntax.Argument;
import net.sf.tweety.arg.dung.syntax.Attack;
import net.sf.tweety.arg.dung.syntax.DungTheory;
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

    private enum ExtensionType {
        complete, ground, ideal, stable, semiStable, preferred;
    }

    private static Collection<Extension> getExtensions (String sExtensionType, DungTheory theory) {
        if(sExtensionType == null) {
            sExtensionType = "preferred";
        }
        System.out.println("Extension type: " + sExtensionType);
        ExtensionType extensionType = ExtensionType.valueOf(sExtensionType);
        switch (extensionType) {
            case complete:
                return new SimpleCompleteReasoner().getModels(theory);
            case ground:
                return new SimpleGroundedReasoner().getModels(theory);
            case ideal:
                return new SimpleIdealReasoner().getModels(theory);
            case stable:
                return new SimpleStableReasoner().getModels(theory);
            case semiStable:
                return new SimpleSemiStableReasoner().getModels(theory);
            case preferred:
            default:
                return new SimplePreferredReasoner().getModels(theory);
        }
    }

    @Override
    public Response serve(IHTTPSession session) {
        DungTheory theory = new DungTheory();
        Map<String, String> params = session.getParms();
        String extensionType = params.remove("extensionType");
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
        System.out.println("Extension type: " + extensionType);
        Collection<Extension> extensions = getExtensions(extensionType, theory);
        System.out.println("Extensions, type " + extensionType + ": " + extensions);

        JsonArray jExtensions = new JsonArray();
        for (Extension extension : extensions) {
            JsonArray jExtension = new JsonArray();
            for (Argument argument : extension) {
                jExtension.add(argument.toString());
            }
            jExtensions.add(jExtension);
        }
        System.out.println("Extensions, type " + extensionType + ": " + extensions);

        return newFixedLengthResponse(jExtensions.toString());
    }
}