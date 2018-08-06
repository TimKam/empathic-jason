// initial beliefs
benefit(-100, "Show vodka ad").
benefit(-5, "Show steak ad").
benefit(10, "Show university ad").
benefit(2, "Show community college ad").
acceptable("Show university ad", "Show community college ad").
acceptable("Show community college ad", "Show university ad").

is_acceptable(PersuaderAction, MitigatorAction) :-
    .findall(_, acceptable(PersuaderAction, MitigatorAction), Res)
    & .length(Res, Length)
    & Length > 0.

/***Plans***/
/* wait for persuader's utility mapping
   respond with own mapping
   compute compromise */
+announce(utility, ReceivedUtility)[source(Source)] <- .print("Received utility mapping: ", ReceivedUtility)
    .findall(benefit(X, Y), benefit(X, Y), OwnUtility)
    .send(Source, tell, respond(OwnUtility))
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
    };
    +actionApproved(_).

/* wait for persuader's compromise suggestion
   approve/disapprove suggestions
   print action acknowledgement/disapproval */
+propose(action, ReceivedAction)[source(Source)] <-
    .wait({+actionApproved(_)})
    .findall(Name, approvedAction(Name), ApprovedActions)
    .nth(0, ApprovedActions, ApprovedAction)
    if (ReceivedAction == ApprovedAction) {
        .print("Approve proposal for executing: ", ReceivedAction);
        .send(Source, tell, approve(ReceivedAction))
    } else {
        .print("Disapprove proposal for executing: ", ReceivedAction)
        .print("Expected action: ", ApprovedAction);
        .send(Source, tell, disapprove(ReceivedAction))
    }.

