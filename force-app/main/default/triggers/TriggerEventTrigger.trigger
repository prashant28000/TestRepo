trigger TriggerEventTrigger on Trigger_Event__e (after insert) {
    Trigger_Event__e evt = trigger.new[0];
    TriggerLogGenerator.logTriggerSummary(evt.Object_Name__c, evt.Operation__c, evt.Error_Reasons__c);
}