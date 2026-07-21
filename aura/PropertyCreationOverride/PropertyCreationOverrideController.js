({
    doInit: function (component, event, helper) {
        var flow = component.find("flowData");
        flow.startFlow("Property_Creation");
    },

    handleStatusChange: function (component, event, helper) {
        if (event.getParam("status") === "FINISHED") {
            var navigateEvent = $A.get("e.force:navigateToObjectHome");
            navigateEvent.setParams({
                scope: "Property__c"
            });
            navigateEvent.fire();
        }
    }
})
