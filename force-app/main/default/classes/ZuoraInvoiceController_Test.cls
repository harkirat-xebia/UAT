/*
----------------------------------------------------------------------
-- - Name          : ZuoraInvoiceController_Test
-- - Author        : AAZ
-- - Description   : Test class for ZuoraInvoiceController   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- SEPT-2022     AAZ                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/

@isTest
public class ZuoraInvoiceController_Test {
  @IsTest
  static void getProformaPDF() {
    Test.startTest();
    SmarterAPIMock smarterMock = new SmarterAPIMock();
    Test.setMock(HttpCalloutMock.class, smarterMock);

    String file = ZuoraInvoiceController.getProformaPDF('ORD1234567', 'INVOICE', 'FR', '');
    System.assertNotEquals(null, file);
    Test.stopTest();
  }
}