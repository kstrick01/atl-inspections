/**
 * Async import: fetches one page of inspections, upserts restaurants and
 * inspections by external ID (safe to re-run, no duplicates), then chains
 * itself for the next page. Callout happens before any DML.
 */
public with sharing class InspectionImportJob implements Queueable, Database.AllowsCallouts {

    private static final Integer MAX_PAGES = 50; // safety stop for runaway chains

    private final Date since;
    private final Integer pageNumber;

    public InspectionImportJob(Date since, Integer pageNumber) {
        this.since = since;
        this.pageNumber = pageNumber;
    }

    public void execute(QueueableContext context) {
        List<InspectionApiClient.InspectionRecord> records =
            InspectionApiClient.fetchPage(since, pageNumber);

        upsertRecords(records);

        // Full page means there may be more. Test.isRunningTest(): chained
        // queueables aren't allowed inside Apex tests.
        if (records.size() == InspectionApiClient.PAGE_SIZE
            && pageNumber < MAX_PAGES
            && !Test.isRunningTest()) {
            System.enqueueJob(new InspectionImportJob(since, pageNumber + 1));
        }
    }

    @TestVisible
    private static void upsertRecords(List<InspectionApiClient.InspectionRecord> records) {
        // Map by external ID so the same restaurant isn't upserted twice in one list
        Map<String, Restaurant__c> restaurants = new Map<String, Restaurant__c>();
        Map<String, Inspection__c> inspections = new Map<String, Inspection__c>();

        for (InspectionApiClient.InspectionRecord rec : records) {
            // Skip rows we can't trust rather than failing the whole page
            if (String.isBlank(rec.restaurantId) || String.isBlank(rec.restaurantName)
                || String.isBlank(rec.inspectionId)
                || rec.score == null || rec.inspectionDate == null) {
                continue;
            }

            restaurants.put(rec.restaurantId, new Restaurant__c(
                External_Id__c = rec.restaurantId,
                Name = rec.restaurantName,
                Address__c = rec.address,
                City__c = rec.city,
                Postal_Code__c = rec.postalCode
            ));

            inspections.put(rec.inspectionId, new Inspection__c(
                Source_Id__c = rec.inspectionId,
                // Parent resolved by external ID: no extra query needed
                Restaurant__r = new Restaurant__c(External_Id__c = rec.restaurantId),
                Score__c = rec.score,
                Grade__c = InspectionService.gradeFor(rec.score),
                Inspection_Date__c = rec.inspectionDate
            ));
        }

        // Parents first so child references resolve
        logFailures(Database.upsert(
            restaurants.values(), Restaurant__c.External_Id__c, false, AccessLevel.USER_MODE));
        logFailures(Database.upsert(
            inspections.values(), Inspection__c.Source_Id__c, false, AccessLevel.USER_MODE));
    }

    private static void logFailures(List<Database.UpsertResult> results) {
        for (Database.UpsertResult ur : results) {
            if (!ur.isSuccess()) {
                System.debug(LoggingLevel.WARN,
                    'Inspection import row failed: ' + ur.getErrors()[0].getMessage());
            }
        }
    }
}
