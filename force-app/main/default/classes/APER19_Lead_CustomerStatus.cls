/*
----------------------------------------------------------------------
-- - Name          : APER19_Lead_CustomerStatus
-- - Author        : Copilot
-- - Description   : Classifies a Lead as Prospect or Existing Customer by matching the lead's
--                   business identifier (registration number, or
--                   RCS number for Luxembourg) against accounts that hold at least one activated
--                   contract.
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Aug-2026       Copilot             1.0         Initial version
--  Sep-2026       Copilot             1.1         Added Luxembourg RCS number matching
---------------------------------------------------------------------------------------
*/
// without sharing: classification must not vary with the running user's visibility of Account/Contract.
public without sharing class APER19_Lead_CustomerStatus {
  /**
   * @author Copilot
   * @date Aug 2026
  * @description Sets customer_status__c on every supplied lead. Designed for before insert /
  *              before update, so no DML is performed.
   * @param leads records being inserted or updated
   * @param oldItems Trigger.oldMap on update, null on insert
   */
  public static void evaluateCustomerStatusAndMotion(List<Lead> leads, Map<Id, SObject> oldItems) {
    if (!UtilsBypass.canTrigger('APER19_Lead_CustomerStatus'))
      return;
    if (leads == null || leads.isEmpty())
      return;

    // Luxembourg leads are identified by RCS number; every other BU keeps using the registration number.
    Map<String, List<Lead>> leadsByRegNumber = new Map<String, List<Lead>>();
    Map<String, List<Lead>> leadsByRcs = new Map<String, List<Lead>>();

    for (Lead l : leads) {
      Boolean isLuxembourg = l.ER_BUPicklist__c == Constants.LU;
      String identifier = normalizeIdentifier(isLuxembourg ? l.RCS_Number__c : l.ER_Registration_Number__c);

      if (String.isBlank(identifier)) {
        l.customer_status__c = Constants.LEAD_CUSTOMER_STATUS_PROSPECT;
        continue;
      }

      if (oldItems != null) {
        Lead oldLead = (Lead) oldItems.get(l.Id);
        String oldIdentifier = oldLead == null
          ? null
          : normalizeIdentifier(isLuxembourg ? oldLead.RCS_Number__c : oldLead.ER_Registration_Number__c);
        if (identifier == oldIdentifier)
          continue;
      }

      Map<String, List<Lead>> bucket = isLuxembourg ? leadsByRcs : leadsByRegNumber;
      if (!bucket.containsKey(identifier))
        bucket.put(identifier, new List<Lead>());
      bucket.get(identifier).add(l);
    }

    if (leadsByRegNumber.isEmpty() && leadsByRcs.isEmpty())
      return;

    if (!leadsByRegNumber.isEmpty())
      applyClassification(leadsByRegNumber, getRegNumbersWithActiveContract(leadsByRegNumber.keySet()));

    if (!leadsByRcs.isEmpty())
      applyClassification(leadsByRcs, getRcsNumbersWithActiveContract(leadsByRcs.keySet()));
  }

  /**
   * @author Copilot
   * @date Sep 2026
  * @description Applies the Existing Customer / Prospect classification to every lead in a bucket.
   * @param leadsByIdentifier leads grouped by their matching business identifier
   * @param identifiersWithActiveContract subset of identifiers already holding an activated contract
   */
  private static void applyClassification(
    Map<String, List<Lead>> leadsByIdentifier,
    Set<String> identifiersWithActiveContract
  ) {
    for (String identifier : leadsByIdentifier.keySet()) {
      Boolean isExistingCustomer = identifiersWithActiveContract.contains(identifier);

      for (Lead l : leadsByIdentifier.get(identifier)) {
        l.customer_status__c = isExistingCustomer
          ? Constants.LEAD_CUSTOMER_STATUS_EXISTING
          : Constants.LEAD_CUSTOMER_STATUS_PROSPECT;

        if (isExistingCustomer && String.isBlank(l.Lead_motion__c))
          l.Lead_motion__c = Constants.LEAD_MOTION_CROSS_SELLING;
      }
    }
  }

  /**
   * @author Copilot
   * @date Aug 2026
   * @description Single aggregate query returning the registration numbers that already hold an
   *              activated contract. Grouping caps the row count at the number of distinct
   *              registration numbers instead of the number of contracts.
   * @param regNumbers registration numbers to test
   * @return Set<String> subset of regNumbers belonging to an existing customer
   */
  private static Set<String> getRegNumbersWithActiveContract(Set<String> regNumbers) {
    Set<String> result = new Set<String>();
    String companyRtId = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_COMPANY_RT);

    for (AggregateResult ar : [
      SELECT Account.ER_Registration_Number__c identifier
      FROM Contract
      WHERE
        Status = :Constants.ACTIVATED
        AND Account.RecordTypeId = :companyRtId
        AND Account.ER_Registration_Number__c IN :regNumbers
      GROUP BY Account.ER_Registration_Number__c
    ]) {
      result.add((String) ar.get('identifier'));
    }

    return result;
  }

  /**
   * @author Copilot
   * @date Sep 2026
   * @description Same as getRegNumbersWithActiveContract, but matching Luxembourg accounts by
   *              RCS number instead of registration number.
   * @param rcsNumbers RCS numbers to test
   * @return Set<String> subset of rcsNumbers belonging to an existing customer
   */
  private static Set<String> getRcsNumbersWithActiveContract(Set<String> rcsNumbers) {
    Set<String> result = new Set<String>();
    String companyRtId = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_COMPANY_RT);

    for (AggregateResult ar : [
      SELECT Account.RCS_Number__c identifier
      FROM Contract
      WHERE
        Status = :Constants.ACTIVATED
        AND Account.RecordTypeId = :companyRtId
        AND Account.RCS_Number__c IN :rcsNumbers
      GROUP BY Account.RCS_Number__c
    ]) {
      result.add((String) ar.get('identifier'));
    }

    return result;
  }

  /**
   * @author Copilot
   * @date Aug 2026
   * @description Trims the identifier so that whitespace introduced by API or data loader inserts
   *              does not silently break the match.
   * @param value raw identifier value
   * @return String trimmed value, or null when blank
   */
  private static String normalizeIdentifier(String value) {
    return String.isBlank(value) ? null : value.trim();
  }
}