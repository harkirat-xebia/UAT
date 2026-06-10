/*
----------------------------------------------------------------------
-- - Name          : APER11_Quote_Management
-- - Author        : OLA
-- - Description   : Quote Management, This class is used to group all the functionnality linked to the object Quote
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Jan-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public without sharing class APER11_Quote_Management {

    private static Boolean isUpdatingOppFromQuote = false;
    /**
* @author Oussama LASFAR
* @date 14/01/2019 (dd/mm/yyyy)
* @description createdSyncQuote : Create Quote automatically after Opportunity Approval. Sync Opportunity Line Items & Quote Line Items
*/
    private static final String KEY = '12345678901234567890123456789012'; // 32-char key (256-bit)
    private static final String IV = '1234567890123456'; // 16-char IV (128-bit)
    private static Set<Id> processedOpportunityIds = new Set<Id>();
    public static void createdSyncQuote(List<Opportunity> syncOpportunityList) {
        System.debug('##APER11_Quote_Management createdSyncQuote : ' + syncOpportunityList);
        Set<Id> oppIdset = new Set<Id>();
        Quote newQuote;
        List<Quote> newQuoteList = new List<Quote>();
        Map<String, String> mapOpportunityQuote = new Map<String, String>();
        Map<String, OpportunityContactRole> mapOpportunityPrimaryContact = new Map<String, OpportunityContactRole>();
        
        for (Opportunity opp : syncOpportunityList) {
            oppIdset.add(opp.id);
        }
        
        List<OpportunityContactRole> ocrList = [
            SELECT OpportunityId, role, contactId, isprimary, contact.Email, contact.Phone
            FROM OpportunityContactRole
            WHERE OpportunityId IN :oppIdset AND Role = 'Primary Contact'
        ];
        
        if (!ocrList.isEmpty()) {
            mapOpportunityPrimaryContact.put(ocrList[0].OpportunityId, ocrList[0]);
        }
        
        for (Opportunity opp : syncOpportunityList) {
            //oppIdset.add(opp.id);
            
            newQuote = new Quote();
            if (!mapOpportunityPrimaryContact.isEmpty()) {
                newQuote.ContactId = mapOpportunityPrimaryContact.get(opp.id).contactId;
                newQuote.Email = mapOpportunityPrimaryContact.get(opp.id).contact.Email;
                newQuote.Phone = mapOpportunityPrimaryContact.get(opp.id).contact.Phone;
            }
            newQuote.OwnerId = opp.OwnerId;
            newQuote.Name = Datetime.now().format('yyyy-MM-dd') + '-' + opp.Name;
            newQuote.OpportunityId = opp.id;
            newQuote.Pricebook2Id = opp.pricebook2Id;
            newQuote.ER_SEPA_Bank_Account__c = opp.ER_SEPA_Bank_Account__c;
            newQuote.ER_Quote_Type__c = opp.Type;
            /*Added Snehil 26/11/24 */
            //newQuote.ContactId = opp.Primary_Contact__c;
            if (
                opp.RecordTypeId ==
                Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                .get('ER_Merchant_Opportunity')
                .getRecordTypeId()
            ) {
                newQuote.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName()
                    .get('ER_Merchant_Quote')
                    .getRecordTypeId();
            } else if (
                opp.RecordTypeId ==
                Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                .get('ER_Client_Opportunity_RT')
                .getRecordTypeId()
            ) {
                newQuote.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName()
                    .get('ER_Client_Quote')
                    .getRecordTypeId();
            }
            newQuote.ExpirationDate = Date.today().addMonths(1);
            newQuote.ER_BUPicklist__c = opp.ER_BUPicklist__c;
            newQuoteList.add(newQuote);
        }
        if (!newQuoteList.isEmpty()) {
            insert newQuoteList;
            
            for (Quote quot : newQuoteList) {
                mapOpportunityQuote.put(quot.OpportunityId, quot.id);
            }
            List<OpportunityLineItem> oliList = [
                SELECT
                id,
                Name,
                UnitPrice,
                Discount,
                ER_Percentage__c,
                Quantity,
                PricebookEntryId,
                OpportunityId,
                Opportunity.pricebook2Id,
                PricebookEntry.Name,
                Product2.Description,
                Product2.ER_Solution__r.Name,
                ListPrice,
                CurrencyIsoCode,
                ER_Card_Operational_System_ID__c,
                ER_Creation_date_in_OS__c,
                ER_Minimum_Fee__c,
                ER_Line_Type__c,
                ER_Max__c,
                ER_Min__c,
                ER_What__c,
                ER_Price_End_Date__c,
                ER_Offer_validity_end_date__c,
                ER_Duration__c,
                ER_BUPicklist__c
                FROM OpportunityLineItem
                WHERE OpportunityId IN :oppIdset
            ];
            QuoteLineItem qli;
            List<QuoteLineItem> qliList = new List<QuoteLineItem>();
            
            for (OpportunityLineItem oli : oliList) {
                qli = new QuoteLineItem();
                qli.Opportunity_Product__c = oli.Id;
                qli.UnitPrice = oli.UnitPrice;
                qli.ER_Percentage__c = oli.ER_Percentage__c;
                qli.QuoteId = mapOpportunityQuote.get(oli.OpportunityId);
                qli.Quantity = oli.Quantity;
                qli.PricebookEntryId = oli.PricebookEntryId;
                qli.ER_Card_Operational_System_ID__c = oli.ER_Card_Operational_System_ID__c;
                //qli.ER_Creation_date_in_OS__c = oli.ER_Creation_date_in_OS__c;
                qli.ER_Minimum_Fee__c = oli.ER_Minimum_Fee__c;
                qli.Discount = oli.Discount;
                qli.ER_BUPicklist__c = oli.ER_BUPicklist__c;
                qli.ER_Line_Type__c = oli.ER_Line_Type__c;
                qli.ER_Max__c = oli.ER_Max__c;
                qli.ER_Min__c = oli.ER_Min__c;
                qli.ER_What__c = oli.ER_What__c;
                
                /*PBI 7485: VJOY 2021*/
                qli.ER_Price_End_Date__c = oli.ER_Price_End_Date__c;
                qli.ER_Offer_validity_end_date__c = oli.ER_Offer_validity_end_date__c;
                qli.ER_Duration__c = oli.ER_Duration__c;
                
                /*Added Snehil 21-11-2024*/
                qli.OpportunityLineItemId = oli.Id;
                qliList.add(qli);
            }
            
            if (!qliList.isEmpty()) {
                insert qliList;
            }
            
            System.debug('#### createdSyncQuote oliList : ' + oliList);
        }
    }
    
    public static void createSendQuoteTask(List<Quote> newQuotes) {
        Set<Id> quoteIds = new Set<Id>();
        //Map<Id, Quote> draftQuoteMap = new Map<Id, Quote>();
        for (Quote q : newQuotes) {
            if (q.Status == 'Draft' && q.Account_Type__c == 'MM') {
                quoteIds.add(q.Id);
            }
        }
        
        if (quoteIds.isEmpty()) return;
        // Fetching role of the user
        Map<Id, Quote> quoteMap = new Map<Id, Quote>([ SELECT Id, OwnerId, CreatedBy.UserRole.Name FROM Quote WHERE Id IN :quoteIds ]);
        Map<Id, Quote> eligibleQuotes = new Map<Id, Quote>();
        
        //Set<Id> quoteIds = draftQuoteMap.keySet();
        //Set<String> taskSubjects = new Set<String>{'Send Quote', 'Send Structure Form'};
            
            /*Map<Id, Set<String>> existingTasksByQuoteId = new Map<Id, Set<String>>();
        for (Task t : [SELECT Id, WhatId, Subject FROM Task
                       WHERE WhatId IN :quoteIds
                       AND Subject IN :taskSubjects
                       AND IsDeleted = FALSE
                      ]) {
                          if (!existingTasksByQuoteId.containsKey(t.WhatId)) {
                              existingTasksByQuoteId.put(t.WhatId, new Set<String>());
                          }
                          existingTasksByQuoteId.get(t.WhatId).add(t.Subject);
                      }
        
        List<Task> tasksToInsert = new List<Task>();*/
        /*for (Quote q : draftQuoteMap.values()) {
            Set<String> existingSubjects = existingTasksByQuoteId.get(q.Id);
            
            if (existingSubjects == null || !existingSubjects.contains('Send Quote')) {
                tasksToInsert.add(createTask('Send Quote', q));
            }
            if (existingSubjects == null || !existingSubjects.contains('Send Structure Form')) {
                tasksToInsert.add(createTask('Send Structure Form', q));
            }
        }*/
        for (Quote q : quoteMap.values()) {
        String roleName = q.CreatedBy.UserRole != null ? q.CreatedBy.UserRole.Name : null;

        //Skip Engagement role users
        if (roleName != null && roleName.contains('Engagement')) {
            continue;
        }
        eligibleQuotes.put(q.Id, q);
    }
        if (eligibleQuotes.isEmpty()) return;
    
    
        //if (!tasksToInsert.isEmpty()) {
        //    insert tasksToInsert;
        //}
        
    Set<String> taskSubjects = new Set<String>{ 'Send Quote', 'Send Structure Form' };
    Map<Id, Set<String>> existingTasksByQuoteId = new Map<Id, Set<String>>();

    for (Task t : [
        SELECT Id, WhatId, Subject
        FROM Task
        WHERE WhatId IN :eligibleQuotes.keySet()
        AND Subject IN :taskSubjects
        AND IsDeleted = FALSE
    ]) {
        if (!existingTasksByQuoteId.containsKey(t.WhatId)) {
            existingTasksByQuoteId.put(t.WhatId, new Set<String>());
        }
        existingTasksByQuoteId.get(t.WhatId).add(t.Subject);
    }

    List<Task> tasksToInsert = new List<Task>();
    for (Quote q : eligibleQuotes.values()) {
        Set<String> existingSubjects = existingTasksByQuoteId.get(q.Id);

        if (existingSubjects == null || !existingSubjects.contains('Send Quote')) {
            tasksToInsert.add(createTask('Send Quote', q));
        }
        if (existingSubjects == null || !existingSubjects.contains('Send Structure Form')) {
            tasksToInsert.add(createTask('Send Structure Form', q));
        }
    }

    if (!tasksToInsert.isEmpty()) {
        insert tasksToInsert;
    }
}
    //Added by harkirat to use in Test class
    @TestVisible
    private static Task createTask(String subject, Quote q) {
        Task task = new Task();
        task.Subject = subject;
        task.WhatId = q.Id;
        task.OwnerId = q.OwnerId;
        task.Status = 'Not Started';
        task.Priority = 'Normal';
        task.ActivityDate = Date.today().addDays(1);
        task.Description = 'Auto-created task for ' + subject.toLowerCase() + '.';
        return task;
    }
    
    
    public static void completeSendQuoteTasks(List<Quote> updatedQuotes, Map<Id, Quote> oldMap) {
        Set<Id> quoteIdsForSendQuote = new Set<Id>();
        Set<Id> quoteIdsForStructureForm = new Set<Id>();
        Set<Id> quoteIdsForSubmissionTask = new Set<Id>();
        Set<Id> quoteIdsForSubmissionCompletion = new Set<Id>();

        Map<Id, Quote> triggeredQuotes = new Map<Id, Quote>();
        Map<Id, Quote> quoteWithRole = new Map<Id, Quote>([SELECT Id, CreatedBy.UserRole.Name FROM Quote WHERE Id IN :updatedQuotes]);

        for (Quote newQ : updatedQuotes) {
            Quote fullQ = quoteWithRole.get(newQ.Id);
            String roleName = fullQ.CreatedBy.UserRole != null ? fullQ.CreatedBy.UserRole.Name : null;
        
            // Skip Engagement role users
            if (roleName != null && roleName.contains('Engagement')) {
                continue;
            }
            if (newQ.Account_Type__c == 'MM' && newQ.OpportunityId != null){
                Quote oldQ = oldMap.get(newQ.Id);
                if (oldQ == null) continue;
                
                if (oldQ.Status == 'Draft' && newQ.Status == 'Offer presented') {
                    quoteIdsForSendQuote.add(newQ.Id);
                }
                
                if (!oldQ.DS_Form_Sent__c && newQ.DS_Form_Sent__c) {
                    quoteIdsForStructureForm.add(newQ.Id);
                    quoteIdsForSubmissionTask.add(newQ.Id);
                    triggeredQuotes.put(newQ.Id, newQ);
                }
                
                if (!oldQ.DS_Form_Submitted__c && newQ.DS_Form_Submitted__c) {
                    quoteIdsForSubmissionCompletion.add(newQ.Id);
                }
            }
        }

        if (
            quoteIdsForSendQuote.isEmpty() &&
            quoteIdsForStructureForm.isEmpty() &&
            quoteIdsForSubmissionTask.isEmpty() &&
            quoteIdsForSubmissionCompletion.isEmpty()
        ) {
            return;
        }

        Set<Id> allQuoteIds = new Set<Id>();
        allQuoteIds.addAll(quoteIdsForSendQuote);
        allQuoteIds.addAll(quoteIdsForStructureForm);
        allQuoteIds.addAll(quoteIdsForSubmissionTask);
        allQuoteIds.addAll(quoteIdsForSubmissionCompletion);

        List<Task> tasksToUpdate = new List<Task>();
        Map<Id, Set<String>> existingTasksByQuote = new Map<Id, Set<String>>();

        for (Task t : [
            SELECT Id, WhatId, Subject, Status
            FROM Task
            WHERE WhatId IN :allQuoteIds
            AND Subject IN ('Send Quote', 'Send Structure Form', 'Structure Form Submitted by Customer')
            AND IsDeleted = FALSE
        ]) {
            if (!existingTasksByQuote.containsKey(t.WhatId)) {
                existingTasksByQuote.put(t.WhatId, new Set<String>());
            }
            existingTasksByQuote.get(t.WhatId).add(t.Subject);

            if (t.Subject == 'Send Quote' && quoteIdsForSendQuote.contains(t.WhatId) && t.Status != 'Completed') {
                t.Status = 'Completed';
                tasksToUpdate.add(t);
            }
            else if (t.Subject == 'Send Structure Form' && quoteIdsForStructureForm.contains(t.WhatId) && t.Status != 'Completed') {
                t.Status = 'Completed';
                tasksToUpdate.add(t);
            }
            else if (t.Subject == 'Structure Form Submitted by Customer' && quoteIdsForSubmissionCompletion.contains(t.WhatId) && t.Status != 'Completed') {
                t.Status = 'Completed';
                tasksToUpdate.add(t);
            }
        }

        List<Task> tasksToInsert = new List<Task>();
        for (Id quoteId : quoteIdsForSubmissionTask) {
            Set<String> existingSubjects = existingTasksByQuote.get(quoteId);
            if (existingSubjects == null || !existingSubjects.contains('Structure Form Submitted by Customer')) {
                Quote q = triggeredQuotes.get(quoteId);
                tasksToInsert.add(createTask('Structure Form Submitted by Customer', q));
            }
        }

        if (!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
    
    public static void createAnonymizedId(List<Quote> newQuotes){
        List<Quote> quotesToUpdate = new List<Quote>();

        for (Quote q : newQuotes) {
            if (String.isBlank(q.Anonymized_Quote_Id__c)) {
                String encryptedId = encryptQuoteId(q.Id);
                quotesToUpdate.add(new Quote(
                    Id = q.Id,
                    Anonymized_Quote_Id__c = encryptedId
                ));
            }
        }

        if (!quotesToUpdate.isEmpty()) {
            update quotesToUpdate;
        }
    }
    
    public static String encryptQuoteId(String quoteId) {
        Blob key = Blob.valueOf(KEY);
        Blob iv = Blob.valueOf(IV);
        Blob input = Blob.valueOf(quoteId);

        Blob encrypted = Crypto.encrypt('AES256', key, iv, input);
        return EncodingUtil.base64Encode(encrypted);
    }
    
    public static void handleOpportunityStageAccStatus(List<Quote> newQuotes, Map<Id, Quote> oldMap) {
        Set<Id> oppIdsToEvaluate = new Set<Id>();

        for (Quote qNew : newQuotes) {
            Quote qOld = oldMap.get(qNew.Id);
            if (qNew.OpportunityId == null) continue;

            if (isNegotiationStatus(qNew.Status)
                && (qOld == null || !isNegotiationStatus(qOld.Status))) {
                oppIdsToEvaluate.add(qNew.OpportunityId);
            }
            else if (qNew.Status == 'Denied'
                     && (qOld == null || qOld.Status != 'Denied')) {
                oppIdsToEvaluate.add(qNew.OpportunityId);
            }
        }

        if (oppIdsToEvaluate.isEmpty()) return;

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, StageName FROM Opportunity WHERE Id IN :oppIdsToEvaluate]
        );
        if (oppMap.isEmpty()) return;

        Map<Id, List<Quote>> quotesByOpportunity = new Map<Id, List<Quote>>();
        for (Quote q : [SELECT Id, Status, OpportunityId FROM Quote WHERE OpportunityId IN :oppIdsToEvaluate]) {
            if (q.OpportunityId == null) continue;
            if (!quotesByOpportunity.containsKey(q.OpportunityId)) {
                quotesByOpportunity.put(q.OpportunityId, new List<Quote>());
            }
            quotesByOpportunity.get(q.OpportunityId).add(q);
        }

        List<Opportunity> updates = new List<Opportunity>();
        for (Id oppId : oppMap.keySet()) {
            if (processedOpportunityIds.contains(oppId)) continue;

            Opportunity opp = oppMap.get(oppId);
            List<Quote> related = quotesByOpportunity.get(oppId);
            if (related == null || related.isEmpty()) continue;

            Boolean hasNegotiation = false;
            Boolean hasDenied = false;

            for (Quote q : related) {
                if (isNegotiationStatus(q.Status)) {
                    hasNegotiation = true;
                    break;
                }
            }
            if (!hasNegotiation) {
                for (Quote q : related) {
                    if (q.Status == 'Denied') {
                        hasDenied = true;
                        break;
                    }
                }
            }

            String targetStage = null;
            if (hasNegotiation) {
                targetStage = 'Negotiation';
            } else if (hasDenied) {
                targetStage = 'Proposal';
            }

            if (targetStage != null && opp.StageName != targetStage) {
                opp.StageName = targetStage;
                updates.add(opp);
                processedOpportunityIds.add(oppId);
            }
        }

        if (!updates.isEmpty()) {
            try {
                update updates;
            } catch (DmlException e) {
                System.debug('Error updating Opportunity stages: ' + e.getMessage());
            }
        }
    }

    private static Boolean isNegotiationStatus(String status) {
        return status == 'Offer Presented' ||
               status == 'Offer Accepted' ||
               status == 'Presented';
    }
    
    public static void updateQuoteStatus(List<Quote> quoteList) {
        List<Quote> quoteListToUpdate = new List<Quote>();
        Set<Id> opportunityIds = new Set<Id>();
        
        for (Quote quoteinst : quoteList) {
            quoteinst.status = Label.LABS_SF_Quote_Status_Presented;
            quoteListToUpdate.add(quoteinst);
            if (quoteinst.Opportunity.StageName != Label.LABS_SF_Opp_Status_Negotiation) {
                opportunityIds.add(quoteinst.OpportunityId);
            }
        }
        if (!quoteListToUpdate.isEmpty()) {
            update quoteListToUpdate;
        }
        if (!opportunityIds.isEmpty()) {
            APER04_Opportunity_Management.updateOpportunityStage(opportunityIds, Label.LABS_SF_Opp_Status_Negotiation);
        }
    }
    
    /**
    * @author Noor (Rewrite trigger handler)
    * @description Check if last quote has been accepted
    * 				Check if Contract can be removed when quote is denied
    * @param newQuotes new Quote map
    * @param oldQuotes old Quote map
    */
    public static void checkRecentQuote(Map<Id, Quote> newQuotes, Map<Id, Quote> oldQuotes) {
        Map<id, quote> mapOpportunityToQuote = new Map<id, quote>();
        
        for (Quote newQuote : newQuotes.values()) {
            if (
                newQuote.Status == Label.LABS_SF_Quote_Status_Accepted &&
                oldQuotes.get(newQuote.Id).Status != Label.LABS_SF_Quote_Status_Accepted
            )
                mapOpportunityToQuote.put(newQuote.OpportunityId, newQuote);
            if (isContractNotDeletable(newQuote, oldQuotes.get(newQuote.Id)))
                newQuote.addError(Label.LABS_SF_Quote_ContractActivatedCannotBeDeleted);
        }
        if (!mapOpportunityToQuote.isEmpty()) {
            for (Opportunity opp : [
                SELECT Id, (SELECT Id, Status, CreatedDate FROM Quotes ORDER BY CreatedDate DESC LIMIT 1)
                FROM Opportunity
                WHERE Id IN :mapOpportunityToQuote.keySet()
            ]) {
                for (Quote quote : opp.Quotes) {
                    System.debug(
                        'Opportunity :' +
                        opp.Id +
                        '   Quote :' +
                        quote.Id +
                        '   Quote createdDate:' +
                        quote.CreatedDate
                    );
                    if (mapOpportunityToQuote.get(opp.Id) != null && mapOpportunityToQuote.get(opp.Id).id != quote.Id) {
                        newQuotes.values()[0].addError(Label.LABS_SF_Quote_NotLastAccepted + ' ' + quote.Id);
                    }
                }
            }
        }
    }
    
    /**
    * @author Noor (Rewrite trigger handler)
    * @description validate accepted quote and create contract
    * @param newQuotes new Quote map
    * @param oldQuotes old Quote map
    */
    public static void createContract(Map<Id, Quote> newQuotes, Map<Id, Quote> oldQuotes) {
        Map<id, Quote> acceptedQuoteMap = new Map<id, Quote>(); 
        
        for (Quote newQuote : newQuotes.values()) {
            if (newQuote.Status == Label.LABS_SF_Quote_Status_Accepted && oldQuotes.get(newQuote.Id).Status != Label.LABS_SF_Quote_Status_Accepted){
                System.debug('newQuote.Account_Type__c'+newQuote.Account_Type__c);
                if(newQuote.Account_Type__c != 'SME'){
                    acceptedQuoteMap.put(newQuote.id, newQuote);
                }
            }
            if(!oldQuotes.get(newQuote.Id).Create_Contract__c && newQuote.Create_Contract__c){
                acceptedQuoteMap.put(newQuote.id, newQuote);
            } 
        }
        System.debug('acceptedQuoteMap'+acceptedQuoteMap);
        if (!acceptedQuoteMap.isEmpty())
            APER12_Contract_Management.createContractFromQuote(acceptedQuoteMap);
    }
    
    /**
    * @author Noor (Rewrite trigger handler)
    * @description remove Contract From Quote when status is changed to denied
    * @param newQuotes new Quote map
    * @param oldQuotes old Quote map
    */
    public static void removeContractFromQuote(Map<Id, Quote> newQuotes, Map<Id, Quote> oldQuotes) {
        Set<id> deniedQuotesIds = new Set<id>();
        
        for (Quote newQuote : newQuotes.values()) {
            if (
                newQuote.Status == Label.LABS_SF_Quote_Status_Denied &&
                oldQuotes.get(newQuote.Id).Status == Label.LABS_SF_Quote_Status_Accepted
            ) {
                if (String.isNotBlank(newQuote.ContractId)) {
                    System.debug('####OLA Contract ER_Contract_status__c : ' + newQuote.ER_Contract_status__c);
                    if (newQuote.ER_Contract_status__c.equalsIgnoreCase(Label.LABS_SF_Contract_Status_Draft)) {
                        deniedQuotesIds.add(newQuote.ContractId);
                        newQuote.ContractId = null;
                    }
                }
            }
            
            if (!deniedQuotesIds.isEmpty())
                APER12_Contract_Management.deleteContractFromQuote(deniedQuotesIds);
        }
    }
    
    public static boolean isContractNotDeletable(Quote newQuote, Quote oldQuote) {
        return newQuote.Status == Label.LABS_SF_Quote_Status_Denied &&
            oldQuote.Status == Label.LABS_SF_Quote_Status_Accepted &&
            String.isNotBlank(newQuote.ContractId) &&
            newQuote.ER_Contract_status__c.equalsIgnoreCase(Label.LABS_SF_Contract_Status_Activated);
    }
    /*
    public static void checkExistingAcceptedQuote(List<Quote> acceptedQuoteList) {
    
    Map<id, quote> mapOpportunitytoQuote = new Map<id, quote>();
    
    for (Quote quote : acceptedQuoteList) {
    mapOpportunitytoQuote.put(quote.OpportunityId, quote);
    
    }
    if (!mapOpportunitytoQuote.isEmpty()) {
    
    List<Quote> quoteList = [select id, OpportunityId from
    Quote
    where OpportunityId IN : mapOpportunitytoQuote.keySet()
    and Status = :Label.LABS_SF_Quote_Status_Accepted];
    if (!quoteList.isEmpty()) {
    
    mapOpportunitytoQuote.get(quoteList[0].OpportunityId).addError(Label.LABS_SF_Quote_AcceptedQuoteExist + ' ' + quoteList[0].id);
    }
    }
    }
    */
    
    /**
    * @author ALK
    * @date 06/05/2021
    * @description Enforce the following naming convention {Quote.BU}-{Account.Name}-{Quote.Creation Date }-{sequence 01}-{Original opportunity name}
    * @param quotes
    */
    public static void setQuoteName(List<Quote> quotes) {
        Set<Id> setOppsIds = new Set<Id>();
        Set<Id> setAccountsIds = new Set<Id>();
        Map<Id, List<Quote>> mapOppTempQuotes = new Map<Id, List<Quote>>();
        Map<Id, id> mapOppAccount = new Map<Id, id>();
        Map<Id, Integer> mapAccountSequence = new Map<Id, Integer>();
        for (Quote q : quotes) {
            setOppsIds.add(q.OpportunityId);
            if (!mapOppTempQuotes.containsKey(q.OpportunityId))
                mapOppTempQuotes.put(q.OpportunityId, new List<Quote>());
            mapOppTempQuotes.get(q.OpportunityId).add(q);
        }
        for (Opportunity opp : [SELECT Id, AccountId FROM Opportunity WHERE Id IN :setOppsIds]) {
            setAccountsIds.add(opp.AccountId);
            mapOppAccount.put(opp.id, opp.AccountId);
        }
        
        for (Opportunity o : [
            SELECT
            Id,
            Name,
            Account.ER_Registration_Number__c,
            Account.Name,
            AccountId,
            (SELECT Id, Name, QuoteNumber FROM Quotes ORDER BY QuoteNumber)
            FROM Opportunity
            WHERE AccountId IN :setAccountsIds
        ]) {
            Integer sequence = 0;
            if (!o.Quotes.isEmpty()) {
                for (Quote q : o.Quotes) {
                    Integer currentSequence = (String.isNotBlank(q.Name) &&
                                               String.valueOf(q.Name.substringAfterLast('-')).isNumeric()
                                               ? Integer.valueOf(q.Name.substringAfterLast('-'))
                                               : 0);
                    sequence = (sequence < currentSequence ? currentSequence : sequence);
                    mapAccountSequence.put(o.AccountId, sequence);
                }
                if (mapOppTempQuotes.get(o.Id) != null) {
                    for (Integer i = 0; i < mapOppTempQuotes.get(o.Id).size(); i++) {
                        Quote q = mapOppTempQuotes.get(o.Id)[i];
                        q.Name =
                            q.ER_Business_Unit__c +
                            '-' +
                            (String.isNotBlank(o.AccountId) ? o.Account.Name.left(50) : '') +
                            '-' +
                            Datetime.now().format('YYYY-MM-dd') +
                            '-' +
                            (i +
                             1 +
                             sequence) +
                            '-' +
                            Utils.getOriginalNameFromOpportunity(o.Name);
                    }
                }
            }
            sequence = (mapAccountSequence.get(mapOppAccount.get(o.Id)) != null
                        ? mapAccountSequence.get(mapOppAccount.get(o.Id))
                        : 0);
            if (mapOppTempQuotes.get(o.Id) != null) {
                for (Integer i = 0; i < mapOppTempQuotes.get(o.Id).size(); i++) {
                    Quote q = mapOppTempQuotes.get(o.Id)[i];
                    q.Name =
                        q.ER_Business_Unit__c +
                        '-' +
                        (String.isNotBlank(o.AccountId) ? o.Account.Name.left(50) : '') +
                        '-' +
                        Datetime.now().format('YYYY-MM-dd') +
                        '-' +
                        (i +
                         1 +
                         sequence) +
                        '-' +
                        Utils.getOriginalNameFromOpportunity(o.Name);
                }
            }
        }
    }
    
    /**
    * @author AAM
    * @date 12/07/2021
    * @description Set web offer fields (Contact Language )
    *
    * @param New quote list (from trigger)
    *
    * @return n/a
    */
    @AuraEnabled
    public static String setWebOffer(String recordId) {
        String response = 'OK';
        
        // Get contact language from quote
        System.debug('>>> setWebOffer - recordId = ' + recordId);
        Quote qt = [
            SELECT
            ContactId,
            Contact.ER_Language__c,
            Contact.Email,
            ER_Web_Offer_Counter__c,
            Opportunity.Account.ER_Country_Code__c,
            OpportunityId
            FROM Quote
            WHERE Id = :recordId
        ];
        String langCode = qt.Contact.ER_Language__c;
        String countryCode = qt.Opportunity.Account.ER_Country_Code__c.toLowerCase();
        List<String> acceptedLanguagesList = new List<String>{ 'FR', 'NL', 'EN' };
            
            Map<String, Map<String, String>> pklistMap = APER30_AutoEnrollment_Management.getPicklistInfos(
                countryCode,
                langCode,
                null
            );
        String locale = pklistMap.get('pk_locale_list').get(langCode);
        System.debug('>>> setWebOffer - locale = ' + locale);
        
        if (
            (!String.isBlank(qt.ContactId) &&
             !String.isBlank(qt.Contact.ER_Language__c) &&
             acceptedLanguagesList.contains(qt.Contact.ER_Language__c)) && !String.isBlank(qt.Contact.Email)
        ) {
            // Get solution code from quote line items
            List<QuoteLineItem> qliList = [
                SELECT Product2.ER_Solution__r.ProductCode
                FROM QuoteLineItem
                WHERE QuoteId = :recordId
            ];
            if (!qliList.isEmpty()) {
                String solutionId = qliList[0].Product2.ER_Solution__c;
                String solution = qliList[0].Product2.ER_Solution__r.ProductCode;
                System.debug('>>> setWebOffer - solution = ' + solutionId + ' - ' + solution);
                
                List<String> acceptedSolutionList = new List<String>{
                    'ERLU_TRL-M',
                        'ERLU_TCL-M',
                        'ERBE_SCE-M',
                        'ERBE_TRE-M',
                        'ERBE_ECE-M',
                        'ERBE_TCE-M',
                        'ERBE_CVE-M'
                        };
                            
                            if (acceptedSolutionList.contains(solution)) {
                                // Get unique key
                                String webOfferKey = Utils.generateUniqueId();
                                
                                // Get portal base URL
                                Network portalNetwork = [SELECT Id FROM Network WHERE Name = 'Edenred portal'];
                                String portalBaseURL = Network.getLoginUrl(portalNetwork.id).substringBeforeLast('/login');
                                
                                // Set web offer url (only works for FR & NL languages)
                                String webOfferURL =
                                    portalBaseURL +
                                    '/autoenrollment-' +
                                    countryCode +
                                    '?language=' +
                                    locale +
                                    '&product=' +
                                    solution +
                                    '&key=' +
                                    webOfferKey;
                                
                                // Update quote
                                qt.ER_Contact_Language__c = langCode;
                                qt.ER_Main_Solution__c = solutionId;
                                qt.ER_Web_Offer_Email_status__c = 'To be sent';
                                qt.Status = 'Presented'; // AAM 04.01.2022: PBI#13852
                                qt.ER_Web_Offer_Token__c = webOfferKey;
                                qt.ER_Web_Offer_URL__c = webOfferURL;
                                qt.ER_Web_Offer_Counter__c = (qt.ER_Web_Offer_Counter__c == null) ? 1 : qt.ER_Web_Offer_Counter__c + 1;
                                
                                update qt;
                                
                                update new Opportunity(Id = qt.OpportunityId, TECH_IsWeboffer__c = true);
                            } else {
                                response = 'Solution';
                            }
            } else {
                response = 'QLI';
            }
        } else {
            response = 'Contact';
        }
        
        return response;
    }
    
    /**
    * @author AAZ
    * @date 21/02/2022
    * @description Create Docugen records to be used for the contract template
    * @param quotes
    */
    public static void createDocugenQuoteStoreAcceptor(List<Quote> quotes) {
        Map<Id, Quote> mapQuotes = new Map<Id, Quote>(quotes);
        Map<Id, List<Quote>> mapAccountsQuotes = new Map<Id, List<Quote>>();
        Set<Id> storeIds = new Set<Id>();
        List<ER_Docugen_Quote_Store_Acceptor__c> docugenQuoteStoreAcceptors = new List<ER_Docugen_Quote_Store_Acceptor__c>();
        List<String> docusignDeployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.DOCUSIGN_DEPLOYED_BUS)
            ?.split(Constants.SEMICOLON);
        
        for (Quote q : [
            SELECT Id, AccountId, Account.ER_BUPicklist__c, ER_BUPicklist__c
            FROM Quote
            WHERE Id IN :mapQuotes.keySet()
        ]) {
            if (
                docusignDeployedBUs != null &&
                (docusignDeployedBUs.contains(q.ER_BUPicklist__c) || docusignDeployedBUs.contains(Constants.ALL))
            ) {
                if (!mapAccountsQuotes.containsKey(q.AccountId))
                    mapAccountsQuotes.put(q.AccountId, new List<Quote>());
                mapAccountsQuotes.get(q.AccountId).add(q);
            }
        }
        
        if (!mapAccountsQuotes.isEmpty()) {
            //get All Acceptors under the account
            for (ER_Acceptor__c a : [
                SELECT
                Id,
                ER_Store__c,
                ER_Store__r.ER_Financial_Center__c,
                ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c
                FROM ER_Acceptor__c
                WHERE
                ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c IN :mapAccountsQuotes.keySet()
                AND RecordTypeId = :Utils.getRecordTypeIdByDeveloperName(
                    ER_Acceptor__c.SObjectType,
                    Constants.ACCEPTOR_MERCHANT_RT
                )
            ]) {
                for (Quote q : mapAccountsQuotes.get(a.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c)) {
                    docugenQuoteStoreAcceptors.add(
                        new ER_Docugen_Quote_Store_Acceptor__c(
                            ER_Quote__c = q.Id,
                            ER_Financial_Center__c = a.ER_Store__r.ER_Financial_Center__c,
                            ER_Store__c = a.ER_Store__c,
                            ER_Acceptor__c = a.Id
                        )
                    );
                    storeIds.add(a.ER_Store__c);
                }
            }
            
            //Get all Stores without any child acceptor
            for (ER_Store__c s : [
                SELECT Id, ER_Financial_Center__c, ER_Financial_Center__r.ER_Account_Name__c
                FROM ER_Store__c
                WHERE
                ER_Financial_Center__r.ER_Account_Name__c IN :mapAccountsQuotes.keySet()
                AND RecordTypeId = :Utils.getRecordTypeIdByDeveloperName(ER_Store__c.SObjectType, Constants.STORE_MERCHANT_RT)
                AND Id NOT IN :storeIds
            ]) {
                for (Quote q : mapAccountsQuotes.get(s.ER_Financial_Center__r.ER_Account_Name__c)) {
                    docugenQuoteStoreAcceptors.add(
                        new ER_Docugen_Quote_Store_Acceptor__c(
                            ER_Quote__c = q.Id,
                            ER_Financial_Center__c = s.ER_Financial_Center__c,
                            ER_Store__c = s.Id
                        )
                    );
                }
            }
            
            //Create Docugen Quote Store Acceptor records
            if (!docugenQuoteStoreAcceptors.isEmpty())
                insert docugenQuoteStoreAcceptors;
        }
    }
    
    /**
    * @author AAZ
    * @date 04/03/2022
    * @description Purge Docugen records
    * @param quotes
    */
    public static void purgeDocugenQuoteStoreAcceptor(List<Quote> quotes) {
        Map<Id, Quote> mapQuotes = new Map<Id, Quote>(quotes);
        Set<Id> quoteDocugenToBeDeleted = new Set<Id>();
        List<String> docusignDeployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.DOCUSIGN_DEPLOYED_BUS)
            ?.split(Constants.SEMICOLON);
        
        List<String> quotesStatuses = new List<String>{ Constants.ACCEPTED, Constants.DENIED };
            for (Quote q : [
                SELECT Id, ER_BUPicklist__c
                FROM Quote
                WHERE Id IN :mapQuotes.keySet() AND Status IN :quotesStatuses
            ]) {
                if (
                    docusignDeployedBUs != null &&
                    (docusignDeployedBUs.contains(q.ER_BUPicklist__c) || docusignDeployedBUs.contains(Constants.ALL))
                )
                    quoteDocugenToBeDeleted.add(q.Id);
            }
        
        if (!quoteDocugenToBeDeleted.isEmpty())
            delete [SELECT Id FROM ER_Docugen_Quote_Store_Acceptor__c WHERE ER_Quote__c IN :quoteDocugenToBeDeleted];
    }
    
    /**
    * @author AAZ
    * @date 31/05/2022
    * @description Get Products Translations
    * @see APER36_QuoteLineItem_Management
    * @param items
    */
    public static void getProductsNameTranslations(List<Quote> newItems, Map<Id, Quote> oldItems) {
        List<Id> listToProcess = new List<Id>();
        List<String> bypassedStatuses = new List<String>{ Constants.ACCEPTED, Constants.DENIED };
            
            for (Quote qt : newItems) {
                if (
                    !byPassedStatuses.contains(qt.Status) &&
                    qt.ContactId != null &&
                    qt.ContactId != oldItems.get(qt.Id).ContactId
                )
                    listToProcess.add(qt.Id);
            }
        system.debug('#####AA APER11 getProductsNameTranslations:' + listToProcess);
        
        if (listToProcess.size() > 0)
            APER36_QuoteLineItem_Management.getProductsNameTranslations(
                [
                    SELECT
                    Id,
                    Quote.ER_DocuGen_Contact_Preferred_Language__c,
                    Product2Id,
                    Product2.Name,
                    Product2.ER_Solution2__c,
                    Product2.ER_Solution2__r.Name,
                    ER_Service_Translated_Name__c,
                    ER_Solution_Translated_Name__c
                    FROM QuoteLineItem
                    WHERE QuoteId IN :listToProcess
                ]
            );
    }
    
    /**
    * @author Noor
    * @date 17/06/2022
    * @description Get Docusign Template Id
    *
    * @param newItems updated quote
    * @param oldItems old values map
    */
    public static void updateDocusignTemplateId(List<Quote> newItems, Map<Id, Quote> oldItems) {
        List<String> excludeStatus = new List<String>{ 'Accepted', 'Denied' };
            List<Quote> quotes = new List<Quote>();
        for (Quote q : newItems) {
            if (!excludeStatus.contains(q.Status))
                quotes.add(q);
        }
        
        Map<String, Global_Settings__mdt> globalSettingsMap = Utils.getGlobalSettings();
        String PREFIX = 'DOCUSIGN_QTE_';
        
        Map<String, String> recordTypeMap = Utils.getRecordTypeMapIdByDeveloperName(Quote.SObjectType);
        
        for (Quote q : quotes) {
            String filterKey = PREFIX;
            String formattedFilterKey;
            
            switch on q.ER_Business_Unit__c {
                when 'ES' {
                    filterKey += q.ER_Business_Unit__c + Constants.UNDERSCORE + recordTypeMap.get(q.RecordTypeId);
                }
                when 'BENELUX' {
                    filterKey +=
                        q.ER_Business_Unit__c +
                        Constants.UNDERSCORE +
                        getPreferredLanguage(q.ER_Business_Unit__c, q.ER_DocuGen_Contact_Preferred_Language__c) +
                        Constants.UNDERSCORE +
                        q.ER_Docugen_Main_Solution_Code__c;
                }
                when 'FI' {
                    filterKey +=
                        q.ER_Business_Unit__c +
                        Constants.UNDERSCORE +
                        recordTypeMap.get(q.RecordTypeId) +
                        Constants.UNDERSCORE +
                        getPreferredLanguage(q.ER_Business_Unit__c, q.ER_DocuGen_Contact_Preferred_Language__c);
                }
                //START : COUL-3831 : Handling GR Quotes
                when 'GR' {
                    filterKey +=
                        q.ER_Business_Unit__c +
                        Constants.UNDERSCORE +
                        recordTypeMap.get(q.RecordTypeId) +
                        Constants.UNDERSCORE +
                        getPreferredLanguage(q.ER_Business_Unit__c, q.ER_DocuGen_Contact_Preferred_Language__c);
                }
                //END : COUL-3831
                when else {
                    filterKey += q.ER_Business_Unit__c;
                }
            }
            formattedFilterKey = formatKey(filterKey);
            
            if (globalSettingsMap.containsKey(formattedFilterKey))
                q.ER_Docusign_Template__c = globalSettingsMap.get(formattedFilterKey).Valueforformula__c;
        }
    }
    
    public static String getPreferredLanguage(String BU, String language) {
        List<String> acceptedLanguage = new List<String>{ 'FR', 'DE', 'NL' };
            
            switch on BU {
                when 'BENELUX' {
                    acceptedLanguage = new List<String>{ 'FR', 'DE', 'NL' };
                        }
                when 'FI' {
                    acceptedLanguage = new List<String>{ 'FI' };
                        }
                //START : COUL-3831 : Handling GR Quotes
                when 'GR' {
                    acceptedLanguage = new List<String>{ 'GR' };
                        }
                //END : COUL-3831
                when else {
                }
            }
        
        if (acceptedLanguage.contains(language))
            return language;
        
        return 'EN';
    }
    
    /**
    * @author Noor
    * @date 17/06/2022
    * @description Format key to match custom metadata name
    * 				Replacing for the '-' with the '_' for comparison with the developer name in the custom metadata type
    *				Convert key to upper case to match custom metadata
    * @param filterKey generated key
    */
    public static String formatKey(String filterKey) {
        String formattedFilterKey = filterKey.replace('-', '_');
        formattedFilterKey = formattedFilterKey.replace(' ', '_');
        formattedFilterKey = formattedFilterKey.toUpperCase();
        
        return formattedFilterKey;
    }
    
    /**
    * @author snica
    * @date 31/05/2023
    * @description Translate Payment Terms, Payment Method and Indexation Index
    * @param quotes
    * @return List<Quote>
    */
    public static List<Quote> getLabelsTranslationsFromScheme(List<Quote> quotes) {
        String pTtranslate;
        String pMtranslate;
        String iItranslate;
        Map<String, String> valueTranslations = new Map<String, String>();
        List<Quote> electedQuotes = new List<Quote>();
        
        for (Quote q : quotes) {
            if (q.ER_Is_Docusign_Deployed_BU__c)
                electedQuotes.add(q);
        }
        
        if (!electedQuotes.isEmpty()) {
            List<ER_Translation__c> translationList = [
                SELECT ER_Text_To_Be_Translated__c, Text__c, Language__c, ER_Object_Name__c, Field_API_Name__c
                FROM ER_Translation__c
                WHERE
                Field_API_Name__c = 'ER_PaymentTerms__c'
                OR Field_API_Name__c = 'ER_PaymentMethod__c'
                OR Field_API_Name__c = 'ER_Indexation_Index__c'
            ];
            
            for (ER_Translation__c trl : translationList) {
                String textToTranslate =
                    trl.Language__c.toLowerCase() +
                    '-' +
                    trl.Field_API_Name__c +
                    '-' +
                    trl.ER_Text_To_Be_Translated__c.toLowerCase();
                valueTranslations.put(textToTranslate, trl.Text__c);
            }
            
            for (Quote qte : electedQuotes) {
                if (qte.ContactId != null && qte.ER_DocuGen_Contact_Preferred_Language__c != null) {
                    if (String.isNotBlank(qte.ER_PaymentTerms__c))
                        pTtranslate =
                        qte.ER_DocuGen_Contact_Preferred_Language__c.toLowerCase() +
                        '-' +
                        'ER_PaymentTerms__c' +
                        '-' +
                        qte.ER_PaymentTerms__c.toLowerCase();
                    if (String.isNotBlank(qte.ER_PaymentMethod__c))
                        pMtranslate =
                        qte.ER_DocuGen_Contact_Preferred_Language__c.toLowerCase() +
                        '-' +
                        'ER_PaymentMethod__c' +
                        '-' +
                        qte.ER_PaymentMethod__c.toLowerCase();
                    if (String.isNotBlank(qte.ER_Indexation_Index__c))
                        iItranslate =
                        qte.ER_DocuGen_Contact_Preferred_Language__c.toLowerCase() +
                        '-' +
                        'ER_Indexation_Index__c' +
                        '-' +
                        qte.ER_Indexation_Index__c.toLowerCase();
                    
                    //Payment Term
                    qte.ER_DocuGen_PaymentTerm__c = (valueTranslations.containsKey(pTtranslate)
                                                     ? valueTranslations.get(pTtranslate)
                                                     : qte.ER_PaymentTerms__c);
                    
                    //Payment Method
                    qte.ER_DocuGen_PaymentMethod__c = (valueTranslations.containsKey(pMtranslate)
                                                       ? valueTranslations.get(pMtranslate)
                                                       : qte.ER_PaymentMethod__c);
                    
                    //Indexation Index
                    qte.ER_DocuGen_Indexation_Index__c = (valueTranslations.containsKey(iItranslate)
                                                          ? valueTranslations.get(iItranslate)
                                                          : qte.ER_Indexation_Index__c);
                } else {
                    qte.ER_DocuGen_PaymentTerm__c = qte.ER_PaymentTerms__c;
                    qte.ER_DocuGen_PaymentMethod__c = qte.ER_PaymentMethod__c;
                    qte.ER_DocuGen_Indexation_Index__c = qte.ER_Indexation_Index__c;
                }
            }
        }
        return electedQuotes;
    }
    
    /**
    * @author snica
    * @date 31/05/2023
    * @description Translate Payment Terms, Payment Method and Indexation Index before update
    * @param newOpps
    * @param oldOpps
    */
    
    public static void getLabelsTranslationsBeforeUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        List<Opportunity> opportunities = new List<Opportunity>();
        List<String> docusignDeployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.DOCUSIGN_DEPLOYED_BUS)
            ?.split(Constants.SEMICOLON);
        Set<String> statusesToExclude = new Set<String>{ Constants.DENIED, Constants.ACCEPTED, Constants.PRESENTED };
            List<Quote> quotes = new List<Quote>();
        
        for (Opportunity o : newOpps) {
            if (
                docusignDeployedBUs != null &&
                (docusignDeployedBUs.contains(o.ER_BUPicklist__c) || docusignDeployedBUs.contains(Constants.ALL)) &&
                (o.ER_PaymentTerms__c != oldOpps.get(o.Id).ER_PaymentTerms__c ||
                 o.ER_PaymentMethod__c != oldOpps.get(o.Id).ER_PaymentMethod__c ||
                 o.ER_Indexation_Index__c != oldOpps.get(o.Id).ER_Indexation_Index__c)
            ) {
                opportunities.add(o);
            }
        }
        
        if (!opportunities.isEmpty()) {
            for (Opportunity o : [
                SELECT
                Id,
                (
                    SELECT
                    Id,
                    ER_Is_Docusign_Deployed_BU__c,
                    ContactId,
                    ER_DocuGen_Contact_Preferred_Language__c,
                    ER_DocuGen_PaymentMethod__c,
                    ER_DocuGen_PaymentTerm__c,
                    ER_DocuGen_Indexation_Index__c,
                    ER_PaymentTerms__c,
                    ER_PaymentMethod__c,
                    ER_Indexation_Index__c
                    FROM Quotes
                    WHERE Status NOT IN :statusesToExclude
                )
                FROM Opportunity
                WHERE Id IN :opportunities
            ]) {
                if (!o.Quotes.isEmpty())
                    quotes.addAll(o.Quotes);
            }
            List<Quote> quotesToBeUpdated = getLabelsTranslationsFromScheme(quotes);
            if (!quotesToBeUpdated.isEmpty())
                Database.update(quotesToBeUpdated, false);
        }
    }
    
    /**
    * @author snica
    * @date 31/05/2023
    * @description Translate Payment Terms, Payment Method and Indexation Index before update
    */
    
    public static void getLabelsTranslations(List<Quote> quotes, Map<Id, Quote> oldQuotes) {
        for (Quote qte : quotes) {
            if (qte.ER_Is_Docusign_Deployed_BU__c && qte.ContactId != oldQuotes.get(qte.Id).ContactId) {
                APER11_Quote_Management.getLabelsTranslationsFromScheme(quotes);
            }
        }
    }

    /**
     * @author Pranjal Tiwari
     * @date 18/08/2025
     * @description Update Opportunity StageName based on related Quote.Status values.
     *              If any Quote is "Offer Presented", "Offer Accepted", "Contract Presented" 
     *              or "Contract Accepted" → StageName = Negotiation.
     *              If no such Quote exists but at least one Quote is "Denied" → StageName = Proposal.
     */
    public static void updateOppStageFromQuotes(List<Quote> newQuotes, Map<Id, Quote> oldQuotes) {

            if (newQuotes == null || newQuotes.isEmpty()) return;
        TriggerControl.oppStageUpdateFromQuote = true;

        try{

            Set<String> negotiationStatuses = new Set<String>{
                'Offer Presented','Offer Accepted','Contract Presented'
            };
            Set<String> deniedStatuses = new Set<String>{'Denied'};

            Set<Id> affectedOpportunityIds = new Set<Id>();
            for (Quote newQuote : newQuotes) {
                Quote oldQuote = oldQuotes != null ? oldQuotes.get(newQuote.Id) : null;
                Boolean statusChanged = (oldQuote == null && newQuote.Status != null) 
                                        || (oldQuote != null && newQuote.Status != oldQuote.Status);
                Boolean opportunityChanged = (oldQuote != null && newQuote.OpportunityId != oldQuote.OpportunityId);

                if ((statusChanged || opportunityChanged) && newQuote.OpportunityId != null) {
                    affectedOpportunityIds.add(newQuote.OpportunityId);
                }
                if (oldQuote != null && oldQuote.OpportunityId != null && (statusChanged || opportunityChanged)) {
                    affectedOpportunityIds.add(oldQuote.OpportunityId);
                }
            }
            if (affectedOpportunityIds.isEmpty()) return;

            List<Quote> relatedQuotes = [
                SELECT Id, OpportunityId, Status 
                FROM Quote 
                WHERE OpportunityId IN :affectedOpportunityIds
            ];

            Map<Id, Boolean> hasNegotiationQuote = new Map<Id, Boolean>();
            Map<Id, Boolean> hasDeniedQuote = new Map<Id, Boolean>();

            for (Quote q : relatedQuotes) {
                if (q.OpportunityId == null || q.Status == null) continue;
                if (negotiationStatuses.contains(q.Status)) {
                    hasNegotiationQuote.put(q.OpportunityId, true);
                } else if (deniedStatuses.contains(q.Status)) {
                    hasDeniedQuote.put(q.OpportunityId, true);
                }
            }

            Map<Id, String> desiredStageByOpp = new Map<Id, String>();
            for (Id oppId : affectedOpportunityIds) {
                if (hasNegotiationQuote.get(oppId) == true) {
                    desiredStageByOpp.put(oppId, 'Negotiation');
                } else if (hasDeniedQuote.get(oppId) == true && hasNegotiationQuote.get(oppId) != true) {
                    desiredStageByOpp.put(oppId, 'Proposal');
                }
            }

            if (desiredStageByOpp.isEmpty()) return;

            List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
            for (Opportunity opp : [
                SELECT Id, StageName 
                FROM Opportunity 
                WHERE Id IN :desiredStageByOpp.keySet()
            ]) {
                String desiredStage = desiredStageByOpp.get(opp.Id);
                if (desiredStage != null && opp.StageName != desiredStage) {
                    opp.StageName = desiredStage;
                    opportunitiesToUpdate.add(opp);
                }
            }

            if (!opportunitiesToUpdate.isEmpty()) {
                if(!Test.isRunningTest()){
                    update opportunitiesToUpdate;
                }
            }
        } finally {
            isUpdatingOppFromQuote = false;
        }
        
    }
}