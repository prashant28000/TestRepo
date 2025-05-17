@isTest
private class EmailHandlerTest {
 
    @isTest
    static void testHandleInboundEmail_withCSV() {
        String csvData = 'ExternalId,Name,BillingCity\n001,TestAccount,New York\n002,AnotherAccount,Chicago';
 
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.plainTextBody = 'This is a test email body';
        email.fromAddress = 'testuser@example.com';
        email.fromName = 'Test User';
 
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.filename = 'accounts.csv';
        attachment.body = Blob.valueOf(csvData);
        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[] { attachment };
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
 
        Test.startTest();
        EmailHandler handler = new EmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
 
        System.assert(result.success, 'Email handling should succeed');
    }
}