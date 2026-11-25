/**
 * Nightly refresh. Schedule once from Anonymous Apex:
 *
 *   System.schedule('Nightly Atlanta Inspection Import', '0 0 2 * * ?',
 *       new InspectionImportScheduler());
 */
public with sharing class InspectionImportScheduler implements Schedulable {

    private static final Integer LOOKBACK_DAYS = 7;

    public void execute(SchedulableContext context) {
        System.enqueueJob(new InspectionImportJob(Date.today().addDays(-LOOKBACK_DAYS), 1));
    }
}
