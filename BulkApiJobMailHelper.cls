global class BulkApiJobMailHelper implements Schedulable {
    public String bulkJobId;
    public String recipientEmail;
    
    global BulkApiJobMailHelper(String bulkJobId, String recipientEmail) {
        this.bulkJobId = bulkJobId;
        this.recipientEmail = recipientEmail;
    }
    
    global void execute(SchedulableContext ctx){
        String schJobId = ctx.getTriggerId();
        String pattern = '%' + bulkJobId;
        List<EmailMessage> em = [Select id from EmailMessage where Subject LIKE :pattern];
        
        if(em.size() > 0){
            system.abortJob(schJobId);
            return;
        }
        BulkRecordUpsert.processJobsWithSummary(bulkJobId, recipientEmail, schJobId);
    }
}
