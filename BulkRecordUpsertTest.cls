@isTest public class BulkRecordUpsertTest {
     
    @isTest
    static void testIngestJob_SuccessfulFlow() {
        Test.startTest();
		String csvData = 'External_Id__c,Name\n12345,Test Account';
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponseGenerator());
        Test.setMock(HttpCalloutMock.class, new MockJobFailedResponseGenerator());
        Test.setMock(HttpCalloutMock.class, new MockJobFailedResponseGenerator());
        BulkRecordUpsert.ingestJob(csvData, 'test@example.com');
        Test.stopTest();
    }
     
    private class MockSuccessResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (req.getMethod() == 'POST') {
                res.setBody('{"id":"750xx000000001A","state":"Open"}');
                res.setStatusCode(201);
            } else if (req.getMethod() == 'PUT') {
                res.setBody('Success Upload');
                res.setStatusCode(201);
            } else if (req.getMethod() == 'PATCH') {
                res.setBody('{"state":"UploadComplete"}');
                res.setStatusCode(200);
            }
            return res;
        }
    }
     
    private class MockJobCompleteResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id":"750xx000000001A","state":"JobComplete","object":"Account","numberRecordsProcessed":1,"numberRecordsFailed":0}');
            res.setStatusCode(200);
            return res;
        }
    }
     
    private class MockJobFailedResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id":"750xx000000002B","state":"Failed","object":"Account","numberRecordsProcessed":1,"numberRecordsFailed":1,"errorMessage":"Invalid data"}');
            res.setStatusCode(200);
            return res;
        }
    }
}