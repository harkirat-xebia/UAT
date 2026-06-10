public class APCZ01_AresEntity {
  public class AresDarvBas {
    //legal node
    public String n03_ICO_CRN { get; set; }
    public String n03_DIC_VatNumber { get; set; }
    public String n03_OF_Name { get; set; }
    //adress node
    public String n04_NPF_LegalForm { get; set; }
    public String n04_NS_Country { get; set; }
    public String n04_N_City { get; set; }
    public String n04_NCO_District { get; set; }
    public String n04_NU_Street { get; set; }
    public String n04_CD_LandRegNumber { get; set; }
    public String n04_CO_HouseNumber { get; set; }
    public String n04_PSC_ZipCode { get; set; }
    public String n04_StreetFull { get; set; }
  }

  public class AresNace {
    public String n04_NACE { get; set; }
    public String n04_Nazev { get; set; }
    public Boolean isSelected { get; set; }
  }

  public class AresPopUp {
    public String oId { get; set; }
    public String sName { get; set; }
    public String sVatNumber { get; set; }
    public String sOtherFiscalId { get; set; }
    public String sStreet { get; set; }
    public String sPostalCode { get; set; }
    public String sCity { get; set; }
    public String sCountry { get; set; }
    public String sLegalForm { get; set; }
    public String sBEPhone { get; set; }
    public String sBEEmail { get; set; }
    public String sBEWebsite { get; set; }
    public String sBESubjectToVAT { get; set; }
    public String sBENumberOfEmployees { get; set; }
    public Boolean bGetName { get; set; }
    public Boolean bGetVatNumber { get; set; }
    public Boolean bGetOtherFiscalId { get; set; }
    public Boolean bGetLegalForm { get; set; }
    public Boolean bGetZipCode { get; set; }
    public Boolean bGetStreet { get; set; }
    public Boolean bGetCity { get; set; }
    public Boolean bGetCountry { get; set; }
    public Boolean bGetBEPhone { get; set; }
    public Boolean bGetBEEmail { get; set; }
    public Boolean bGetBEWebsite { get; set; }
    public Boolean bGetBESubjectToVAT { get; set; }
    public Boolean bGetBENumberOfEmployees { get; set; }
    public String sNaceList { get; set; }
  }
}