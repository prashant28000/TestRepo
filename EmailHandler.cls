public class EmailHandler implements Messaging.InboundEmailHandler {
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        system.debug(email.plainTextBody);
        system.debug(email.fromAddress);
        system.debug(email.fromName);
 		
        try{
            for (Messaging.InboundEmail.BinaryAttachment attachment : email.binaryAttachments) {
                if (attachment.filename.endsWithIgnoreCase('.csv')) {
                    String csvContent = attachment.body.toString();
					csvContent = csvContent.replaceAll('\r\n', '\n');
                    system.debug(csvContent);
                    BulkRecordUpsert.ingestJob(csvContent, email.fromAddress);
                }
            }
        }
        catch(Exception e){
            
        }
        
        result.success = true;
        return result;
    }
}