// Loads clearly fictional sample data so you can demo the UI without the API.
// Safe to re-run (upserts by external ID).
// Run: sf apex run --file scripts/apex/load-sample-data.apex

List<Restaurant__c> restaurants = new List<Restaurant__c>{
    new Restaurant__c(Name = 'Sample Peach Diner', Address__c = '100 Example St NW',
        City__c = 'Atlanta', Postal_Code__c = '30303', External_Id__c = 'SAMPLE-001'),
    new Restaurant__c(Name = 'Sample Magnolia Grill', Address__c = '200 Example Ave NE',
        City__c = 'Atlanta', Postal_Code__c = '30308', External_Id__c = 'SAMPLE-002'),
    new Restaurant__c(Name = 'Sample Azalea Taqueria', Address__c = '300 Example Blvd',
        City__c = 'Atlanta', Postal_Code__c = '30309', External_Id__c = 'SAMPLE-003'),
    new Restaurant__c(Name = 'Sample Dogwood Cafe', Address__c = '400 Example Rd SW',
        City__c = 'Atlanta', Postal_Code__c = '30303', External_Id__c = 'SAMPLE-004')
};
Database.upsert(restaurants, Restaurant__c.External_Id__c);

Map<String, Id> idsByExternal = new Map<String, Id>();
for (Restaurant__c r : restaurants) {
    idsByExternal.put(r.External_Id__c, r.Id);
}

List<Inspection__c> inspections = new List<Inspection__c>{
    // Improved over time: latest should show 95/A
    new Inspection__c(Source_Id__c = 'SAMPLE-I-001', Restaurant__c = idsByExternal.get('SAMPLE-001'),
        Score__c = 82, Grade__c = 'B', Inspection_Date__c = Date.today().addDays(-180)),
    new Inspection__c(Source_Id__c = 'SAMPLE-I-002', Restaurant__c = idsByExternal.get('SAMPLE-001'),
        Score__c = 95, Grade__c = 'A', Inspection_Date__c = Date.today().addDays(-30)),
    // Single recent C
    new Inspection__c(Source_Id__c = 'SAMPLE-I-003', Restaurant__c = idsByExternal.get('SAMPLE-002'),
        Score__c = 74, Grade__c = 'C', Inspection_Date__c = Date.today().addDays(-60)),
    // Old and low: shows the U grade and the "over a year ago" warning
    new Inspection__c(Source_Id__c = 'SAMPLE-I-004', Restaurant__c = idsByExternal.get('SAMPLE-003'),
        Score__c = 66, Grade__c = 'U', Inspection_Date__c = Date.today().addDays(-400))
    // SAMPLE-004 intentionally has no inspections: shows "No inspection on file"
};
Database.upsert(inspections, Inspection__c.Source_Id__c);

System.debug('Loaded ' + restaurants.size() + ' restaurants and ' + inspections.size() + ' inspections.');
