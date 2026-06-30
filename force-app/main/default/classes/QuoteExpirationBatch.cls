/*
----------------------------------------------------------------------
-- Name          : QuoteExpirationBatch
-- Author        : Harkirat Singh
-- Description   : Daily batch that automatically denies quotes whose
--                 ExpirationDate has passed, but only when the quote
--                 is still in Draft or Offer Presented status.
--                 Approved, Accepted, and Denied quotes are skipped.
--
-- Date          Name              Version   Remarks
-- -----------   ----------------  -------   ----------------------------------
-- Jun-2026      Harkirat Singh    1.0       Initial version
----------------------------------------------------------------------
*/
public class QuoteExpirationBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status
            FROM Quote
            WHERE ExpirationDate < TODAY
            AND Status IN (:Label.LABS_SF_Quote_Status_Draft, 'Offer Presented')
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Quote> scope) {
        for (Quote q : scope) {
            q.Status = Label.LABS_SF_Quote_Status_Denied;
        }
        QuoteTriggerHandler.triggerDisabled = true;
        try {
            Database.update(scope, false);
        } finally {
            QuoteTriggerHandler.triggerDisabled = false;
        }
    }

    public void finish(Database.BatchableContext bc) {}
}
