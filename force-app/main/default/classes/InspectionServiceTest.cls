@IsTest
private class InspectionServiceTest {

    @IsTest
    static void gradeCutoffs() {
        Assert.areEqual('A', InspectionService.gradeFor(100));
        Assert.areEqual('A', InspectionService.gradeFor(90));
        Assert.areEqual('B', InspectionService.gradeFor(89));
        Assert.areEqual('B', InspectionService.gradeFor(80));
        Assert.areEqual('C', InspectionService.gradeFor(79));
        Assert.areEqual('C', InspectionService.gradeFor(70));
        Assert.areEqual('U', InspectionService.gradeFor(69));
        Assert.isNull(InspectionService.gradeFor(null));
    }

    @IsTest
    static void latestInspectionWins() {
        Restaurant__c r = new Restaurant__c(Name = 'Test Diner', External_Id__c = 'T1');
        insert r;

        insert new List<Inspection__c>{
            new Inspection__c(Restaurant__c = r.Id, Source_Id__c = 'I1', Score__c = 80,
                Grade__c = 'B', Inspection_Date__c = Date.today().addDays(-90)),
            new Inspection__c(Restaurant__c = r.Id, Source_Id__c = 'I2', Score__c = 96,
                Grade__c = 'A', Inspection_Date__c = Date.today())
        };

        r = [SELECT Latest_Score__c, Latest_Grade__c, Latest_Inspection_Date__c
             FROM Restaurant__c WHERE Id = :r.Id];
        Assert.areEqual(96, r.Latest_Score__c);
        Assert.areEqual('A', r.Latest_Grade__c);
        Assert.areEqual(Date.today(), r.Latest_Inspection_Date__c);
    }

    @IsTest
    static void deletingLatestFallsBackToPrevious() {
        Restaurant__c r = new Restaurant__c(Name = 'Test Diner', External_Id__c = 'T1');
        insert r;
        Inspection__c older = new Inspection__c(Restaurant__c = r.Id, Source_Id__c = 'I1',
            Score__c = 80, Grade__c = 'B', Inspection_Date__c = Date.today().addDays(-90));
        Inspection__c newer = new Inspection__c(Restaurant__c = r.Id, Source_Id__c = 'I2',
            Score__c = 96, Grade__c = 'A', Inspection_Date__c = Date.today());
        insert new List<Inspection__c>{ older, newer };

        delete newer;

        r = [SELECT Latest_Score__c, Latest_Grade__c FROM Restaurant__c WHERE Id = :r.Id];
        Assert.areEqual(80, r.Latest_Score__c);
        Assert.areEqual('B', r.Latest_Grade__c);
    }

    @IsTest
    static void deletingAllInspectionsClearsLatestFields() {
        Restaurant__c r = new Restaurant__c(Name = 'Test Diner', External_Id__c = 'T1');
        insert r;
        Inspection__c only = new Inspection__c(Restaurant__c = r.Id, Source_Id__c = 'I1',
            Score__c = 91, Grade__c = 'A', Inspection_Date__c = Date.today());
        insert only;

        delete only;

        r = [SELECT Latest_Score__c, Latest_Grade__c, Latest_Inspection_Date__c
             FROM Restaurant__c WHERE Id = :r.Id];
        Assert.isNull(r.Latest_Score__c);
        Assert.isNull(r.Latest_Grade__c);
        Assert.isNull(r.Latest_Inspection_Date__c);
    }

    @IsTest
    static void bulkInsertAcross200Restaurants() {
        List<Restaurant__c> restaurants = new List<Restaurant__c>();
        for (Integer i = 0; i < 200; i++) {
            restaurants.add(new Restaurant__c(Name = 'Bulk ' + i, External_Id__c = 'B' + i));
        }
        insert restaurants;

        List<Inspection__c> inspections = new List<Inspection__c>();
        for (Integer i = 0; i < 200; i++) {
            inspections.add(new Inspection__c(
                Restaurant__c = restaurants[i].Id, Source_Id__c = 'BI' + i,
                Score__c = 90, Grade__c = 'A', Inspection_Date__c = Date.today()));
        }

        Test.startTest();
        insert inspections;
        Test.stopTest();

        Assert.areEqual(200, [SELECT COUNT() FROM Restaurant__c WHERE Latest_Score__c = 90]);
    }
}
