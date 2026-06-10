/**
 * @author: ALK
 * @date: 07/02/2022
 * @desc: Medallia_Feedback_Management
 * @see: Medallia_Feedback_Management
 */

public with sharing class Medallia_Feedback_Management {
  /**
   * @author ALK
   * @date 07/02/2022
   * @description Create Medallia Cases
   * @param items
   * @see APER08_Case_Management
   */
 /* public static void createMedalliaCases(List<medallia_xm__Medallia_Feedback__c> items) {
    List<Id> medalliaFeedbackListIds = new List<Id>();

    for (medallia_xm__Medallia_Feedback__c mf : items) {
      if (mf.medallia_xm__Alert_Yn_Flag__c == Constants.YES)
        medalliaFeedbackListIds.add(mf.Id);
    }

    if (!medalliaFeedbackListIds.isEmpty())
      APER08_Case_Management.createMedalliaCases(medalliaFeedbackListIds);
  }*/

  /**
   * @author ALK
   * @date 21/03/2022
   * @description - Devops 15290 - Autopopulate the individual lookup
   * @param items
   */
  /*public static void fillInIndividualLookup(List<medallia_xm__Medallia_Feedback__c> items) {
    Map<Id, List<medallia_xm__Medallia_Feedback__c>> mapContactFeedbacks = new Map<Id, List<medallia_xm__Medallia_Feedback__c>>();

    for (medallia_xm__Medallia_Feedback__c mf : items) {
      if (mf.medallia_xm__Contact_Id__c != null) {
        if (!mapContactFeedbacks.containsKey(mf.medallia_xm__Contact_Id__c))
          mapContactFeedbacks.put(mf.medallia_xm__Contact_Id__c, new List<medallia_xm__Medallia_Feedback__c>());
        mapContactFeedbacks.get(mf.medallia_xm__Contact_Id__c).add(mf);
      }
    }

    for (Contact c : [
      SELECT Id, AccountId, Email, LastName, FirstName
      FROM Contact
      WHERE Id IN :mapContactFeedbacks.keySet() AND IsPersonAccount = TRUE
    ]) {
      for (medallia_xm__Medallia_Feedback__c mf : mapContactFeedbacks.get(c.Id)) {
        mf.ER_Individual_Id__c = c.AccountId;
        mf.ER_Individual_Email__c = c.Email;
        mf.ER_Individual_Firstname__c = c.FirstName;
        mf.ER_Individual_Lastname__c = c.LastName;
      }
    }
  }*/
}