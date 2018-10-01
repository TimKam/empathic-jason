# Empathic Jason agents - examples
**Author**: [Timotheus Kampik](https://github.com/TimKam)

In this repository, we provide two examples of *empathic agents*, implemented with [Jason](http://jason.sourceforge.net/wp/) [1].

## Empathic agents
At the 6th International Workshop on Engineering Multi-Agent System (EMAS), we introduced the idea of an *empathic agent* [2] as an agent that maintains a "process through which [it] simulates another’s situated psychological states, while maintaining clear self–other differentiation", following a particular philosophical definition of empathy [3].

In their basic version, our empathic agents consider exactly one specific moment, at which each of them can execute a finite set of actions.
Each action can potentially affect the utility of the executing agent, as well as of all other agents.

The agents follow a combined utility-based/rule-based approach to decide upon the actions each agent should execute:

*   They construct a utility function for each agent that maps all possible action sets (of all agents) to a numeric utility value.
    To ensure the utility mappings of different agents are comparable and that consensus can be reached, a *shared value system* is required.
    If there is no activity set that optimizes all agents' utility functions, a *conflict of interests* is detected. 

*   If a conflict of interests exists, each agent applies a set of acceptability rules that determine whether a conflicting action set is indeed not acceptable or whether the agent is allowed to execute this action despite the conflict (however, the agent will only do so if this makes sense; see below).
    If the actions are not acceptable (or acceptable, but not chosen to be executed), the agents can:
    
    *   Choose the actions that maximize their combined utility.
        This approach does not always lead to the best acceptable solution possible, because the agents never consider action sets that do not optimize their own utility, but are better than the compromise.
        Hence, agents that follow this approach can be referred to as *lazy empathic agents*.
        The *lazy* approach reduces worst case complexity, as it avoids iterating through action sets that are neither *egoistically optimal* (considering all agents execute actions the agent in focus prefers), nor *combined-utility optimal*.

    *   Select the next best set of actions, considering one's individual utility and repeat the check for conflicts and acceptability.
        This approach ensures the utility outcome for the agent is the best acceptable outcome possible.
        Hence, we refer to agents that follow this approach as *full empathic agents*.
        The downside of this approach is that in the worst case, it requires re-iterating through all action sets that offer better own utility than the action set that provides maximal combined utility before settling on the latter.

    Game theoretical considerations need to be made to determine if an agent should in fact execute a acceptable, but conflicting action: if one agent executes a set of acceptable, but conflicting actions, given that another agent does the same, the resulting utility for both could be worse than the compromise or than a different set of conflicting, but acceptable actions.
    However, in the context of our Jason implementation we focus on *two agent, one actor* scenarios.
    In these scenarios, such considerations do not need to be made, as the non-acting agent has no action set to adjust as a reaction to the acting agent.
    Hence, we do not cover these game theoretical aspects in detail here.

The notion of acceptability rules in case of conflicts is introduced to reflect a human-like approach to empathic behavior that does not encompass combined utility optimization in all cases.
For example, in many human societies, the notion of *individual freedom* allows actors to maximize their own utility, as long as this does not directly harm others; the utility loss of others through *inaction* is in many cases acceptable.

A range of artificial intelligence concepts and algorithms can be applied to extend the *empathic agent* basic concepts.
To cover multiple discrete (or discretized) time steps, the concepts can be implemented with Markov decision processes (not implemented in the provided examples).
Analogously, the concepts can be extended in different directions, for example by adding argumentation capabilities to find consensus if agents have inconsistent beliefs, as the advanced example in this repository demonstrates.

## Requirements
As Jason is Java-based, you will need Java (8 or later), as well as [Maven](https://maven.apache.org/) (3.3 or later) and [Gradle](https://gradle.org/) (4.5. or later) to run the examples.
Follow the instructions in the [Jason documentation](https://github.com/jason-lang/jason/blob/master/doc/tutorials/getting-started/readme.adoc#installation-and-configuration) to install and configure Jason.
If you are using Windows, you will need a Bash emulator for running the advanced example.

## Running the examples
The repository contains two examples, one *basic* example, which only uses pure AgentSpeak (Jason's agent-oriented programing language), and one advanced example, which makes use of a custom-implemented argumentation extension for Jason.
To get the examples, clone this repository with ``git clone https://github.com/TimKam/empathic-jason.git``.

To run the **basic** example, proceed as follows:

1.  Navigate into the repository's root directory.

2.  Install the dependencies for the Jason extension with ``gradle getDependencies``.

3.  Run ``jason empathic_example_simple.mas2j``.

To run the **advanced** example, proceed as follows:

1.  Navigate to the repository's root directory.

2.  Install the dependencies for the Jason extension with ``gradle getDependencies``.

3.  The advanced example requires building and running a [Tweety-based](http://tweetyproject.org/) argumentation server.
    Build the server with ``gradle buildArgumentationServer``.

4.  Start the argumentation server with ``gradle startArgumentationServer``.
    Once the server runs, you can exit the Gradle task with ``Ctrl + C`` and later stop the server with ``gradle stopArgumentationServer``.

5.  Finally, run the agents by executing ``jason empathic_example_argumentation.mas2j``.

## Jason extension
The repository contains a Jason extension that enables the agents to resolve arguments by applying argumentation theory [4], using the argumentation reasoning capabilities of the [Tweety library](http://tweetyproject.org/) [5].
The extension is located in the [src](src/) directory.
The extension architecture is service-oriented in that the argumentation reasoning is handled by a dedicated argumentation server that is accessible by the *local* part of the extension via RESTful HTTP (``GET``) requests.
The server runs on port ``8080`` on ``localhost``.
Configuring server port and address is currently only possible by editing the source code.

To use the extension, call ``empathy.solve_argument(Arguments, Resolution)``, for example as follows:

    empathy.solve_argument([argument("a",["b", "c"]), argument("b",["c"]), argument("c",[])]), Resolution)

The ``solve_argument`` function then assigns all non-acceptable arguments--in the example: ``["c"]``--to the ``Resolution`` variable.
In argumentation theory, the non-acceptable arguments the extensions determines are all arguments that are not element of the *maximal ideal extension*.
    
## Example scenarios and implementations
In this repository, we provide two example scenario implementations of empathic Jason agents.
Both scenarios have the same core properties (the advanced scenario is an extension of the basic scenario):

*   The use case is online advertisement (*ad*) selection.
    A *persuader* agent can choose from a list of ads and receives a monetary incentive that depends on the ad it displays.
    The human is represented by a *mitigator* agent that communicates the impact of the different ads on the human's well-being to the persuader, who considers this impact when choosing the ad to display.

*   As only the persuader is acting, we do not need to consider the game theoretical challenges we briefly discussed above.

*   The persuader can choose between four different ads, but can show only one ad at a time.
    Hence, the two utility mappings simply assign a utility value to each activity. The agents have the following activity-to-utility mappings in their belief base (note that the structure is ``(utility, action)`` and not vice versa:

    *   Persuader agent:

            revenue(3, "Show vodka ad").
            revenue(2, "Show steak ad").
            revenue(1, "Show university ad").
            revenue(0.1, "Show community college ad").

    *   Mitigator agent:

            benefit(-100, "Show vodka ad").
            benefit(-5, "Show steak ad").
            benefit(10, "Show university ad").
            benefit(2, "Show community college ad").

    The utility mappings of the persuader are labeled *revenue*, while the mappings of the mitigator are labelled *benefit* to highlight the differences in impact on the agents (economic impact on the persuader; impact on well-being of the individual the mitigator is proxying).
    However, we assume that *revenue* and *benefit* are measured in comparable units.
    Each agent starts with its own utility mapping in their *belief base*.
    The utility mapping of the other agent needs to be received at runtime.

### Basic scenario
In the basic example, both agents start with a belief base that contains the following acceptability rules in addition to the utility mappings:

    acceptable("Show university ad", "Show community college ad").
    acceptable("Show community college ad", "Show university ad").

First, the persuader sends its utility mappings to the mitigator and receives the mitigator's utility mappings in response.
Then, the persuader determines the action it will propose to execute.
It first selects the action that maximizes its own utility (``Show vodka ad``) and checks if it conflicts with the other agent's preferred action (``Show university ad``).
After determining the apparent conflict, the agent queries the acceptability rule base to determine whether the preferred action is acceptable even in the case of conflict.
As the action ``Show university ad`` is not acceptable in case of conflict, the agent falls back to proposing the action that maximizes combined utility (``utility_persuader * utility_mitigator``), which is the action ``Show university ad``.
I.e., the agents implemented in this example are *lazy* (see above) and do not try to find other conflicting, but acceptable solutions (action or action sets) that provide better individual utility than the solution that maximizes the shared utility after the individually best action as been deemed not acceptable. 
After having determined an action, the persuader sends over the action proposal to the mitigator.

In the meantime, the mitigator has executed the same algorithm to determine the activity it expects the persuader to propose.
As the utility mappings and acceptability rules in the belief bases of both agents are consistent, it determines the same action as the persuader, it can approve the persuader's action proposal.
The persuader can then execute the action ``Show university ad``.

If the mitigator would have determined another action (for example due to an acceptability rule set that is inconsistent with the one of the persuader), it would have rejected the proposed action and terminated the session.

### Advanced scenario (argumentation)
The advanced scenario introduces empathic agents that have argumentation capabilities to handle inconsistencies between the beliefs of different agents.
The agent implementations are extensions of the ones in the first example, i.e. they have the same empathic agent core.
In the scenario, the persuader has additional acceptability rules in its belief base--for some reason, it thinks that the action *Show vodka ad* is generally acceptable:

    acceptable("Show vodka ad", "Show university ad").
    acceptable("Show vodka ad", "Show community college ad").
    acceptable("Show vodka ad", "Show steak ad").

In contrast, the mitigator lacks these acceptability rules.
Based on the inconsistency itself, it is not possible to determine whether additional rules of the persuader are invalid or whether the mitigator lacks these rules.
However, the mitigator knows that the action *Show vodka ad* is generally not acceptable, because the user it represents is an alcoholic.
This is reflected by the following *attack* belief:

    attack("Show vodka ad", "Alcoholic").

Considering its acceptability rules, the persuader determines that ``Show vodka ad`` is the activity it should execute.
When the persuader proposes the activity, the mitigator disapproves of the proposal.
It sends its attack to the persuader, who then constructs an argumentation framework from all attacks and acceptability rules:

*   Each attack is added as an argument, with the rules it attacks as the argument's attack target.

*   Each attacked rule is added as an argument that does not attack any arguments.

*   Further arguments can be added as attacks to *attack*-type arguments.

Using the argumentation extension, the persuader resolves the argumentation framework: it determines the *maximal ideal extension* and removes all arguments (*attacks* or *acceptability rules*) that are not element of the maximal ideal extension from its belief base.
The attack ``attack("Show vodka ad", "Alcoholic")`` successfully attacks all inconsistent acceptability rules (rules the persuader has, but the mitigator has not).
The persuader now re-determines the to-be-proposed actions, considering the updated belief base.
The action it determines this time is ``Show university ad``.
The mitigator approves the action, so that the persuader can execute it.

## Acknowledgements
This work was partially supported by the Wallenberg AI, Autonomous Systems and Software Program (WASP) funded by the Knut and Alice Wallenberg Foundation.

## References
*   [1] R. H. Bordini, J. F. Hübner, and M. Wooldridge, Programming Multi-Agent Systems in AgentSpeak Using Jason (Wiley Series in Agent Technology). USA: John Wiley & Sons, Inc., 2007.

*   [2] T. Kampik, J. C. Nieves, and H. Lindgren, “Towards empathic autonomous agents,” in 6th International Workshop on Engineering Multi-Agent Systems (EMAS 2018), Stockholm, 2018.

*   [3] A. Coplan, “Will the real empathy please stand up? A case for a narrow conceptualization,” South. J. Philos., vol. 49, pp. 40–65, 2011.

*   [4] P. M. Dung, “On the acceptability of arguments and its fundamental role in nonmonotonic reasoning, logic programming and n-person games,” Artif. Intell., vol. 77, no. 2, pp. 321–357, 1995.

*   [5] M. Thimm, “Tweety - A Comprehensive Collection of Java Libraries for Logical Aspects of Artificial Intelligence and Knowledge Representation,” in Proceedings of the 14th International Conference on Principles of Knowledge Representation and Reasoning (KR’14), Vienna, Austria, 2014.

