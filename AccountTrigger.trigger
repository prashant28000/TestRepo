trigger AccountTrigger on Account (before update, before insert, before delete, after update, after insert, after delete, after undelete) {
    String sObjName = String.valueOf((trigger.new ?? trigger.old).getSObjectType());
    try{
        ExceptionGenerator.soqlException();
        if(trigger.isAfter){
            TriggerLogGenerator.logTriggerSummary(sObjName, String.valueOf(trigger.operationType), null);
        }        
    }
    catch(Exception e){
        TriggerLogGenerator.hanldeTriggerException(sObjName, String.valueOf(trigger.operationType), e.getMessage());
        throw e;
    }
}