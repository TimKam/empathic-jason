// initial beliefs
benefit(-100, "Show vodka ad").
benefit(-5, "Show steak ad").
benefit(10, "Show university ad").
benefit(2, "Show community college ad").
acceptable("Show university ad", "Show community college ad").
acceptable("Show community college ad", "Show university ad").
attack("Show vodka ad", "Alcoholic").

/***Rules**/
// acceptability check
is_acceptable(PersuaderAction, MitigatorAction) :-
    .findall(_, acceptable(PersuaderAction, MitigatorAction), Res)
    & .length(Res, Length)
    & Length > 0.

// argument existence check
does_exist(Name) :-
    .findall(_, argument(Name, _), Res)
    & .length(Res, Length)
    & Length > 0.

/***Plans***/
/* wait for persuader's utility mapping
   respond with own mapping
   compute compromise */
+announce(utility, ReceivedUtility)[source(A)] <- .print("Received utility mapping: ", ReceivedUtility)
    .findall(benefit(X, Y), benefit(X, Y), OwnUtility);
    +firstReponse("")
    .send(A, tell, respond(OwnUtility))
    for (.member(Revenue, ReceivedUtility)) {
        +Revenue
    }
    .findall(benefit(X, Y), benefit(X, Y), OwnUtility)
    .max(OwnUtility, benefit(OwnMaxUtility, OwnAction))
    .findall(revenue(X, Y), revenue(X, Y), OtherUtility)
    .max(OtherUtility, revenue(OtherMaxUtility, OtherAction))
    .print("Own best action: ", OwnAction)
    .print("Other's best action: ", OtherAction)
    if (OwnAction == OtherAction) {
        .print("Prefer executing: ", OwnAction);
        +approvedAction(OwnAction)
    } else {
        if(is_acceptable(OtherAction, OwnAction)) {
            .print("Other's best action acceptable");
            +approvedAction(OtherAction)
        } else {
            .print("Other's best action not acceptable")
            .findall(Name, benefit(Value, Name), Actions)
            for(.member(Action, Actions)){
                .findall(Value, benefit(Value, Action), OwnValues)
                .nth(0, OwnValues, OwnValue)
                .findall(Value, revenue(Value, Action), OtherValues)
                .nth(0, OtherValues, OtherValue)
                if(OtherValue < 0 & OwnValue > 0) {
                    +combinedUtility(OtherValue / OwnValue, Action)
                } elif(OtherValue > 0 & OwnValue < 0) {
                    +combinedUtility(OwnValue / OtherValue, Action)
                } elif(OtherValue < 0 & OwnValue < 0) {
                    +combinedUtility(OwnValue * OtherValue * -1, Action)
                } else {
                    +combinedUtility(OwnValue * OtherValue, Action)
                }
            }
            .findall(combinedUtility(X, Y), combinedUtility(X, Y), CombinedUtility)
            .max(CombinedUtility, combinedUtility(CombinedMaxUtility, CombinedAction))
            .print("Action with combined maximum utility: ", CombinedAction)
            .print("Approve executing: ", CombinedAction);
            +approvedAction(CombinedAction)
        }
    }
    +awaitProposal("").

/* wait for persuader's compromise suggestion
   approve/disapprove suggestions
   print action acknowledgement/disapproval */
+propose(action, ReceivedAction)[source(A)] <-
    if(firstReponse(_)) {
        .wait({+awaitProposal(_)});
        -awaitProposal("");
        -firstReponse("")
    }
    .findall(Name, approvedAction(Name), ApprovedActions)
    .nth(0, ApprovedActions, ApprovedAction)
    if (ReceivedAction == ApprovedAction) {
        .print("Approve proposal for executing: ", ReceivedAction);
        .send(A, tell, approve(ReceivedAction))
    } else {
        .print("Disapprove proposal for executing: ", ReceivedAction)
        .print("Expected action: ", ApprovedAction);
        // send own attacks and rules
        .findall(acceptable(X, Y), acceptable(X, Y), AcceptabilityRules)
        .findall(attack(X, Y), attack(X, Y), Attacks)
        .send(A, tell, disapprove(AcceptabilityRules, Attacks, ApprovedAction));
    }.
/*
+!start <-  .findall(attack(X, Y), attack(X, Y), Attacks)
    for (.member(Attack, Attacks)) {
        .findall(Argument, attack(Target, Argument), Names)
        .nth(0, Names, Name)
        .findall(Target, attack(Target, Argument), Targets)
        .nth(0, Targets, Target)
        if(does_exist(Name)) {
            .findall(OldTargetsList, argument(Name, OldTargetsList), OldTargetsList)
            .nth(0, OldTargetsList, OldTargets)
            .concat(OldTargets, [Target], NewTargets);
            -argument(Name, OldTargets);
            +argument(Name, NewTargets)
        } else {
            +argument(Name, [Target])
        }
        if(not does_exist(Target)) {
            +argument(Target, [])
        }
    }
    .findall([X, Y], argument(X, Y), Arguments)
    .print("Arguments: ", Arguments)
    empathy.solve_argument(Arguments, Resolution)
    .print("Remove successfully attacked acceptability rules: ", Resolution)
    for(.member(InvalidAttack, Resolution)) {
        -acceptable(InvalidAttack)
    }.*/
