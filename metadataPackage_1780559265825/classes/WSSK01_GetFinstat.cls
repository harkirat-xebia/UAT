/*
----------------------------------------------------------------------
-- - Name          : WSSK01_GetFinstat
-- - Author        : OLA
-- - Description   : get information from Finstat public register
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Sep-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/

public class WSSK01_GetFinstat {
  public static Finstat GetFinstatInfos(string ico) {
    String apiKey = Label.LAB_SF_SK_FinStat_APIKey;
    String Hash = generateHash(ico, apiKey);
    string finStatURL = 'http://www.finstat.sk/api/extended?ico=' + ico + '&apiKey=' + apiKey + '&Hash=' + Hash;
    system.debug('##### getCardBalanceURL: ' + finStatURL);

    try {
      //declare the http request to perform the REST call
      Http h = new Http();
      HttpRequest req = new HttpRequest();
      req.setEndpoint(finStatURL);
      req.setMethod('GET');
      req.setTimeout(60000);
      HttpResponse res = h.send(req);
      String responseBody = res.getbody();

      if (String.valueOf(res.getStatusCode()).startsWith('2')) {
        System.debug('#### GetFinstatInfos responseBody ' + responseBody);
        DOM.Document responseBodyDocument = res.getBodyDocument();
        return parseFinStatBody(responseBodyDocument);
      } else if (String.valueOf(res.getStatusCode()).equals('404')) {
        throw new CustomException(Label.LAB_SF_PublicRegister_NoData.replace('{0}', ico));
      } else if (String.valueOf(res.getStatusCode()).equals('500')) {
        throw new CustomException(Label.LABS_SF_WS_Unavailable);
      } else {
        throw new CustomException(Label.LABS_SF_WS_GenericError1);
      }
    } catch (CustomException e) {
      system.debug('##### GetFinstatInfos CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### GetFinstatInfos Exception : ' + e);
      throw new CustomException(Label.LABS_SF_WS_GenericError1);
    }
  }

  public static Finstat parseFinStatBody(DOM.Document body) {
    Dom.XmlNode root = body.getRootElement();
    Finstat finstatInst = new Finstat();

    for (Dom.XmlNode element : root.getChildElements()) {
      switch on element.getName() {
        when 'Name' {
          finstatInst.Name = String.isNotBlank(element.getText()) ? element.getText() : '';
        }
        when 'Dic' {
          finstatInst.Dic = String.isNotBlank(element.getText()) ? element.getText() : '';
        }
        when 'IcDPH' {
          finstatInst.IcDPH = String.isNotBlank(element.getText()) ? element.getText() : '';
        }
        when 'Ico' {
          finstatInst.Ico = String.isNotBlank(element.getText()) ? element.getText() : '';
        }
        when 'LegalFormText' {
          finstatInst.LegalFormText = String.isNotBlank(element.getText()) ? element.getText() : '';
        }
        when 'StreetNumber' {
          finstatInst.StreetNumber = String.isNotBlank(element.getText()) ? element.getText() : '';
        }
        when 'Street' {
          finstatInst.Street = String.isNotBlank(element.getText()) ? element.getText() : '';
        }
        when 'ZipCode' {
          finstatInst.ZipCode = String.isNotBlank(element.getText()) ? element.getText() : '';
        }
        when 'City' {
          finstatInst.City = String.isNotBlank(element.getText()) ? element.getText() : '';
        }
        when 'Country' {
          finstatInst.Country = String.isNotBlank(element.getText()) ? element.getText() : '';
        }
        when 'SkNaceCode' {
          finstatInst.NaceCode = String.isNotBlank(element.getText()) ? element.getText() : '';
        }
        when 'SkNaceText' {
          finstatInst.NaceText = String.isNotBlank(element.getText()) ? element.getText() : '';
        }
      }
    }

    System.debug('finstatInst : ' + finstatInst);
    return finstatInst;
  }
  public static String generateHash(String ico, String apiKey) {
    String privateKey = Label.LAB_SF_SK_FinStat_PrivateKey;
    String hashParam = ico;
    String text = 'SomeSalt+' + apiKey + '+' + privateKey + '++' + hashParam + '+ended';
    blob digest = crypto.generateDigest('SHA-256', blob.valueOf(text));
    System.debug('### generateDigest : ' + EncodingUtil.convertToHex(digest));
    return EncodingUtil.convertToHex(digest);
  }

  public class Finstat {
    @AuraEnabled
    public String Name { get; set; }
    @AuraEnabled
    public String Dic { get; set; }
    @AuraEnabled
    public String IcDPH { get; set; }
    @AuraEnabled
    public String Ico { get; set; }
    @AuraEnabled
    public String LegalFormText { get; set; }
    @AuraEnabled
    public String Street { get; set; }
    @AuraEnabled
    public String StreetNumber { get; set; }
    @AuraEnabled
    public String ZipCode { get; set; }
    @AuraEnabled
    public String City { get; set; }
    @AuraEnabled
    public String Country { get; set; }
    @AuraEnabled
    public String NaceCode { get; set; }
    @AuraEnabled
    public String NaceText { get; set; }

    public Finstat() {
      Name = '';
      Dic = '';
      IcDPH = '';
      Ico = '';
      LegalFormText = '';
      Street = '';
      StreetNumber = '';
      ZipCode = '';
      City = '';
      Country = '';
      NaceCode = '';
      NaceText = '';
    }
  }
  //description Custom error handling class
  public class CustomException extends Exception {
  }
}