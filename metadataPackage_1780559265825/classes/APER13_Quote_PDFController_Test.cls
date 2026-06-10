/*
----------------------------------------------------------------------
-- - Name          : LCER01_Quote_PDFController_Test
-- - Author        : OLA
-- - Description   : test class of LCER01_Quote_PDFController
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Feb-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class APER13_Quote_PDFController_Test {
  @testSetup
  static void testSetup() {
    Account merchantAccount = APER07_UtilityTestMethod.getCompany('testCompany');
    insert merchantAccount;

    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Merchant_Opportunity',
      'APER13_Quote_PDFController_Test'
    );
    insert newOpportunity;

    Contact c = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'APER13', 'APER13');
    insert c;

    Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
      'ER_Merchant_Quote',
      'APER13_Quote_PDFController_Test',
      newOpportunity.id,
      null
    );
    merchantQuote.ContactId = c.Id;
    insert merchantQuote;
  }

  static testMethod void testSavePDF() {
    Quote testQuote = [SELECT Id, Name FROM Quote ORDER BY CreatedDate DESC LIMIT 1];
    APER13_Quote_PDFController.savePDF('TEST', testQuote.Id, true);
  }

  static testMethod void testPreviewPDF() {
    Quote testQuote = [SELECT Id, Name FROM Quote ORDER BY CreatedDate DESC LIMIT 1];
    APER13_Quote_PDFController.previewPDF('TEST');
  }

  static testMethod void testGetTemplates() {
    APER13_Quote_PDFController.getTemplates();
  }
}