public class TriggerLogGenerator {
    private static final List<String> objectList = new List<String>{
        'Account', 'Contact', 'Opportunity', 'Case', 'Lead', 'Campaign', 'User', 'Task'};

    public static void logTriggerSummary(String objectName, String operation, String eMessage) {
        List<Trigger_Log__c> logsToInsert = new List<Trigger_Log__c>();
 		
        Trigger_Log__c log = new Trigger_Log__c();
        log.Name = 'Log - ' + objectName + ' Trigger';
        log.Object__c = objectName;
        log.Operation__c = operation.substring(operation.indexOf('_') + 1);
        
        if(eMessage == null){
            log.Result__c = 'Success';
        }
        else{
            log.Result__c = 'Error';
            log.Error_Reason__c = eMessage;
            Integer endIdx = Math.min(255, eMessage.length());
            log.Error_Reason_Short__c = eMessage.substring(0, endIdx);
        }
        logsToInsert.add(log);
        
        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
    }
    
    public static void hanldeTriggerException(String objectName, String operation, String err){
        Trigger_Event__e evt = new Trigger_Event__e(
            Object_Name__c = objectName, Operation__c = operation, Error_Reasons__c = err
        );    
        Database.SaveResult result = EventBus.publish(evt);
        System.debug('Publish Status: ' + result.isSuccess());
    }
}