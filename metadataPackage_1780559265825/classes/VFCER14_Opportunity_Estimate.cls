/*
----------------------------------------------------------------------
-- - Name          : VFCER14_Opportunity_Estimate
-- - Author        : Noor
-- - Description   : Controller VFCER14_Opportunity_Estimate used for button Estimate
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  02/06/2022       Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public with sharing class VFCER14_Opportunity_Estimate {
  public Opportunity opportunityRecord { get; set; }

  public List<OpportunityLineItem> lineItems { get; set; }

  public VFCER14_Opportunity_Estimate(ApexPages.StandardController controller) {
    Map<String, OpportunityLineItem> lineItemPerSolution = new Map<String, OpportunityLineItem>();
    opportunityRecord = new Opportunity();

    if (String.isNotBlank(controller.getId())) {
      opportunityRecord = [
        SELECT
          Id,
          Name,
          (
            SELECT
              Id,
              Solution__c,
              Solution__r.Name,
              ER_Face_Value__c,
              ER_Days_Per_Month__c,
              ER_Nb_Beneficiaries__c,
              ER_Load_Per_Year__c,
              ER_Estimated_Value__c
            FROM OpportunityLineItems
          )
        FROM Opportunity
        WHERE Id = :controller.getId()
      ];

      for (OpportunityLineItem item : opportunityRecord.OpportunityLineItems) {
        lineItemPerSolution.put(item.Solution__r.Name, item);
      }

      lineItems = lineItemPerSolution.values();
    }
  }

  /**
   * @author Noor
   * @date 01/06/2022 (dd/mm/yyyy)
   * @description estimate : redirect to VFER14_Opportunity_Estimate Page.
   */
  public PageReference saveItems() {
    List<OpportunityLineItem> itemsToUpdate = new List<OpportunityLineItem>();
    Map<Id, OpportunityLineItem> valueMap = new Map<Id, OpportunityLineItem>();

    for (OpportunityLineItem item : lineItems)
      valueMap.put(item.Solution__c, item);

    for (OpportunityLineItem item : opportunityRecord.OpportunityLineItems) {
      OpportunityLineItem newItem = new OpportunityLineItem(Id = item.Id);
      newItem.ER_Face_Value__c = valueMap.get(item.Solution__c).ER_Face_Value__c;
      newItem.ER_Nb_Beneficiaries__c = valueMap.get(item.Solution__c).ER_Nb_Beneficiaries__c;
      newItem.ER_Load_Per_Year__c = valueMap.get(item.Solution__c).ER_Load_Per_Year__c;
      newItem.ER_Days_Per_Month__c = valueMap.get(item.Solution__c).ER_Days_Per_Month__c;
      itemsToUpdate.add(newItem);
    }

    if (!itemsToUpdate.isEmpty())
      update itemsToUpdate;

    PageReference pageRef = new PageReference('/' + opportunityRecord.Id);
    pageRef.setRedirect(true);
    return pageRef;
  }
}