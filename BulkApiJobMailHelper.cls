global class BulkApiJobMailHelper implements Schedulable {
    public String bulkJobId;
    public String recipientEmail;
    
    global BulkApiJobMailHelper(String bulkJobId, String recipientEmail) {
        this.bulkJobId = bulkJobId;
        this.recipientEmail = recipientEmail;
    }
    
    global void execute(SchedulableContext ctx){
        String schJobId = ctx.getTriggerId();
        BulkRecordUpsert.processJobsWithSummary(bulkJobId, recipientEmail, schJobId);
    }
}