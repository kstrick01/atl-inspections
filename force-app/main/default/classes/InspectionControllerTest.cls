@IsTest
private class InspectionControllerTest {

    @TestSetup
    static void setup() {
        insert new List<Restaurant__c>{
            new Restaurant__c(Name = 'Sample Peach Diner', Postal_Code__c = '30303', External_Id__c = 'C1'),
            new Restaurant__c(Name = 'Sample Peach Bakery', Postal_Code__c = '30308', External_Id__c = 'C2'),
            new Restaurant__c(Name = 'Sample Magnolia Grill', Postal_Code__c = '30303', External_Id__c = 'C3')
        };
    }

    @IsTest
    static void searchByNameIsPartialAndCaseInsensitive() {
        List<Restaurant__c> results = InspectionController.searchRestaurants('peach', null);
        Assert.areEqual(2, results.size());
    }

    @IsTest
    static void searchByNameAndPostalCode() {
        List<Restaurant__c> results = InspectionController.searchRestaurants('peach', '30303');
        Assert.areEqual(1, results.size());
        Assert.areEqual('Sample Peach Diner', results[0].Name);
    }

    @IsTest
    static void blankSearchReturnsRestaurants() {
        Assert.areEqual(3, InspectionController.searchRestaurants('', '').size());
        Assert.areEqual(3, InspectionController.searchRestaurants(null, null).size());
    }

    @IsTest
    static void searchWithNoMatchReturnsEmptyList() {
        Assert.isTrue(InspectionController.searchRestaurants('zzz-no-match', null).isEmpty());
    }

    @IsTest
    static void historyIsNewestFirst() {
        Restaurant__c r = [SELECT Id FROM Restaurant__c WHERE External_Id__c = 'C1'];
        insert new List<Inspection__c>{
            new Inspection__c(Restaurant__c = r.Id, Source_Id__c = 'H1', Score__c = 70,
                Grade__c = 'C', Inspection_Date__c = Date.today().addDays(-200)),
            new Inspection__c(Restaurant__c = r.Id, Source_Id__c = 'H2', Score__c = 95,
                Grade__c = 'A', Inspection_Date__c = Date.today().addDays(-10))
        };

        List<Inspection__c> history = InspectionController.getInspections(r.Id);

        Assert.areEqual(2, history.size());
        Assert.areEqual(95, history[0].Score__c);
        Assert.areEqual(70, history[1].Score__c);
    }

    @IsTest
    static void historyRequiresRestaurantId() {
        try {
            InspectionController.getInspections(null);
            Assert.fail('Expected an AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(true);
        }
    }
}
