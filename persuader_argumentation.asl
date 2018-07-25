// initial beliefs
revenue(3, "Show vodka ad").
revenue(2, "Show steak ad").
revenue(1, "Show university ad").
revenue(0.1, "Show community college ad").
acceptable("Show university ad", "Show community college ad").
acceptable("Show community college ad", "Show university ad").
acceptable("Show vodka ad", "Show university ad").
acceptable("Show vodka ad", "Show community college ad").
acceptable("Show vodka ad", "Show steak ad").

/***Rules***/
// acceptability check
is_acceptable(PersuaderAction, MitigatorAction) :-
    .findall(_, acceptable(PersuaderAction, MitigatorAction), Res)
    & .length(Res, Length)
    & Length > 0.
// argument existence check
does_arg_exist(Name) :-
    .findall(_, argument(Name, _), Res)
    & .length(Res, Length)
    & Length > 0.
// acceptability rule existence check
does_rule_exist(Name) :-
    .findall(_, argument(Name, _), Res)
    & .length(Res, Length)
    & Length > 0.

/***Goals***/
// initial goal
!start.

/***Plans***/
// announce utility mapping
+!start <- .findall(revenue(X, Y), revenue(X, Y), Utility)
    .broadcast(tell, announce(utility, Utility)).

// receive mitigator's utility mapping and update beliefs accordingly
+respond(Utility) <- .print("Received utility mapping: ", Utility)
    for (.member(Benefit, Utility)) {
        +Benefit
    }
    !proposeAction.

// determine and propose compromise
+!proposeAction <- .findall(revenue(X, Y), revenue(X, Y), OwnUtility)
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
+disapprove(AcceptabilityRules, Attacks, ExpectedAction) <- .print("Must not execute proposed action.")
    .print("Received acceptability rules: ", AcceptabilityRules)
    .print("Received attacks: ", Attacks)
    .print("Mitigator expects: ", ExpectedAction)
    for(.member(AcceptabilityRule, AcceptabilityRules)){
        if(not does_rule_exist(AcceptabilityRule)) {
            +AcceptabilityRule
        }
    }
    for (.member(Attack, Attacks)) {
        +Attack
        .findall(Argument, attack(Target, Argument), Names)
        .nth(0, Names, Name)
        .findall(Target, attack(Target, Argument), Targets)
        .nth(0, Targets, Target)
        if(does_arg_exist(Name)) {
            .findall(OldTargetsList, argument(Name, OldTargetsList), OldTargetsList)
            .nth(0, OldTargetsList, OldTargets)
            .concat(OldTargets, [Target], NewTargets);
            -argument(Name, OldTargets);
            +argument(Name, NewTargets)
        } else {
            +argument(Name, [Target])
        }
        if(not does_arg_exist(Target)) {
            +argument(Target, [])
        }
    }
    .findall([X, Y], argument(X, Y), Arguments)
    .print("Arguments: ", Arguments)
    empathy.solve_argument(Arguments, Resolution)
    .print("Remove successfully attacked acceptability rules: ", Resolution)
    for(.member(InvalidAttack, Resolution)) {
        .findall(acceptable(InvalidAttack, _), acceptable(InvalidAttack, _), InvalidRules)
        for(.member(InvalidRule, InvalidRules)) {
            -InvalidRule;
            +~InvalidRule;
        }
    }
    !proposeAction. 