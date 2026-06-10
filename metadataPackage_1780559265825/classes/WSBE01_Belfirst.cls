/**
 *Creator : Killian Degryse (ABSI)
 *Date : 2018/02/14
 *Class to call the webservice belfirst
 *@Construct : open the connection
 *@NEED : Close the connection at the end
 */
public with sharing class WSBE01_Belfirst {
  private String endPoint = 'https://webservices.bvdinfo.com/v1.3/belfirst/remoteaccess.asmx';
  private String username = 'Edenred-WS';
  private String password = 'Belfirst-WS';

  String sessionHandle = null;

  String token;
  String selectionCount;

  public class Belfirst {
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
    @AuraEnabled
    public String Phone { get; set; }
    @AuraEnabled
    public String Email { get; set; }
    @AuraEnabled
    public String Website { get; set; }
    @AuraEnabled
    public String SubjectToVAT { get; set; }
    @AuraEnabled
    public String NumberOfEmployees { get; set; }
    @AuraEnabled
    public String VatNumber { get; set; }

    public Belfirst() {
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
      Phone = '';
      Email = '';
      Website = '';
      SubjectToVAT = '';
      NumberOfEmployees = '';
    }
  }

  public WSBE01_Belfirst() {
    String body =
      '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://bvdep.com/webservices/">' +
      '<soapenv:Header/>' +
      '<soapenv:Body>' +
      '<web:Open>' +
      '<web:username>' +
      username +
      '</web:username>' +
      '<web:password>' +
      password +
      '</web:password>' +
      '</web:Open>' +
      '</soapenv:Body>' +
      '</soapenv:Envelope>';
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse res;

    req.setEndpoint(endPoint);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'text/xml; charset=utf-8');
    req.setBody(body);

    res = http.send(req);
    System.debug('#### WSBE01_Belfirst res : ' + res);
    System.debug('#### WSBE01_Belfirst res.string : ' + res.toString());
    System.debug('#### WSBE01_Belfirst res.body : ' + res.getBody());

    XmlStreamReader reader = new XmlStreamReader(res.getBody());
    System.debug('#### WSBE01_Belfirst reader : ' + reader);
    while (reader.hasNext()) {
      if (reader.getEventType().equals(XmlTag.START_ELEMENT)) {
        if ('OpenResult'.equals(reader.getLocalName())) {
          reader.next();
          sessionHandle = reader.getText();
        }
      }
      reader.next();
    }
  }

public Map<String, String> getInfos(String idValue, String idType, String language) {
    setLanguage(language);
    if (idType == 'BVDID') {
        findByBVDId(idValue);
    } else if (idType == 'RCSID') {
        findByRCSId('L'+ idValue);
    } else {
        throw new WSBE01_BelfirstException('Invalid ID Type provided. Must be BVDID or RCSID.');
    }
    return getListData();
  }

  public void setLanguage(String language) {
    language = language.equals('fr_BE') ? 'FR' : 'NL';
    String body =
      '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://bvdep.com/webservices/">' +
      '<soapenv:Header/>' +
      '<soapenv:Body>' +
      '<web:SetLanguage>' +
      '<web:sessionHandle>' +
      sessionHandle +
      '</web:sessionHandle>' +
      '<web:languageIsoAbbreviation>' +
      language +
      '</web:languageIsoAbbreviation>' +
      '</web:SetLanguage>' +
      '</soapenv:Body>' +
      '</soapenv:Envelope>';
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse res;

    req.setEndpoint(endPoint);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'text/xml; charset=utf-8');
    req.setBody(body);
    if(sessionHandle != null){
      
      res = http.send(req);
      System.debug('#### setLanguage res : ' + res);
      System.debug('#### setLanguage res.string : ' + res.toString());
      System.debug('#### setLanguage res.body : ' + res.getBody());
    }else{
      throw new WSBE01_BelfirstException('Unexpected Error in Belfirst, try again later.');
    }
    
  }

  public void findByBVDId(String bvdId) {
    String body =
      '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://bvdep.com/webservices/">' +
      '<soapenv:Header/>' +
      '<soapenv:Body>' +
      '<web:FindByBVDId>' +
      '<web:sessionHandle>' +
      sessionHandle +
      '</web:sessionHandle>' +
      '<web:id>' +
      bvdId +
      '</web:id>' +
      '</web:FindByBVDId>' +
      '</soapenv:Body>' +
      '</soapenv:Envelope>';
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse res;

    req.setEndpoint(endPoint);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'text/xml; charset=utf-8');
    req.setBody(body);

    if(sessionHandle != null){    
      res = http.send(req);
      System.debug('body=' + res.getBody());
    }else{
      throw new WSBE01_BelfirstException('Unexpected Error in Belfirst, try again later.');
    }
    
    XmlStreamReader reader = new XmlStreamReader(res.getBody());
    while (reader.hasNext()) {
      if (reader.getEventType().equals(XmlTag.START_ELEMENT)) {
        if ('Token'.equals(reader.getLocalName())) {
          reader.next();
          token = reader.getText();
        }
        if ('SelectionCount'.equals(reader.getLocalName())) {
          reader.next();
          selectionCount = reader.getText();
        }
      }
      reader.next();
    }
  }

  public Map<String, String> getListData() {
    String itemXml;
    List<String> itemXmlList;
    if (selectionCount == '0') {
        //            throw new Exception(Label.Error_Message_Missing_Info_Belfirst);
        throw new WSBE01_BelfirstException('error test');
    }
    Map<String, String> result = new Map<String, String>();
    System.debug('token : ' + token);
    String body =
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://bvdep.com/webservices/">' +
        '<soapenv:Header/>' +
        '<soapenv:Body>' +
        '<web:GetListData>' +
        '<web:sessionHandle>' +
        sessionHandle +
        '</web:sessionHandle>' +
        '<web:selection>' +
        '<web:Token>' +
        token +
        '</web:Token>' +
        '<web:SelectionCount>' +
        selectionCount +
        '</web:SelectionCount>' +
        '</web:selection>' +
        '<web:fromRecord>0</web:fromRecord>' +
        '<web:nrRecords>1</web:nrRecords>' +
        '<web:listFormatName>Webservice-Salesforce</web:listFormatName>' +
        '<web:resultformat>XML</web:resultformat>' +
        '</web:GetListData>' +
        '</soapenv:Body>' +
        '</soapenv:Envelope>';
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse res;
    
    req.setEndpoint(endPoint);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'text/xml; charset=utf-8');
    req.setBody(body);
    
    if(sessionHandle != null){  
      res = http.send(req);
    }else{
      throw new WSBE01_BelfirstException('Unexpected Error in Belfirst, try again later.');
    }
    
    if(res.getStatusCode() == 200){
        System.debug('#ABSI body : ' + res.getBody());
        itemXml = res.getBody().replaceAll('&lt;', '<');
        
        itemXml = itemXml.replaceAll('&gt;', '>');
        itemXmlList = itemXml.split('<GetListDataResult>');
        itemXml = itemXmlList[1].split('</GetListDataResult>')[0];
        System.debug('itemXml=' + itemXml);
        XmlStreamReader reader = new XmlStreamReader(itemXml);
        String attribute;
        while (reader.hasNext()) {
            if (reader.getEventType().equals(XmlTag.START_ELEMENT)) {
                if ('item'.equals(reader.getLocalName())) {
                    attribute = reader.getAttributeValueAt(0);
                    reader.next();
                    if (reader.hasText())
                        result.put(attribute, reader.getText());
                }
            }
            reader.next();
        }
    }else{
        throw new WSBE01_BelfirstException('Unexpected Error in Belfirst : ' + res.getStatus());
    }
    System.debug('#ABSI result : ' + result);
    return result;
}

  public void closeConnection() {
    String body =
      '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://bvdep.com/webservices/">' +
      '<soapenv:Header/>' +
      '<soapenv:Body>' +
      '<web:Close>' +
      '<web:sessionHandle>' +
      sessionHandle +
      '</web:sessionHandle>' +
      '</web:Close>' +
      '</soapenv:Body>' +
      '</soapenv:Envelope>';
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse res;

    req.setEndpoint(endPoint);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'text/xml; charset=utf-8');
    req.setBody(body);

    if(sessionHandle != null){  
      res = http.send(req);
    }else{
      throw new WSBE01_BelfirstException('Unexpected Error in Belfirst, try again later.');
    }
  }

  public void findByRCSId(String rcsId) {
    if (String.isBlank(sessionHandle)) {
        throw new WSBE01_BelfirstException('Unexpected Error in Belfirst, try again later.');
    }

    String body =
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://bvdep.com/webservices/">' +
        '<soapenv:Header/>' +
        '<soapenv:Body>' +
        '<web:Find>' +
        '<web:sessionHandle>' + sessionHandle + '</web:sessionHandle>' +
        '<web:selectionId>DNBelfirstNeo:bvd.BelfirstNeo.Search.Companies.SearchStepDictionary+RCNumber</web:selectionId>' +
        '<web:parameters>' +
        '<web:SelectionParameter>' +
        '<web:ParameterId>Id</web:ParameterId>' +
        '<web:ParameterValue>' + rcsId + '</web:ParameterValue>' +
        '</web:SelectionParameter>' +
        '</web:parameters>' +
        '</web:Find>' +
        '</soapenv:Body>' +
        '</soapenv:Envelope>';

    HttpRequest req = new HttpRequest();
    req.setEndpoint(endPoint);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'text/xml; charset=utf-8');
    req.setBody(body);

    Http http = new Http();
    HttpResponse res = http.send(req);

    System.debug('### findByRCSId response: ' + res.getBody());

    if (res.getStatusCode() != 200) {
        throw new WSBE01_BelfirstException('Unexpected Error in Belfirst : ' + res.getStatus());
    }

    XmlStreamReader reader = new XmlStreamReader(res.getBody());
    while (reader.hasNext()) {
        if (reader.getEventType() == XmlTag.START_ELEMENT) {
            if ('Token'.equalsIgnoreCase(reader.getLocalName())) {
                reader.next();
                token = reader.getText();
            }
            if ('SelectionCount'.equalsIgnoreCase(reader.getLocalName())) {
                reader.next();
                selectionCount = reader.getText();
            }
        }
        reader.next();
    }

    System.debug('### findByRCSId token=' + token + ' | selectionCount=' + selectionCount);
  }

}