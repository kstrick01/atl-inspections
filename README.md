# Atlanta Restaurant Inspections (Salesforce)

A DoorDash-style "inspection score" feature built on Salesforce: Apex backend, LWC front end.

## What's in the project

| Piece | Files |
|---|---|
| Data model | `Restaurant__c`, `Inspection__c` (master-detail) and their fields |
| Trigger + service | `InspectionTrigger`, `InspectionService` (keeps latest score on the restaurant) |
| Controller | `InspectionController` (`searchRestaurants`, `getInspections`) |
| Integration | `InspectionApiClient`, `InspectionImportJob` (Queueable), `InspectionImportScheduler` |
| LWC | `restaurantInspectionList` (search + history), `inspectionBadge` (grade pill) |
| Tests | `InspectionServiceTest`, `InspectionControllerTest`, `InspectionImportTest` |
| Demo data | `scripts/apex/load-sample-data.apex` (fictional restaurants only) |

## Deploy

```
sf org login web -a myorg
sf project deploy start -d force-app -o myorg
sf apex run --file scripts/apex/load-sample-data.apex -o myorg
sf apex run test --test-level RunLocalTests --result-format human --wait 10 -o myorg
```

Then in Lightning App Builder, create an App Page and drop in **Restaurant Inspection List**.

## Connecting a real data source

The import code expects a JSON endpoint reached through a Named Credential called
`Atlanta_Inspection_API` (create it in Setup > Named Credentials; no URLs or secrets live in code).

Request: `GET /inspections?since=YYYY-MM-DD&page=1&pageSize=200`

Response: a JSON array of

```json
{
  "restaurantId": "FSP-060-001234",
  "restaurantName": "Sample Peach Diner",
  "address": "100 Example St NW",
  "city": "Atlanta",
  "postalCode": "30303",
  "inspectionId": "INS-2026-000987",
  "score": 92,
  "inspectionDate": "2026-10-14"
}
```

I did not find an official public API or bulk download for Atlanta-area scores. Fulton County
publishes its latest inspections on its website, and Georgia DPH runs a statewide inspection portal.
Before pulling data from either, check their terms of use, and consider asking the health
department whether they offer a data feed. If you build a small adapter service that returns the JSON
above, the Apex side doesn't change.

Schedule the nightly refresh from Anonymous Apex:

```apex
System.schedule('Nightly Atlanta Inspection Import', '0 0 2 * * ?', new InspectionImportScheduler());
```

## Things to verify

- Grade cutoffs in `InspectionService.gradeFor` (A 90-100, B 80-89, C 70-79, U below 70) were inferred
  from published Georgia scores (e.g. 90/A, 84/B, 73/C). Confirm against the current Georgia DPH rules.
- Apex classes use `WITH USER_MODE`, so non-admin users need object and field access. Create a permission
  set for the two objects before sharing with other users.
- Matching restaurants across data sources (inspection records vs. delivery listings) is a separate hard
  problem: normalize addresses and names, and decide how to handle low-confidence matches.
