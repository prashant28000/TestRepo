public class CSVAccountBatch implements Database.Batchable<String>, Database.Stateful {
    private List<String> csvLines;
    public Integer totalProcessed = 0;
    public Integer totalFailed = 0;
    public string recipientEmail = '';
    public string errors = '';
 
    public CSVAccountBatch(String csvContent, String recipientEmail) {
        this.csvLines = csvContent.split('\n');
        this.recipientEmail = recipientEmail;
        if (!csvLines.isEmpty()) 
            csvLines.remove(0);
    }
 
    public Iterable<String> start(Database.BatchableContext BC) {
        return csvLines;
    }
 
    public void execute(Database.BatchableContext BC, List<String> scope) {
        List<Account> accountsToUpsert = new List<Account>();
 
        for (String line : scope) {
            try {
                List<String> columns = line.split(',');
                if (columns.size() >= 3) {
                    Account acc = new Account();
                    acc.External_Id__c = columns[0].trim();
                    acc.Name = columns[1].trim();
                    acc.BillingCity = columns[2].trim();
                    accountsToUpsert.add(acc);
                } else {
                    totalFailed++;
                }
            } catch (Exception e) {
                totalFailed++;
            }
        }
 
        if (!accountsToUpsert.isEmpty()) {
            try {
                upsert accountsToUpsert External_Id__c;
                totalProcessed += accountsToUpsert.size();
            } catch (DmlException dmlEx) {
                errors += dmlEx.getMessage() + '\n';
                system.debug(dmlEx.getMessage());
                totalFailed += accountsToUpsert.size();
            }
        }
    }
 
    public void finish(Database.BatchableContext BC) {
        System.debug('Total Processed: ' + totalProcessed);
        System.debug('Total Failed: ' + totalFailed);
        system.debug('Email: ' + recipientEmail);
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] {recipientEmail});
     
        email.setSubject('CSV Account Import Summary');
        String body = 'Record processing has been completed.\n\n' +
                      'Total Records Processed: ' + (totalProcessed + totalFailed) + '\n' +
                      'Successfully Upserted: ' + totalProcessed + '\n' +
                      'Failed Records: ' + totalFailed + '\n';
        
        if(errors.length() > 0){
            body += 'Reason of Failure : ' + errors;
        }
    
        email.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}