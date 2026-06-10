/**
*Creator : Snehil Verma
*Date : 2024/11/09
*Class for all "util" methods
*/
public class BE_Util {
    /**
     *@Parameter Integer => VAT without BE0 (or BE1) 
     *@Return if the enterprise number is valid, return true
     */ 
    public static Boolean checkEnterpriseNumber(Integer enterpriseNumber){
        Integer lastNumbers = math.mod(enterpriseNumber, 100);
        enterpriseNumber = (enterpriseNumber-lastNumbers)/100;
        Integer reducedEnterpriseNumber = (enterpriseNumber/97)*97;
        Integer rest = enterpriseNumber-reducedEnterpriseNumber;
        return 97-rest == lastNumbers;
    }

    public static String addValueToMultiSelect(String value,String newvalue){
        List<String> init = new List<String>();
        if (value !=null && value!=''){
            init = value.split(';');
        }
        init.add(newvalue);
        Set<String> ret = new Set<String>();
        ret.addAll(init);
        return String.join(new List<String>(ret), ';');
    }

    public static String getWebserviceSetting(String setting){
        if(isCurrentUserOrgProduction())
            return getSetting(setting);
        else
            return getSetting(setting+' UAT');
    }

    private static String getSetting(String setting){
        String result;

        /*try{
            result = [SELECT BE_Value__c FROM BE_Webservice_Setting__mdt
                      WHERE Label = :setting].BE_Value__c;
        }
        catch(Exception e){
            result = null;
        }*/
        return result;
    }

    public static Boolean isCurrentUserOrgProduction(){
        Id productionId;
        try{
            productionId = [SELECT BE_Value__c FROM BE_Organization_ID__mdt
                            WHERE Label = 'Production Organization ID'].BE_Value__c;
        }
        catch(Exception e){
            return false;
        }
        return productionId == UserInfo.getOrganizationId();
    }
    
    //Added for PBI-578 by Killian Degryse
    public static void addAttachmentOnSObject(Blob b, Id sObjectId, String name){
        Attachment attachment = new Attachment();
        attachment.Body = b;
        attachment.Name = name;
        attachment.ParentId = sObjectId;
        insert attachment;
    }
    
    //PBI-667 : Maintenance page
    public static Boolean isOnMaintenance(String stakeholderType){
        List<BE_Activate_Maintenance_Page__mdt> lstActMaintPage = [SELECT BE_Type__c,BE_Activate_Maintenance_Page__c
        FROM BE_Activate_Maintenance_Page__mdt
        WHERE BE_Type__c=:stakeholderType];
        return (lstActMaintPage.size() > 0 && lstActMaintPage.get(0).BE_Activate_Maintenance_Page__c);

    }
}