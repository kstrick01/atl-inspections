@IsTest
private class InspectionImportTest {

    private class ApiMock implements HttpCalloutMock {
        private final Integer status;
        private final String body;

        ApiMock(Integer status, String body) {
            this.status = status;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(status);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
            return res;
        }
    }

    private static String sampleBody() {
        return '[' +
            '{"restaurantId":"R1","restaurantName":"Sample Peach Diner","address":"1 Test St",' +
            '"city":"Atlanta","postalCode":"30303","inspectionId":"I1","score":88,"inspectionDate":"2026-01-10"},' +
            '{"restaurantId":"R1","restaurantName":"Sample Peach Diner","address":"1 Test St",' +
            '"city":"Atlanta","postalCode":"30303","inspectionId":"I2","score":96,"inspectionDate":"2026-06-10"}' +
            ']';
    }

    @IsTest
    static void importsRecordsAndRollsUpLatest() {
        Test.setMock(HttpCalloutMock.class, new ApiMock(200, sampleBody()));

        Test.startTest();
        System.enqueueJob(new InspectionImportJob(Date.newInstance(2026, 1, 1), 1));
        Test.stopTest();

        Restaurant__c r = [SELECT Name, Latest_Score__c, Latest_Grade__c
                           FROM Restaurant__c WHERE External_Id__c = 'R1'];
        Assert.areEqual('Sample Peach Diner', r.Name);
        Assert.areEqual(96, r.Latest_Score__c);
        Assert.areEqual('A', r.Latest_Grade__c);
        Assert.areEqual(2, [SELECT COUNT() FROM Inspection__c]);
    }

    @IsTest
    static void rerunningTheImportDoesNotCreateDuplicates() {
        Test.setMock(HttpCalloutMock.class, new ApiMock(200, sampleBody()));

        Test.startTest();
        System.enqueueJob(new InspectionImportJob(Date.newInstance(2026, 1, 1), 1));
        Test.stopTest();

        Test.setMock(HttpCalloutMock.class, new ApiMock(200, sampleBody()));
        Test.startTest();
        System.enqueueJob(new InspectionImportJob(Date.newInstance(2026, 1, 1), 1));
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Restaurant__c]);
        Assert.areEqual(2, [SELECT COUNT() FROM Inspection__c]);
    }

    @IsTest
    static void invalidRowsAreSkipped() {
        String body = '[' +
            '{"restaurantId":"R1","restaurantName":"Sample Peach Diner","inspectionId":"I1",' +
            '"score":90,"inspectionDate":"2026-06-10"},' +
            '{"restaurantId":"R2","restaurantName":"No Score Cafe","inspectionId":"I2",' +
            '"inspectionDate":"2026-06-10"},' +
            '{"restaurantName":"No Id Cafe","inspectionId":"I3","score":80,"inspectionDate":"2026-06-10"}' +
            ']';
        Test.setMock(HttpCalloutMock.class, new ApiMock(200, body));

        Test.startTest();
        System.enqueueJob(new InspectionImportJob(Date.newInstance(2026, 1, 1), 1));
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Restaurant__c]);
        Assert.areEqual(1, [SELECT COUNT() FROM Inspection__c]);
    }

    @IsTest
    static void apiErrorRaisesApiException() {
        Test.setMock(HttpCalloutMock.class, new ApiMock(500, '{"error":"boom"}'));

        Test.startTest();
        try {
            InspectionApiClient.fetchPage(Date.today(), 1);
            Assert.fail('Expected an ApiException');
        } catch (InspectionApiClient.ApiException e) {
            Assert.isTrue(e.getMessage().contains('500'));
        }
        Test.stopTest();
    }

    @IsTest
    static void schedulerEnqueuesTheImport() {
        Test.setMock(HttpCalloutMock.class, new ApiMock(200, sampleBody()));

        Test.startTest();
        String jobId = System.schedule('Test Inspection Import', '0 0 2 * * ?',
            new InspectionImportScheduler());
        Test.stopTest();

        Assert.isNotNull(jobId);
        Assert.areEqual(1, [SELECT COUNT() FROM CronTrigger WHERE Id = :jobId]);
    }
}
