public class APER09_DatedConversionRate_Management {
  static String isoCode = '';
  static String conversionRate = '';
  static String startDate = '';

  @Future(callout=true)
  public static void getDailyRates(List<String> CurrencyTypeList) {
    Dom.Document doc = callECBws();
    Dom.XMLNode root = doc.getRootElement();
    parseXML(root, CurrencyTypeList);
  }

  public static void updateDatedConversionRate(String isoCode, String conversionRate, String startDate) {
    try {
      System.debug('### IN updateDatedConversionRate ' + isoCode + ' - ' + conversionRate + ' - ' + startDate);
      Http h = new Http();
      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v28.0/sobjects/DatedConversionRate/'
      );
      req.setBody(
        '{ "IsoCode" : "' +
        isoCode +
        '", "ConversionRate" : ' +
        conversionRate +
        ', "StartDate" : "' +
        startDate +
        '" }'
      );
      req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
      req.setHeader('Content-Type', 'application/json');
      req.setMethod('POST');
      HttpResponse res = h.send(req);
      System.debug('### updateDatedConversionRate HttpResponse : ' + res);
      if (res.getStatusCode() != null && String.valueOf(res.getStatusCode()).startsWith('2')) {
      }
    } catch (Exception e) {
      System.debug('### APER09_DatedConversionRate_Management updateDatedConversionRate Exception : ' + e);
      throw new DatedConversionRateException(e);
    }
  }
  public static Dom.Document callECBws() {
    try {
      System.debug('### IN callECBws');
      Http h = new Http();
      HttpRequest req = new HttpRequest();
      req.setEndpoint(Label.LAB_SF_Currency_ECB_Endpoint);
      req.setMethod('GET');
      HttpResponse res = h.send(req);
      System.debug('### ECB HttpResponse : ' + res);
      if (res.getStatusCode() != null && String.valueOf(res.getStatusCode()).startsWith('2')) {
        Dom.Document doc = res.getBodyDocument();
        return doc;
        //Retrieve the root element for this document.
        //Dom.XMLNode root = doc.getRootElement();
        //parseXML(root);
      } else {
        throw new CalloutException(res.getStatus());
      }
    } catch (Exception e) {
      System.debug('### APER09_DatedConversionRate_Management callECBws Exception : ' + e);
      throw new DatedConversionRateException(e);
    }
  }
  public static void parseXML(DOM.XMLNode node, List<String> CurrencyTypeList) {
    try {
      System.debug('### IN parseXML');

      if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
        if (node.getAttribute('time', null) != null) {
          System.debug('### TIME : ' + node.getAttribute('time', null));
          startDate = node.getAttribute('time', null);
        }

        if (CurrencyTypeList.contains(node.getAttribute('currency', null)) && node.getAttribute('rate', null) != null) {
          System.debug(
            '### currency : ' +
            node.getAttribute('currency', null) +
            ' rate : ' +
            node.getAttribute('rate', null)
          );
          isoCode = node.getAttribute('currency', null);
          conversionRate = node.getAttribute('rate', null);
          updateDatedConversionRate(isoCode, conversionRate, startDate);
          return;
        }
      }
      for (Dom.XMLNode child : node.getChildElements()) {
        parseXML(child, CurrencyTypeList);
      }
    } catch (Exception e) {
      System.debug('### APER09_DatedConversionRate_Management parseXML Exception : ' + e);
      throw new DatedConversionRateException(e);
    }
  }

  class DatedConversionRateException extends Exception {
  }
}