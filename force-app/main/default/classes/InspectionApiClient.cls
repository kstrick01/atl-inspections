/**
 * Calls the inspection data endpoint through the Named Credential
 * "Atlanta_Inspection_API" (create it in Setup; no URL or secret lives in code).
 *
 * Expected response: a JSON array, e.g.
 * [{
 *   "restaurantId":   "FSP-060-001234",
 *   "restaurantName": "Sample Peach Diner",
 *   "address":        "100 Example St NW",
 *   "city":           "Atlanta",
 *   "postalCode":     "30303",
 *   "inspectionId":   "INS-2026-000987",
 *   "score":          92,
 *   "inspectionDate": "2026-10-14"
 * }]
 *
 * Request: GET /inspections?since=YYYY-MM-DD&page=1&pageSize=200
 */
public with sharing class InspectionApiClient {

    public static final Integer PAGE_SIZE = 200;

    public class ApiException extends Exception {}

    public class InspectionRecord {
        public String restaurantId;
        public String restaurantName;
        public String address;
        public String city;
        public String postalCode;
        public String inspectionId;
        public Integer score;
        public Date inspectionDate;
    }

    public static List<InspectionRecord> fetchPage(Date since, Integer pageNumber) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Atlanta_Inspection_API/inspections'
            + '?since=' + String.valueOf(since)
            + '&page=' + pageNumber
            + '&pageSize=' + PAGE_SIZE);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new ApiException('Inspection API returned HTTP ' + res.getStatusCode());
        }
        return (List<InspectionRecord>) JSON.deserialize(res.getBody(), List<InspectionRecord>.class);
    }
}
