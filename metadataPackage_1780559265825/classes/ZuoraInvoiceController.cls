/**
 * @author : AAZ
 * @date : 26/09/2022
 * @desc : ZuoraInvoiceController
 * @see ZuoraInvoiceController
 */

public with sharing class ZuoraInvoiceController {
  @AuraEnabled
  public static String getProformaPDF(String invoiceNumber, String invoiceType, String bu, String proformaVersion) {
    return ZuoraUtils.getInvoicePDF(invoiceNumber, invoiceType, bu, proformaVersion);
  }
}