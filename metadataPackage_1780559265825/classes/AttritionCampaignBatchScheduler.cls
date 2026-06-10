/*
----------------------------------------------------------------------
-- - Name          : AttritionCampaignBatchScheduler 
-- - Author        : Snehil Verma
-- - Description   : Scheduler for AttritionCampaignBatch
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- Nov-2024     Snehil Verma        1.0         Initial version
---------------------------------------------------------------------------------------
*/
public class AttritionCampaignBatchScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AttritionCampaignBatch());
    }
}