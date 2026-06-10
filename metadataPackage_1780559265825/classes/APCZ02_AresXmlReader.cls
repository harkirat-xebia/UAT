public class APCZ02_AresXmlReader {
  //Basic  address
  public String ReadDarvBasXml(HttpResponse res) {
    APCZ01_AresEntity.AresDarvBas ent = new APCZ01_AresEntity.AresDarvBas();
    APCZ01_AresEntity ent2 = new APCZ01_AresEntity();
    Dom.Document doc = res.getBodyDocument();

    for (Dom.XmlNode node01 : doc.getRootElement().getChildElements()) {
      for (Dom.XmlNode node02 : node01.getChildElements()) {
        for (Dom.XmlNode node03 : node02.getChildElements()) {
          String node03_name = node03.getName();
          String node03_text = node03.getText();

          //n03_ICO_CRN
          //n03_DIC_VatNumber
          //n03_OF_Name

          switch on node03_name {
            when 'ICO' {
              ent.n03_ICO_CRN = node03_text;
            }
            when 'DIC' {
              ent.n03_DIC_VatNumber = node03_text;
            }
            when 'OF' {
              ent.n03_OF_Name = node03_text;
            }
          } //End switch 03

          //system.debug('03 = '+ node03_name + ' -- ' + node03_text);

          for (Dom.XmlNode node04 : node03.getChildElements()) {
            String node04_name = node04.getName();
            String node04_text = node04.getText();

            switch on node04_name {
              when 'NPF' {
                ent.n04_NPF_LegalForm = node04_text;
              }
              when 'NS' {
                ent.n04_NS_Country = node04_text;
              }
              when 'N' {
                ent.n04_N_City = node04_text;
              }
              when 'NCO' {
                ent.n04_NCO_District = node04_text;
              }
              when 'NU' {
                ent.n04_NU_Street = node04_text;
              }
              when 'CD' {
                ent.n04_CD_LandRegNumber = node04_text;
              }
              when 'CO' {
                ent.n04_CO_HouseNumber = node04_text;
              }
              when 'PSC' {
                ent.n04_PSC_ZipCode = node04_text;
              }
            } //End switch 03
          } //Node 4
        } //Node 3
      } //Node 2
    } //Node 1

    String Nu_Street = (String.isNotBlank(ent.n04_NU_Street)) ? ent.n04_NU_Street + ' ' : '';
    String LandRegnum = (String.isNotBlank(ent.n04_CD_LandRegNumber)) ? ent.n04_CD_LandRegNumber : '';
    String HouseNum = (String.isNotBlank(ent.n04_CO_HouseNumber)) ? '/' + ent.n04_CO_HouseNumber : '';

    ent.n04_StreetFull = Nu_Street + LandRegnum + HouseNum;

    if (string.isBlank(Nu_Street) && string.isBlank(HouseNum)) {
      ent.n04_StreetFull = ent.n04_N_City + ' ' + LandRegnum;
    }
    /*
        if(String.isNotBlank(ent.n04_CO_HouseNumber))
        {
            ent.n04_StreetFull = ent.n04_NU_Street + ' ' + ent.n04_CD_LandRegNumber + '/' + ent.n04_CO_HouseNumber;
        }
        else 
        {
           ent.n04_StreetFull = ent.n04_NU_Street + ' ' + ent.n04_CD_LandRegNumber; 
        }*/

    return JSON.serialize(ent);
  }

  public String ReadDarvResXml(HttpResponse res, String sExistingNace) {
    System.debug('sExistingNace=' + sExistingNace);

    List<String> lstExistingNace;

    if (sExistingNace != null) {
      lstExistingNace = sExistingNace.split(',');
    }

    List<String> naceList = new List<String>();
    List<String> naceNazevList = new List<String>();

    Dom.Document doc = res.getBodyDocument();

    for (Dom.XmlNode node01 : doc.getRootElement().getChildElements()) {
      for (Dom.XmlNode node02 : node01.getChildElements()) {
        for (Dom.XmlNode node03 : node02.getChildElements()) {
          for (Dom.XmlNode node04 : node03.getChildElements()) {
            String node04_name = node04.getName();
            String node04_text = node04.getText();

            //String sNace = null;
            if (node04_name == 'NACE' && node04_text != null) {
              naceList.Add(node04_text);
            }

            //String sNazevNace = null;
            if (node04_name == 'Nazev_NACE' && node04_text != null) {
              /*system.debug('02nace = '+ node04_name + ' -- ' + node04_text);
               sNazevNace = node04_text;*/
              //entList.Add(ent);
              naceNazevList.Add(node04_text);
            }
          } //Node 4
        } //Node 3
      } //Node 2
    } //Node 1

    List<APCZ01_AresEntity.AresNace> entList = new List<APCZ01_AresEntity.AresNace>();

    if (naceList.Size() == naceNazevList.Size()) {
      for (Integer i = 0; i < naceList.Size(); i++) {
        APCZ01_AresEntity.AresNace ent = new APCZ01_AresEntity.AresNace();
        ent.n04_NACE = naceList[i];
        ent.n04_Nazev = naceNazevList[i];

        Boolean bIsSelected = false; //Init as not seleced

        if (lstExistingNace != null) {
          for (String rowNace : lstExistingNace) {
            if (rowNace == naceList[i]) {
              bIsSelected = true;
            }
          }
        } //not null list

        ent.isSelected = bIsSelected;
        entList.Add(ent);
      }
    }

    //system.debug(JSON.serialize(entList));
    return JSON.serialize(entList);
  }
}