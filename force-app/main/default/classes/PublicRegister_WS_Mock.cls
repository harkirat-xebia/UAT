/**
 * Created by noorgoolamnabee on 16/05/2023.
 */

public with sharing class PublicRegister_WS_Mock implements HttpCalloutMock {
  public HttpResponse respond(HttpRequest req) {
    // Create a fake response
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    if (req.getEndpoint().contains(Constants.PUBLIC_REGISTER_WEBSERVICE_GR)) {
      String json =
        '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><env:Header/><env:Body><m:rgWsPublicAfmMethodResponse xmlns:m="http://gr/gsis/' +
        'rgwspublic/RgWsPublic.wsdl"><RgWsPublicBasicRt_out><m:afm>094438998   </m:afm><m:stopDate xsi:nil="true"/><m:postalAddressNo>147      </m:postalAddressNo><m:doyDescr>ΦΑΕ ΠΕΙΡΑΙΑ</m:doyDescr><m:doy>' +
        '1206</m:doy><m:onomasia>ΥΠΗΡΕΣΙΕΣ ΔΙΑΤΑΚΤΙΚΩΝ ΑΝΩΝΥΜΗ ΕΜΠΟΡΙΚΗ ΕΤΑΙΡΕΙΑ</m:onomasia><m:legalStatusDescr>ΑΕ</m:legalStatusDescr><m:registDate>1996-03-21T00:00:00.000+02:00</m:registDate><m:deactivationFlag>' +
        '1</m:deactivationFlag><m:deactivationFlagDescr>ΕΝΕΡΓΟΣ ΑΦΜ          </m:deactivationFlagDescr><m:postalAddress>ΘΕΣΣΑΛΟΝΙΚΗΣ</m:postalAddress><m:firmFlagDescr>ΕΠΙΤΗΔΕΥΜΑΤΙΑΣ      ' +
        '</m:firmFlagDescr><m:commerTitle>VOUCHERS SERVICES S.A.</m:commerTitle><m:postalAreaDescription>ΜΟΣΧΑΤΟ</m:postalAreaDescription><m:INiFlagDescr>ΜΗ ΦΠ</m:INiFlagDescr><m:postalZipCode>' +
        '18346</m:postalZipCode></RgWsPublicBasicRt_out><arrayOfRgWsPublicFirmActRt_out><m:RgWsPublicFirmActRtUser><m:firmActDescr>ΑΛΛΕΣ ΕΠΑΓΓΕΛΜΑΤΙΚΕΣ, ΤΕΧΝΙΚΕΣ ΚΑΙ ΕΠΙΧΕΙΡΗΜΑΤΙΚΕΣ ΥΠΗΡΕΣΙΕΣ ' +
        'Π.Δ.Κ.Α.</m:firmActDescr><m:firmActKind>1</m:firmActKind><m:firmActKindDescr>ΚΥΡΙΑ</m:firmActKindDescr><m:firmActCode>' +
        '74902000</m:firmActCode></m:RgWsPublicFirmActRtUser><m:RgWsPublicFirmActRtUser><m:firmActDescr>ΑΛΛΕΣ ΥΠΗΡΕΣΙΕΣ ΒΟΗΘΗΤΙΚΕΣ ΤΩΝ ΧΡΗΜΑΤΟΠΙΣΤΩΤΙΚΩΝ, Π.Δ.Κ.Α., ΕΚΤΟΣ ΑΠΟ ΤΙΣ ΑΣΦΑΛΙΣΤΙΚΕΣ ΚΑΙ ΤΑ ΣΥΝΤΑΞΙΟΔΟΤΙΚΑ ' +
        'ΤΑΜΕΙΑ</m:firmActDescr><m:firmActKind>2</m:firmActKind><m:firmActKindDescr>ΔΕΥΤΕΡΕΥΟΥΣΑ</m:firmActKindDescr><m:firmActCode>' +
        '66199900</m:firmActCode></m:RgWsPublicFirmActRtUser></arrayOfRgWsPublicFirmActRt_out><pCallSeqId_out>185441925</pCallSeqId_out><pErrorRec_out><m:errorDescr xsi:nil="true"/><m:errorCode ' +
        'xsi:nil="true"/></pErrorRec_out></m:rgWsPublicAfmMethodResponse></env:Body></env:Envelope>';
      res.setBody(json);
      res.setStatusCode(200);
    } else {
      System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
      res.setBody('jsonString');
      res.setStatusCode(200);
    }
    return res;
  }
}