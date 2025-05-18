public class BulkRecordUpsert {
 
    public static void ingestJob(String csvData, String recipientEmail) {
        try {
            String apiVersion = '58.0';
            String operation = 'upsert';
            String objectName = 'Account';
            String externalIdField = 'External_Id__c';
 
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String jobEndpoint = 'callout:Bulk2/services/data/v' + apiVersion + '/jobs/ingest';
 
            // Create job request payload
            Map<String, Object> jobPayload = new Map<String, Object>{
                'externalIdFieldName' => externalIdField,
                'lineEnding' => 'LF',
                'operation' => operation,
                'object' => objectName,
                'contentType' => 'CSV'
            };
            String jobRequestBody = JSON.serialize(jobPayload);
            System.debug('Job request body: ' + jobRequestBody);
 
            Http http = new Http();
            HttpRequest createJobRequest = new HttpRequest();
            createJobRequest.setEndpoint(jobEndpoint);
            createJobRequest.setMethod('POST');     
            createJobRequest.setHeader('Content-Type', 'application/json');
            createJobRequest.setBody(jobRequestBody);
 
            HttpResponse createJobResponse = http.send(createJobRequest);
            system.debug(createJobResponse.getStatusCode() + ' ' + createJobResponse.getBody());
 
            if (createJobResponse.getStatusCode() == 200 || createJobResponse.getStatusCode() == 201) {
                System.debug('Job created successfully.');
                System.debug(createJobResponse.getBody());
 
                Map<String, Object> jobResponse = (Map<String, Object>) JSON.deserializeUntyped(createJobResponse.getBody());
                String jobId = (String) jobResponse.get('id');
                System.debug('Job ID: ' + jobId);
 
                // Step 2: Upload CSV data
                String uploadEndpoint = 'callout:Bulk2/services/data/v' + apiVersion + '/jobs/ingest/' + jobId + '/batches';
                HttpRequest uploadDataRequest = new HttpRequest();
                uploadDataRequest.setMethod('PUT');
                uploadDataRequest.setEndpoint(uploadEndpoint);
                uploadDataRequest.setHeader('Content-Type', 'text/csv');
                uploadDataRequest.setBody(csvData);
 
                HttpResponse uploadDataResponse = http.send(uploadDataRequest);
                System.debug('Upload Response: ' + uploadDataResponse.getBody());
 
                if (uploadDataResponse.getStatusCode() <= 299) {
                    // Step 3: Mark job as ready to process
                    String completeJobEndpoint = 'callout:Bulk2/services/data/v' + apiVersion + '/jobs/ingest/' + jobId;
                    HttpRequest completeJobRequest = new HttpRequest();
                    completeJobRequest.setMethod('PATCH');
                    completeJobRequest.setEndpoint(completeJobEndpoint);
                    completeJobRequest.setHeader('Content-Type', 'application/json');
                    completeJobRequest.setBody('{ "state" : "UploadComplete" }');
 
                    HttpResponse completeJobResponse = http.send(completeJobRequest);
                    System.debug('Job Completion Response: ' + completeJobResponse.getBody());
                    
                    String CRON_EXP = '0 0 * * * ?'; 
                    BulkApiJobMailHelper sch = new BulkApiJobMailHelper(jobId, recipientEmail); 
                    system.schedule('Hourly BULK API job mail' + System.now(), CRON_EXP, sch);
                } else {
                    System.debug('Error uploading CSV data: ' + uploadDataResponse.getStatusCode() + ' - ' + uploadDataResponse.getBody());
                }
            } else {
                System.debug('Error creating job: ' + createJobResponse.getStatusCode() + ' - ' + createJobResponse.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }
    
    @future(callout = true)
    public static void processJobsWithSummary(String inputJobId, String recipientEmail, String schJobId) {
        String jobEndpoint = 'callout:Bulk2/services/data/v58.0/jobs/ingest/' + inputJobId;
        Http http = new Http();
        HttpRequest jobInfoRequest = new HttpRequest();
        jobInfoRequest.setEndpoint(jobEndpoint);
        jobInfoRequest.setMethod('GET');
        jobInfoRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        jobInfoRequest.setHeader('Content-Type', 'application/json');
        HttpResponse response = http.send(jobInfoRequest);
        String jsonResponse = response.getBody();
        
        List<String> failedJobDetails = new List<String>();
        List<String> successfulJobDetails = new List<String>();
        Set<String> affectedObjects = new Set<String>();
     
        Map<String, Object> jobData = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        system.debug(jobData);
        system.debug(jobData.get('state'));
        
        String status = (String) jobData.get('state');
        String jobId = (String) jobData.get('id');
        String objectName = (String) jobData.get('object');
        Integer processed = (Integer) jobData.get('numberRecordsProcessed');
        Integer failed = (Integer) jobData.get('numberRecordsFailed');
        String failureReason = (String) jobData.get('errorMessage');
        
        if (status == 'Failed' || (status == 'JobComplete' && failed > 0)) {
            failedJobDetails.add(
                'Job ID: ' + jobId + '\n' +
                'Object: ' + objectName + '\n' +
                'Processed Records: ' + processed + '\n' +
                'Failed Records: ' + failed + '\n' +
                'Error Message: ' + (failureReason != null ? failureReason : 'No error message') + '\n'
            );
        }
        else if (status == 'JobComplete' && failed == 0) {
            successfulJobDetails.add(
                'Job ID: ' + jobId + '\n' +
                'Object: ' + objectName + '\n' +
                'Processed Records: ' + processed + '\n' +
                'All records processed successfully.\n'
            );
        }
        
        if (!failedJobDetails.isEmpty() || !successfulJobDetails.isEmpty()) {
            sendJobSummaryNotification(successfulJobDetails, failedJobDetails, recipientEmail);
            System.abortJob(schJobId);
        }
    }
 	
    private static void sendJobSummaryNotification(
        List<String> successDetails,
        List<String> failureDetails,
        String recipientEmail
    ) {
        if (recipientEmail == null) return;
     
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { recipientEmail });
        email.setSubject('Bulk Data Load Summary');
     
        String body = 'BULK DATA LOAD SUMMARY\n\n';
     
        if (!successDetails.isEmpty()) {
            body += '--- Successful Jobs ---\n';
            body += String.join(successDetails, '\n------------------\n');
            body += '\n\n';
        }
     
        if (!failureDetails.isEmpty()) {
            body += '--- Failed Jobs ---\n';
            body += String.join(failureDetails, '\n------------------\n');
            body += '\n\nPlease investigate failed jobs.\n';
        }
     
        email.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}