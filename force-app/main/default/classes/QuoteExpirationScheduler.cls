/*
----------------------------------------------------------------------
-- Name          : QuoteExpirationScheduler
-- Author        : Harkirat Singh
-- Description   : Schedulable class that triggers QuoteExpirationBatch
--                 daily. Schedule via: System.schedule('Quote Expiration',
--                 '0 0 1 * * ?', new QuoteExpirationScheduler());
--
-- Date          Name              Version   Remarks
-- -----------   ----------------  -------   ----------------------------------
-- Jun-2026      Harkirat Singh    1.0       Initial version
----------------------------------------------------------------------
*/
public class QuoteExpirationScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new QuoteExpirationBatch(), 200);
    }
}
