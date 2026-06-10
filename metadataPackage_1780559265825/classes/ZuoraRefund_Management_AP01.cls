/*
----------------------------------------------------------------------
-- - Name          : ZuoraRefund_Management_AP01
-- - Author        : AAZ
-- - Description   : Zuora Refund Management   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- Nov-2021     AAZ                 1.0         Initial version
---------------------------------------------------------------------------------------
*/

public class ZuoraRefund_Management_AP01 {
  /**
   * @author AAZ
   * @date 30/11/2021
   * @description Delete Refund Record if it's a draft
   * @param newRefunds
   */
  public static void deleteRefund(List<Zuora__Refund__c> newRefunds) {
    List<Zuora__Refund__c> listRefundtoDel = new List<Zuora__Refund__c>();

    List<Zuora__Refund__c> listNewRefund = [
      SELECT Id, ER_Post_Process__c
      FROM Zuora__Refund__c
      WHERE Id IN :newRefunds
    ];

    System.debug('>>>>> AAZ - ZuoraRefund_Management_AP01 deleteRefund listNewRefund: ' + listNewRefund);

    for (Zuora__Refund__c re : listNewRefund) {
      if (re.ER_Post_Process__c == 'Delete')
        listRefundtoDel.add(re);
    }

    if (!listRefundtoDel.isEmpty())
      delete listRefundtoDel;
  }
}