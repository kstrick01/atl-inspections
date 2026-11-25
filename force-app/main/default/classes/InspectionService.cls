/**
 * Business logic for inspection data.
 * Keeps the denormalized "latest inspection" fields on Restaurant__c in sync.
 * (A roll-up summary can't return "the score from the most recent inspection",
 * so Apex does it.)
 */
public with sharing class InspectionService {

    /**
     * Georgia reports scores as score/grade, e.g. 90/A, 84/B, 73/C.
     * Below 70 is treated as U (unsatisfactory). Verify these cutoffs against
     * the Georgia DPH food service rules before relying on them.
     */
    public static String gradeFor(Integer score) {
        if (score == null) {
            return null;
        }
        if (score >= 90) {
            return 'A';
        }
        if (score >= 80) {
            return 'B';
        }
        if (score >= 70) {
            return 'C';
        }
        return 'U';
    }

    /**
     * Recomputes Latest_Score__c / Latest_Grade__c / Latest_Inspection_Date__c
     * for the given restaurants. Bulk-safe: two queries and one DML regardless
     * of how many restaurants are passed in.
     */
    public static void refreshLatestScores(Set<Id> restaurantIds) {
        restaurantIds.remove(null);
        if (restaurantIds.isEmpty()) {
            return;
        }

        // Step 1: the most recent inspection date per restaurant
        Map<Id, Date> latestDates = new Map<Id, Date>();
        for (AggregateResult ar : [
            SELECT Restaurant__c rid, MAX(Inspection_Date__c) latest
            FROM Inspection__c
            WHERE Restaurant__c IN :restaurantIds
            WITH USER_MODE
            GROUP BY Restaurant__c
        ]) {
            latestDates.put((Id) ar.get('rid'), (Date) ar.get('latest'));
        }

        // Step 2: fetch the inspection(s) on those dates
        Map<Id, Inspection__c> latestInspections = new Map<Id, Inspection__c>();
        if (!latestDates.isEmpty()) {
            for (Inspection__c insp : [
                SELECT Restaurant__c, Score__c, Grade__c, Inspection_Date__c
                FROM Inspection__c
                WHERE Restaurant__c IN :latestDates.keySet()
                AND Inspection_Date__c IN :latestDates.values()
                WITH USER_MODE
                ORDER BY CreatedDate DESC
            ]) {
                // Guard against restaurants that have other dates in the IN list.
                // If two inspections share a date, the most recently loaded wins.
                if (insp.Inspection_Date__c == latestDates.get(insp.Restaurant__c)
                    && !latestInspections.containsKey(insp.Restaurant__c)) {
                    latestInspections.put(insp.Restaurant__c, insp);
                }
            }
        }

        // Step 3: write the results. Restaurants with no inspections get cleared.
        List<Restaurant__c> updates = new List<Restaurant__c>();
        for (Id restaurantId : restaurantIds) {
            Inspection__c latest = latestInspections.get(restaurantId);
            updates.add(new Restaurant__c(
                Id = restaurantId,
                Latest_Score__c = latest?.Score__c,
                Latest_Grade__c = latest?.Grade__c,
                Latest_Inspection_Date__c = latest?.Inspection_Date__c
            ));
        }

        // allOrNone = false: if a restaurant was deleted in the same transaction
        // (cascade delete of its inspections), don't fail the whole batch.
        List<Database.SaveResult> results = Database.update(updates, false, AccessLevel.USER_MODE);
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                System.debug(LoggingLevel.WARN,
                    'Latest score refresh failed: ' + sr.getErrors()[0].getMessage());
            }
        }
    }
}
