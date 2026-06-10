/*
----------------------------------------------------------------------
-- - Name          : ZuoraCreditMemo_Management_AP01
-- - Author        : AAZ
-- - Description   : Zuora CreditMem Management   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- Nov-2021     AAZ                 1.0         Initial version
---------------------------------------------------------------------------------------
*/

public class ZuoraCreditMemo_Management_AP01 {
  /**
   * @author AAZ
   * @date 29/11/2021
   * @description Delete CreditMemo Record if it's a draft
   * @param newCreditMemo
   * @param oldCreditMemo
   */
  public static void deleteCreditMemo(List<Zuora__CreditMemo__c> newCreditMemos) {
    List<Zuora__CreditMemo__c> listCMtoDel = new List<Zuora__CreditMemo__c>();

    List<Zuora__CreditMemo__c> listNewCM = [
      SELECT Id, ER_Post_Process__c
      FROM Zuora__CreditMemo__c
      WHERE Id IN :newCreditMemos
    ];

    System.debug('>>>>> AAZ - ZuoraCreditMemo_Management_AP01 deleteCreditMemo listnewCM: ' + listNewCM);

    for (Zuora__CreditMemo__c cm : listNewCM) {
      if (cm.ER_Post_Process__c == 'Delete')
        listCMtoDel.add(cm);
    }

    if (!listCMtoDel.isEmpty())
      delete listCMtoDel;
  }
}