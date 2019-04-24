
# logicapps-alerts


## Presentation

Monitoring and bring a LogicApps based solutions to reliability could be quite challenging sometimes.

Hopefully, Azure offers different tools to manage these aspects. We can use some integrated artifacts like Azure Dashboards mainly for monitoring purposes but we can also use complete solutions like Azure Monitor and also a lot in-between alternatives.

Globally, in my projects, I have to take care of 3 "kinds" of monitoring/alerts (I couple the 2 concepts because they often come together):

- Overall runs activities monitoring like Metrics related to LogicApps (Run Succeed, Average Execution Time, ...).

- LogicApps executions and "In-Process" activities like errors handling (catching an error that occurs in an LogicApp and do something with it).

- Overall platform activity and health monitoring (like the number of runs failures in a time frame for example to evaluate if the LogicApp can manage the activity).

To help me with these objectives, I leverage these 3 Azure Services:

- Azure Dashboards
- Azure LogicApps ^^
- Azure Monitor

This demonstration shows how to implement these 3 kinds of monitoring/alerts artifacts by using a simple scenario implementation.


## The scenario

Let's say we have a solution that relies on different LogicApps in the background and we want to manage monitoring and errors at this layer. Using the 3 previously described Azure features, we can start with this kind of high-level architecture:


![high level](docs/highlevel.png | width=500)


Into the Azure Resources Group, we will find our bunch of LogicApps we want to manage.

 - In the **A** section
We use a dedicated LogicApp called "LogicApp-Error" to catch all errors that may occur from the bunch of workflows. More information later.

 - In the **B** section
We use a dedicated Azure Dashboard to monitor quite in real-time different metrics from the workflows runs and also to have an history of them.

 - In the **C** section
We use Azure Monitor to telemetry some important measures about the overall platform performances and notify if a certain threshold is exceeded.


## Demonstration

Our demo scenario contains a bunch of LogicApps.

Because our solution could be overloaded or subject to different problems, We want to increase reliability by getting more information about runs and being able to do something "useful" when an unexpected event occurs.

For our scenario, let's build the 2 dummies LogicApps, one that success (logicapp-1) and one that fails (logicapp-2).


**logicapp-1**

Nothing special here. The workflow runs and succeed (we still have an error handling in this one but it will never be hit).


![](docs/pict10.PNG =500x)


**logicapp-2**

In this one, we generate an error by passing a wrong data type to the Select action (Boolean instead of Array). This way, we can easy test error and activity handling from this one.


![](docs/pict11.PNG =500x)


Now let's create the different monitoring/alerts artifacts.



## The Azure LogicApp to manage errors (section A)

In these processes, We could manage errors right inside the LogicApp itself and plug error management logic inside (like described in the article: https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-exception-handling). But, when a solution involves several LogicApps, it can be useful to have a centralized way to manage errors than occur in the whole solution processes at any level.

I like to leverage an Azure LogicApp for this purpose because other LogicApps can send errors details to a dedicated LogicApp instead of having to manage their own errors (especially if the way to manage errors is quite similar).

So, in our scenario, we going to create a new LogicApp called *logicapp-error* to manage any error that comes from other processes. We can represent it as follow:


![](docs/pict1.png =250x)


This logicapp-alert endpoint exposes 2 parameters:

-  *context*: that contains information about the workflow run that triggered the error.
-  *error*: that contains information about the error itself.


![](docs/pict4.PNG =500x)


In case of error in the other LogicApps, these parameters are sent by using the "Azure Logic Apps" built-in action and the 2 built-in functions *workflow()* and *result('scope_name')*.


![](docs/pict13.PNG =500x)



## The Azure Dashboard (section B)

Azure Dashboards can be used to display important metrics about a LogicApp.

We will see here how to display 2 metrics: runs succeed and runs failed (for the last hour - could be overridden by user).

To implement the Dashboard definition for the ARM template, I just built it using the portal and I modified the exported definition according to my needs.

I had to 'tokenize' some parts: in the extracted template, references to the resources to monitor are hard-coded. We need to use ARM functions to dynamically rebuild the reference.

Example: If you want to get the full reference to the *logicapp-2* resource, you will use `[resourceId('Microsoft.Logic/workflows', 'logicapp-2')]`.

Finally, at the end, you get the dashboard deployed to your resources group and accessible from the dashboards menu.


![](docs/pict5.PNG =600x)


## Azure Monitor (section C)

Azure Monitor (aka Log Analytics) is a beautiful telemetry piece that can integrate and monitor natively my solution.

It's more platform oriented and solution health monitoring. It does not fit very well detection and management of events that happen into the LogicApp process itself. To make it short, it's not oriented on a single execution, it's more "statistics/trends" oriented.

It's a very useful additional layer of monitoring when you want to define if your solution is well designed and assumes the workload. This way, you can for example monitor/alert Execution Latency of your LogicApps and try to improve processes designs in order to increase performances (i.e.: by using batch requests. Good resource for that can be found here: https://github.com/piou13/logicapps-sharepoint-batch ^^ ).

In this example, we create an Action Group that use mail notification (but we can plug additional features like SMS, Azure Functions, LogicApp, WebHooks, etc...).


![](docs/pict6.PNG =600x)


Then, We define a Metric Alert that triggers when the percentage of runs failures is over 1% for the last 30 minutes. When an alert is triggered, the Action Group is called.


![](docs/pict7.PNG =600x)


You can check these settings by going to the logicapp-2 (this is where we deployed the Metric Alert) in the Alerts section. You also have access to the alerts dashboard.


![e](docs/pict8.PNG =250x)

![](docs/pict9.PNG =600x)

![](docs/pict15.PNG =600x)


In case of alert, Azure Monitor will send you an email by the mean of the Action Group.

A good starting point with Azure Monitor Alerts can be found here: https://docs.microsoft.com/en-us/azure/azure-monitor/platform/alerts-metric



## Install the sample

**Prerequisites**

- An Azure subscription
- A Resource Group
- Owner of the Resource Group

**The sample contains:**

- The Azure ARM Template.
- The PowerShell setup script.

**Run the sample**

To install the sample, run the PowerShell script from its location with the following parameters:

-  _ResourceGroupName_: The name of an existing resources group.
-  _AlertEmail_: Email address to send alerts to.



## The alternatives

As I told you in the introduction, there's other alternatives to help us in LogicApp monitoring. In this sample, I show three of them but some other may be more fitted depending your need.

I will try to include these additional solutions to this tutorial (depending on my free-time ;)) but meanwhile, here's a quick description of them:

- Log Analytics + the LogicApps Management Solution

Very powerful and "straight to the point" solution. You can turn-on diagnostic logging and integrate with Azure Log Analytics. Then, in Log Analytics, you install the LogicApps Management Solution. A complete integrated app that gives you deep analytics on different aspects of LogicApp.

https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-monitor-your-logic-apps-oms

- View the LogicApps triggers and runs history

Simple but efficient when you want to get detailed information about workflows histories. Also useful for debugging because you can relaunch a previous workflow, it will run using the last version. We can use the portal to browse this information but there's also an API I would like to investigate.

https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-monitor-your-logic-apps#view-runs-and-trigger-history-for-your-logic-app



## References

 - Azure Dashboard

https://docs.microsoft.com/en-us/azure/azure-portal/azure-portal-dashboards

- Azure Monitor

https://docs.microsoft.com/en-us/azure/azure-monitor/overview

