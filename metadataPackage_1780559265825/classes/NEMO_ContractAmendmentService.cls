public without sharing class NEMO_ContractAmendmentService {

    public static NEMO_ContractAmendmentTypes.ApplyResult applyLineChanges(
        String contractId,
        Id amendmentOppId,
        List<NEMO_ContractAmendmentTypes.ChangeDTO> changes
    ) {
        NEMO_ContractAmendmentTypes.ApplyResult res = new NEMO_ContractAmendmentTypes.ApplyResult();

        // Collect match keys
        Set<Id> cliIds = new Set<Id>();
        Set<Id> product2Ids = new Set<Id>();

        for (NEMO_ContractAmendmentTypes.ChangeDTO c : changes) {
            if (c == null || c.match == null) continue;
            if (String.isNotBlank(c.match.cliId)) cliIds.add((Id)c.match.cliId);
            if (String.isNotBlank(c.match.product2Id)) product2Ids.add((Id)c.match.product2Id);
        }

        Map<Id, Id> cliToProduct2 = new Map<Id, Id>();
        if (!cliIds.isEmpty()) {
            for (ER_ContractLineItem__c cli : [
                SELECT Id, ER_Product2__c
                FROM ER_ContractLineItem__c
                WHERE Id IN :cliIds
                  AND ER_Contract__c = :contractId
            ]) {
                cliToProduct2.put(cli.Id, cli.ER_Product2__c);
                if (cli.ER_Product2__c != null) product2Ids.add(cli.ER_Product2__c);
            }
        }

        Opportunity opp = [
            SELECT Id, Pricebook2Id, CurrencyIsoCode
            FROM Opportunity
            WHERE Id = :amendmentOppId
            LIMIT 1
        ];

        Map<Id, OpportunityLineItem> product2ToOli = new Map<Id, OpportunityLineItem>();
        if (!product2Ids.isEmpty()) {
            for (OpportunityLineItem oli : [
                SELECT Id, Product2Id, PricebookEntryId,
                       Quantity, UnitPrice, Discount,
                       ER_Percentage__c, ER_Min__c, ER_Max__c, ER_Line_Type__c,
                       ER_Offer_validity_end_date__c,
                       ER_MPV__c,
                       ER_Edenred_Margin_TUR__c,
                       ER_Free_To_Set_Margin__c,
                       ER_Cumulative_with_Promotions__c
                FROM OpportunityLineItem
                WHERE OpportunityId = :amendmentOppId
                  AND Product2Id IN :product2Ids
            ]) {
                product2ToOli.put(oli.Product2Id, oli);
            }
        }

        List<OpportunityLineItem> toUpdate = new List<OpportunityLineItem>();
        List<OpportunityLineItem> toInsert = new List<OpportunityLineItem>();

        for (NEMO_ContractAmendmentTypes.ChangeDTO c : changes) {
            if (c == null || c.match == null) continue;

            String action = String.isBlank(c.action) ? 'UPDATE' : c.action.trim().toUpperCase();
            Id product2Id;

            if (String.isNotBlank(c.match.product2Id)) {
                product2Id = (Id)c.match.product2Id;
            } else if (String.isNotBlank(c.match.cliId)) {
                product2Id = cliToProduct2.get((Id)c.match.cliId);
            }

            if (product2Id == null) {
                throw new AuraHandledException('No matching Product found for change: ' + JSON.serialize(c.match));
            }

            OpportunityLineItem existing = product2ToOli.get(product2Id);

            if (action == 'ADD' || existing == null) {
                OpportunityLineItem oli = new OpportunityLineItem();
                oli.OpportunityId = amendmentOppId;
                oli.Product2Id = product2Id;
                oli.PricebookEntryId = findPricebookEntryId(opp.Pricebook2Id, opp.CurrencyIsoCode, product2Id);

                applyUpdates(oli, c.updates);
                toInsert.add(oli);
            } else {
                applyUpdates(existing, c.updates);
                toUpdate.add(existing);
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] sr = Database.update(toUpdate, false);
            for (Database.SaveResult r : sr) {
                if (r.isSuccess()) res.updatedLineItemIds.add((String)r.getId());
                else throw new AuraHandledException('OLI update failed: ' + r.getErrors()[0].getMessage());
            }
        }

        if (!toInsert.isEmpty()) {
            Database.SaveResult[] sr = Database.insert(toInsert, false);
            for (Database.SaveResult r : sr) {
                if (r.isSuccess()) res.createdLineItemIds.add((String)r.getId());
                else throw new AuraHandledException('OLI insert failed: ' + r.getErrors()[0].getMessage());
            }
        }

        return res;
    }

    private static void applyUpdates(OpportunityLineItem oli, NEMO_ContractAmendmentTypes.UpdatesDTO u) {
        if (u == null) return;

        if (u.quantity != null) oli.Quantity = u.quantity;
        if (u.unitPrice != null) oli.UnitPrice = u.unitPrice;
        if (u.discount != null) oli.Discount = u.discount;

        if (u.percentage != null) oli.ER_Percentage__c = u.percentage;
        if (u.min != null) oli.ER_Min__c = u.min;
        if (u.max != null) oli.ER_Max__c = u.max;
        if (u.lineType != null) oli.ER_Line_Type__c = u.lineType;
        if (u.offerValidityEndDate != null) oli.ER_Offer_validity_end_date__c = u.offerValidityEndDate;

        if (u.mpv != null) oli.ER_MPV__c = u.mpv;
        if (u.edenredMarginTur != null) oli.ER_Edenred_Margin_TUR__c = u.edenredMarginTur;

        if (u.freeToSetMargin != null) oli.ER_Free_To_Set_Margin__c = u.freeToSetMargin;
        if (u.cumulativeWithPromotions != null) oli.ER_Cumulative_with_Promotions__c = u.cumulativeWithPromotions;
    }

    private static Id findPricebookEntryId(Id pricebook2Id, String currencyIsoCode, Id product2Id) {
    List<PricebookEntry> pbes;

    if (String.isBlank(currencyIsoCode)) {
        // Org not using multi-currency or currency is not set
        pbes = [
            SELECT Id
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebook2Id
              AND Product2Id = :product2Id
              AND IsActive = true
            LIMIT 1
        ];
    } else {
        // Multi-currency org: match opp currency
        pbes = [
            SELECT Id
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebook2Id
              AND Product2Id = :product2Id
              AND IsActive = true
              AND CurrencyIsoCode = :currencyIsoCode
            LIMIT 1
        ];
    }

    if (pbes.isEmpty()) {
        throw new AuraHandledException(
            'No active PricebookEntry found for Product2=' + product2Id +
            ' in Pricebook=' + pricebook2Id +
            (String.isBlank(currencyIsoCode) ? '' : (' currency=' + currencyIsoCode))
        );
    }
    return pbes[0].Id;
}

}