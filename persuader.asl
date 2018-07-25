// initial beliefs
revenue(3, "Show vodka ad").
revenue(2, "Show steak ad").
revenue(1, "Show university ad").
revenue(0.1, "Show community college ad").
acceptable("Show university ad", "Show community college ad").
acceptable("Show community college ad", "Show university ad").

// Rule - acceptability check
is_acceptable(PersuaderAction, MitigatorAction) :-
    .findall(_, acceptable(PersuaderAction, MitigatorAction), Res)
    & .length(Res, Length)
    & Length > 0.

// initial goal
!start.

/***Plans***/
// announce utility mapping
+!start <- .findall(revenue(X, Y), revenue(X, Y), Utility)
    .broadcast(tell, announce(utility, Utility)).

// receive mitigator's utility mapping; determine and propose compromise
+respond(Utility) <- .print("Received utility mapping: ", Utility)
    for (.member(Benefit, Utility)) {
        +Benefit
    }
    .findall(revenue(X, Y), revenue(X, Y), OwnUtility)
    .max(OwnUtility, revenue(OwnMaxUtility, OwnAction))
    .findall(benefit(X, Y), benefit(X, Y), OtherUtility)
    .max(OtherUtility, benefit(OtherMaxUtility, OtherAction))
    .print("Own best action: ", OwnAction)
    .print("Other's best action: ", OtherAction)
    if (OwnAction == OtherAction) {
        .print("Propose executing: ", OwnAction)
        .broadcast(tell, propose(action, OwnAction))
    } else {
        if(is_acceptable(OwnAction, OtherAction)) {
            .print("Own best action acceptable")
            .print("Propose executing: ", OwnAction)
            .broadcast(tell, propose(action, OwnAction))
        } else {
            .print("Own best action not acceptable")
            .findall(Name, revenue(Value, Name), Actions)
            for(.member(Action, Actions)){
                .findall(Value, revenue(Value, Action), OwnValues)
                .nth(0, OwnValues, OwnValue)
                .findall(Value, benefit(Value, Action), OtherValues)
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
            .print("Propose executing: ", CombinedAction)
            .broadcast(tell, propose(action, CombinedAction))
        }
    }.
                        
// receive approval and execte action
+approve(Action) <- .print("Execute: ", Action).
// or receive disapproval and stop service offering
+disapprove(Action) <- .print("Must not execute: ", Action, ". Shutting down service offering.").