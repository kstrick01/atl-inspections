/**
 * Thin controller for the LWC front end. All SOQL uses bind variables
 * (no SOQL injection) and runs in user mode so object/field security applies.
 */
public with sharing class InspectionController {

    private static final Integer MAX_RESULTS = 50;
    private static final Integer MAX_HISTORY = 20;

    @AuraEnabled(cacheable=true)
    public static List<Restaurant__c> searchRestaurants(String searchTerm, String postalCode) {
        String namePattern = '%' + (String.isBlank(searchTerm) ? '' : searchTerm.trim()) + '%';

        if (String.isBlank(postalCode)) {
            return [
                SELECT Id, Name, Address__c, City__c, Postal_Code__c,
                       Latest_Score__c, Latest_Grade__c, Latest_Inspection_Date__c
                FROM Restaurant__c
                WHERE Name LIKE :namePattern
                WITH USER_MODE
                ORDER BY Name
                LIMIT :MAX_RESULTS
            ];
        }

        String zip = postalCode.trim();
        return [
            SELECT Id, Name, Address__c, City__c, Postal_Code__c,
                   Latest_Score__c, Latest_Grade__c, Latest_Inspection_Date__c
            FROM Restaurant__c
            WHERE Name LIKE :namePattern
            AND Postal_Code__c = :zip
            WITH USER_MODE
            ORDER BY Name
            LIMIT :MAX_RESULTS
        ];
    }

    // Not cacheable: called imperatively so history is always fresh.
    @AuraEnabled
    public static List<Inspection__c> getInspections(Id restaurantId) {
        if (restaurantId == null) {
            throw new AuraHandledException('A restaurant is required.');
        }
        return [
            SELECT Id, Score__c, Grade__c, Inspection_Date__c
            FROM Inspection__c
            WHERE Restaurant__c = :restaurantId
            WITH USER_MODE
            ORDER BY Inspection_Date__c DESC
            LIMIT :MAX_HISTORY
        ];
    }
}
