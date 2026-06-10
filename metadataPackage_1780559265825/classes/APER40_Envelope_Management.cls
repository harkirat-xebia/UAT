/*
----------------------------------------------------------------------
-- - Name          : APER40_Envelope_Management
-- - Author        : Snica
-- - Description   : Envelope Management, This class is used to group all the functionnality linked to the object Envelope
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- Aug-2022    snica               1.0         Initial version.
---------------------------------------------------------------------------------------
*/
public class APER40_Envelope_Management {
  /**
   * @author snica
   * @date 03/08/2022
   * @description - Docusign - Fill signature information automatically
   * @param contracts
   */
  public static void fillSignatureInformation(Map<Id, SObject> newItems) {
    Set<String> quoteIds = new Set<String>();
    List<Contract> contracts = new List<Contract>();

    for (dfsle__EnvelopeStatus__c env : [
      SELECT Id, dfsle__SourceId__c
      FROM dfsle__EnvelopeStatus__c
      WHERE Id IN :newItems.keySet()
    ]) {
      quoteIds.add(env.dfsle__SourceId__c);
    }

    for (Quote qte : [SELECT ContractId, ContactId, Contact.Title, Id FROM Quote WHERE Id IN :quoteIds]) {
      for (Contract crt : [
        SELECT
          CustomerSignedId,
          CustomerSignedTitle,
          Id,
          CustomerSignedDate,
          CompanySignedId,
          CompanySignedDate,
          ER_QuoteId__c
        FROM Contract
        WHERE Id = :qte.ContractId
      ]) {
        contracts.add(crt);
      }
    }

    for (Contract item : contracts) {
      for (Quote qte : [SELECT ContractId, ContactId, Contact.Title, Id FROM Quote WHERE Id = :item.ER_QuoteId__c]) {
        item.CustomerSignedId = qte.ContactId;
        item.CustomerSignedTitle = qte.Contact.Title;
      }

      for (dfsle__EnvelopeStatus__c env : [
        SELECT dfsle__Completed__c, OwnerId
        FROM dfsle__EnvelopeStatus__c
        WHERE dfsle__SourceId__c = :item.ER_QuoteId__c AND dfsle__Status__c = 'Completed'
      ]) {
        item.CustomerSignedDate = (env.dfsle__Completed__c).date();
        item.CompanySignedId = env.OwnerId;
        item.CompanySignedDate = (env.dfsle__Completed__c).date();
      }
    }
    update contracts;
  }
}