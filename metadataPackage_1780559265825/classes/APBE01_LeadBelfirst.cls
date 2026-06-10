public with sharing class APBE01_LeadBelfirst {
  Map<Id, Lead> newMap;
  public APBE01_LeadBelfirst() {
    this.newMap = newMap;
  }

  // AAM - COUL-1059: it seems to be unused code, to check if this class is still relevant or has to be deleted 
  // //Should be only one lead at a time
  // public void populateLeadFromSelligent() {
  //   belfirstCall(newMap.keySet());

  //   List<Lead> leadToUpdate = [SELECT Id, CreatedBy.Name FROM Lead WHERE Id IN :newMap.keySet()];

  //   Database.DMLOptions dmlOpts = new Database.DMLOptions();
  //   dmlOpts.AssignmentRuleHeader.useDefaultRule = true;

  //   for (Lead l : leadToUpdate) {
  //     if ('Selligent'.equals(l.CreatedBy.Name)) {
  //       l.setOptions(dmlOpts);
  //     }
  //   }

  //   update leadToUpdate;
  // }

  // //It's mandatory to use a future method to be able to do a callout in a trigger.
  // //In the loop, the trigger will check if the record is created by Selligent.
  // @future(callout=true)
  // private static void belfirstCall(Set<Id> recordIds) {
  //   List<Lead> leads = [
  //     SELECT
  //       Street,
  //       PostalCode,
  //       City,
  //       Country,
  //       Company,
  //       Phone,
  //       NumberOfEmployees,
  //       ER_Legal_Form__c,
  //       ER_Language__c,
  //       ER_Enterprise_Number__c,
  //       CreatedBy.Name,
  //       LeadSource,
  //       Rating,
  //       RecordTypeId,
  //       ER_VAT_Number__c
  //     //    ,BE_Product__c
  //     FROM Lead
  //     WHERE Id IN :recordIds
  //   ];
  //   List<Lead> leadsToUpdate = new List<Lead>();

  //   WSBE01_Belfirst belfirstWebservice = new WSBE01_Belfirst();
  //   Map<String, String> belfirstInfos;
  //   String language;

  //   for (Lead l : leads) {
  //     if ('Selligent'.equals(l.CreatedBy.Name)) {
  //       language = 'FR'.equals(l.ER_Language__c) ? 'fr_BE' : 'nl_BE';
  //       belfirstInfos = belfirstWebservice.getInfos('BE' + l.ER_Enterprise_Number__c, language);
  //       leadsToUpdate.add(updateLead(belfirstInfos, l));
  //     }
  //   }

  //   belfirstWebservice.closeConnection();
  //   update leadsToUpdate;
  // }

  // //Update lead with infos received from belfirst
  // private static Lead updateLead(Map<String, String> infos, Lead l) {
  //   l.Street = infos.get('ADDRESS');
  //   l.PostalCode = infos.get('POSTCODE');
  //   l.City = infos.get('TOWN');
  //   l.Country = infos.get('COUNTRY');
  //   L.Company = String.isBlank(l.Company) ? infos.get('NAME') : l.Company;
  //   l.Phone = String.isBlank(l.Phone) ? infos.get('PHONE') : l.Phone;
  //   l.ER_Legal_Name__c = String.isBlank(l.Company) ? infos.get('NAME') : l.Company;
  //   Integer numberOfEmployees;
  //   try {
  //     numberOfEmployees = Integer.valueOf(infos.get('EMPLOYEE'));
  //   } catch (Exception e) {
  //     //Invalid integer
  //   }
  //   l.NumberOfEmployees = l.NumberOfEmployees == null ? numberOfEmployees : l.NumberOfEmployees;
  //   l.ER_Legal_Form__c = infos.get('TYPE');
  //   l.ER_VAT_Number__c = 'BELGIUM'.equals((l.Country).toUpperCase()) ? 'BE' + l.ER_Enterprise_Number__c : '';
  //   l.Website = infos.get('WEBSITE');
  //   l.Email = 'EMAIL';

  //   //Hardcoded values
  //   l.LeadSource = 'Mobility Landing Page';
  //   //l.BE_Product__c = 'Mobility Solution';
  //   L.Rating = 'Hot';

  //   return l;
  // }
}