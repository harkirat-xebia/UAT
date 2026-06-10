public class APCZ03_AresCallout_ById {
  public HttpResponse getDarvBas(String sId) {
    Http h = new Http();
    HttpRequest req = new HttpRequest();

    //24745391 Edenred
    req.setEndpoint('http://wwwinfo.mfcr.cz/cgi-bin/ares/darv_bas.cgi?ico=' + sId);
    req.setTimeout(60000);
    req.setMethod('GET');
    HttpResponse res = h.send(req);

    return res;
  } //darv_bas

  public HttpResponse getDarvRes(String sId) {
    Http h = new Http();
    HttpRequest req = new HttpRequest();

    //24745391 Edenred
    req.setEndpoint('http://wwwinfo.mfcr.cz/cgi-bin/ares/darv_res.cgi?ico=' + sId);
    req.setTimeout(60000);
    req.setMethod('GET');
    HttpResponse res = h.send(req);

    return res;
  } //darv_res

  public HttpResponse getCreditScoringInfo(String crnValue) {
    Http h = new Http();
    HttpRequest req = new HttpRequest();

    //24745391 Edenred
    req.setEndpoint(
      'https://services.informa.es/api/get-product?username=' +
      '631245' +
      '&password=' +
      '5EDENRED' +
      '&product=INFORME_COMERCIAL&cif=' +
      crnValue
    );
    req.setTimeout(60000);
    req.setMethod('GET');
    HttpResponse res = h.send(req);

    return res;
  }

  public HttpResponse getTableInfo() {
    Http h = new Http();
    HttpRequest req = new HttpRequest();

    //24745391 Edenred
    req.setEndpoint('https://services.informa.es/api/get-tables?idioma=es&username=631245&password=5EDENRED');
    req.setTimeout(60000);
    req.setMethod('GET');
    HttpResponse res = h.send(req);

    return res;
  }
}