/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : UpdateSMEOpportunityQuoteQueueable
 * Author          : Harkirat
 * Created Date    : May 18, 2026
 * Last Modified By: Harkirat
 * Last Modified On: May 18, 2026
 * Description     : Updates Opportunity and Quote with Contract IDs after SME contracts are created
 * Called after contract creation to avoid SOQL limits
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  May 18, 2026  │ Harkirat     │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public without sharing class UpdateSMEOpportunityQuoteQueueable implements Queueable {

    //These are SME engagement contract IDs
    private List<Id> contractIds;
    
    public UpdateSMEOpportunityQuoteQueueable(List<Id> contractIds) {
        this.contractIds = contractIds;
    }
    
    public void execute(QueueableContext context) {
        System.debug('=== UPDATE SME OPPORTUNITY & QUOTE QUEUEABLE STARTED ===');
        System.debug('Contract IDs to process: ' + contractIds);
        
        try {
            // Query contracts with related Opportunity and Quote IDs
            List<Contract> contracts = [
                SELECT Id, 
                       ER_OpportunityId__c,
                       ER_QuoteId__c,
                       Status,
                       AccountId,
                       Account.Customer_Domain_Reference__c,
                       Main_Platform__c,
                       Main_Platform__r.Customer_Domain_Reference__c
                FROM Contract
                WHERE Id IN :contractIds
                AND ER_OpportunityId__c != null
            ];
            
            System.debug('Found ' + contracts.size() + ' contracts to process');
            
            if (contracts.isEmpty()) {
                System.debug('No contracts found - exiting');
                return;
            }
            
            // Prepare updates
            Map<Id, Id> oppIdToContractId = new Map<Id, Id>();
            Map<Id, Id> quoteIdToContractId = new Map<Id, Id>();
            Map<Id, String> accountIdToCustomerDomainRef = new Map<Id, String>();
            
            for (Contract c : contracts) {
                if (c.ER_OpportunityId__c != null) {
                    oppIdToContractId.put(c.ER_OpportunityId__c, c.Id);
                }
                if (c.ER_QuoteId__c != null) {
                    quoteIdToContractId.put(c.ER_QuoteId__c, c.Id);
                }
                // Prepare Account updates - only if Main Platform has a value
                if (c.AccountId != null && 
                    c.Main_Platform__c != null && 
                    String.isNotBlank(c.Main_Platform__r.Customer_Domain_Reference__c)) {
                    
                    // Only update if the current value is different or empty
                    if (c.Account.Customer_Domain_Reference__c != c.Main_Platform__r.Customer_Domain_Reference__c) {
                        accountIdToCustomerDomainRef.put(
                            c.AccountId, 
                            c.Main_Platform__r.Customer_Domain_Reference__c
                        );
                        System.debug('Preparing Account update: ' + c.AccountId + 
                                   ' → Customer Domain: ' + c.Main_Platform__r.Customer_Domain_Reference__c);
                    }
                }
            }
            
            // Update Opportunities
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Id oppId : oppIdToContractId.keySet()) {
                oppsToUpdate.add(new Opportunity(
                    Id = oppId,
                    StageName = 'Closed Won',
                    ContractId = oppIdToContractId.get(oppId)
                    //ER_Won_Reason__c = 'Auto-Enrollment'
                ));
                System.debug('Preparing Opportunity update: ' + oppId + ' → Contract: ' + oppIdToContractId.get(oppId));
            }
            
            // Update Quotes
            List<Quote> quotesToUpdate = new List<Quote>();
            for (Id quoteId : quoteIdToContractId.keySet()) {
                quotesToUpdate.add(new Quote(
                    Id = quoteId,
                    ContractId = quoteIdToContractId.get(quoteId)
                ));
                System.debug('Preparing Quote update: ' + quoteId + ' → Contract: ' + quoteIdToContractId.get(quoteId));
            }

            // Update Accounts
            List<Account> accountsToUpdate = new List<Account>();
            for (Id accountId : accountIdToCustomerDomainRef.keySet()) {
                accountsToUpdate.add(new Account(
                    Id = accountId,
                    Customer_Domain_Reference__c = accountIdToCustomerDomainRef.get(accountId)
                ));
                System.debug('Preparing Account update: ' + accountId + 
                           ' → Customer Domain: ' + accountIdToCustomerDomainRef.get(accountId));
            }
            
            // Perform updates
            if (!oppsToUpdate.isEmpty()) {
                update oppsToUpdate;
                System.debug('Successfully updated opp ' + oppsToUpdate.size() + ' Opportunities to Closed Won');
            }
            
            if (!quotesToUpdate.isEmpty()) {
                update quotesToUpdate;
                System.debug('Successfully updated quote' + quotesToUpdate.size() + ' Quotes with Contract IDs');
            }

            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
                System.debug('Successfully updated account' + accountsToUpdate.size() + ' Accounts with Customer Domain Reference');
            }
            
            // Chain to contract activation queueable
            System.debug('=== CHAINING TO CONTRACT ACTIVATION ===');
            
            if (!contractIds.isEmpty()) {
                System.enqueueJob(new ActivateContractsQueueable(contractIds, new List<Id>()));
                System.debug('Enqueued ' + contractIds.size() + ' contracts for activation');
            }
            
            System.debug('=== UPDATE SME OPPORTUNITY & QUOTE QUEUEABLE COMPLETED ===');
            
        } catch (Exception e) {
            System.debug('ERROR in UpdateSMEOpportunityQuoteQueueable: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            System.debug('Line Number: ' + e.getLineNumber());
            logError(contractIds, e.getMessage());
        }
    }
    
    /**
     * Log error for monitoring
     */
    private void logError(List<Id> contractIds, String errorMessage) {
        try {
            System.debug('Logging error for contracts: ' + contractIds);
            System.debug('Error: ' + errorMessage);
        } catch (Exception e) {
            System.debug('Failed to log error: ' + e.getMessage());
        }
    }
}