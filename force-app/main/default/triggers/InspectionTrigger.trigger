trigger InspectionTrigger on Inspection__c (after insert, after update, after delete, after undelete) {
    // One trigger per object, no logic here: collect parents, delegate to the service.
    Set<Id> restaurantIds = new Set<Id>();
    List<Inspection__c> changed = Trigger.isDelete ? Trigger.old : Trigger.new;
    for (Inspection__c insp : changed) {
        restaurantIds.add(insp.Restaurant__c);
    }
    InspectionService.refreshLatestScores(restaurantIds);
}
