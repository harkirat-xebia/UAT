/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SMEPlatformEngagementQueueable
 * Author          : Harkirat 
 * Created Date    : May 20, 2026
 * Last Modified By: Harkirat 
 * Last Modified On: May 20, 2026
 * Description     : To reduce the 101 SOQL
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  May 20, 2026  │ Harkirat     │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

/**
 * Queueable class to create SME Platform engagement records
 * Runs in separate transaction with fresh governor limits
 * @author Harkirat
 */
public without sharing class SMEPlatformEngagementQueueable implements Queueable {
    
    private List<Id> contractIds;
    
    public SMEPlatformEngagementQueueable(List<Id> contractIds) {
        this.contractIds = contractIds;
    }
    
    public void execute(QueueableContext context) {
        // System.debug('=== SME PLATFORM QUEUEABLE STARTED ===');
        // System.debug('Processing ' + contractIds.size() + ' contracts');
        // System.debug('Contract IDs: ' + contractIds);
        // System.debug('User: ' + UserInfo.getUserId());
        // System.debug('User: ' + UserInfo.getProfileId());   
        
        try {
            // Re-query contracts with all needed information
            Map<Id, Contract> contractsWithDetails = new Map<Id, Contract>([
                SELECT Id, Status, AccountId, Account.Name,
                       ER_OpportunityId__c,
                       ER_OpportunityId__r.CampaignId,
                       ER_OpportunityId__r.ER_Promo_Code2__c,
                       ER_OpportunityId__r.ER_Promo_Code2__r.Create_SME_Platform_Engagement__c,
                       ER_OpportunityId__r.ER_Promo_Code2__r.ER_Business_Unit__c,
                       ER_OpportunityId__r.Name,
                       ER_OpportunityId__r.ER_Won_Reason__c,
                       ER_OpportunityId__r.ER_Solutions__c,
                       ER_OpportunityId__r.ER_Estimated_Number_Of_Beneficiaries__c,
                       ER_OpportunityId__r.OwnerId,
                       ER_OpportunityId__r.Preferred_Language__c,
                       ER_OpportunityId__r.RecordTypeId,
                       OwnerId, CreatedBy.Name, StartDate, EndDate, CurrencyIsoCode,
                       Primary_Contact__c, Billing_Contact__c, Owner.Name,
                       CustomerSignedDate, CustomerSignedId
                FROM Contract
                WHERE Id IN :contractIds
            ]);


            if (contractsWithDetails.isEmpty()) {
                System.debug('No contracts found to process');
                return;
            }
            
            /*List<Contract> contracts = contractsWithDetails.values();
            
            if (contracts.isEmpty()) {
                System.debug('No contracts found to process');
                return;
            }*/
            
            // Call your existing sync method
            //System.debug('Step 2: Calling createSMEPlatformEngagementSync');
            List<Id> createdSMEContractIds = APER12_Contract_Management.createSMEPlatformEngagementSync(
                contractIds, 
                contractsWithDetails
            );
            //System.debug('=== SME PLATFORM QUEUEABLE COMPLETED SUCCESSFULLY ===');

			//CHAIN THE SECOND QUEUEABLE HERE (AFTER EVERYTHING IS CREATED)
            /*if (createdSMEContractIds != null && !createdSMEContractIds.isEmpty()) {

                System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(createdSMEContractIds));
                System.debug('Chained UpdateSMEOpportunityQuoteQueueable for ' + createdSMEContractIds.size() + ' contracts');
            }*/
            if (createdSMEContractIds != null && !createdSMEContractIds.isEmpty()) {
                //System.debug('Created SME Contract IDs: ' + createdSMEContractIds);
            }

            if (createdSMEContractIds != null && !createdSMEContractIds.isEmpty()) {
                //System.debug('Step 3: Checking queueable limits before chaining');
                System.debug('Current queueable jobs: ' + Limits.getQueueableJobs() + 
                           '/' + Limits.getLimitQueueableJobs());
                
                if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
                    // System.debug('Step 4: Enqueuing UpdateSMEOpportunityQuoteQueueable');
                    // System.debug('Passing ' + createdSMEContractIds.size() + ' SME contract IDs');
                    
                     System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(createdSMEContractIds));
                    
                    // System.debug('Successfully chained UpdateSMEOpportunityQuoteQueueable');
                } else {
                    //System.debug('WARNING: Queueable limit reached, cannot chain');
                }
            } else {
                //System.debug('No SME contracts created, skipping chained queueable');
            }

        } catch (Exception e) {
            //System.debug('ERROR in SME Platform Queueable');
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }

}