/*
----------------------------------------------------------------------
-- - Name          : PromoCodeExpirationBatchScheduler 
-- - Author        : Snehil Verma
-- - Description   : Scheduler for PromoCodeExpirationBatch
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- Jan-2025     Snehil Verma        1.0         Initial version
---------------------------------------------------------------------------------------
*/
public class PromoCodeExpirationBatchScheduler implements Schedulable {
	public void execute(SchedulableContext sc) {
        Database.executeBatch(new PromoCodeExpirationBatch());
    }
}