/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : InvalidContractWrapper
 * Author          : Harkirat Singh
 * Created Date    : Apr 6, 2026
 * Last Modified By: Harkirat Singh
 * Last Modified On: Apr 6, 2026
 * Description     : This class implements for Bulk Contract Activation
 *  
 * Change History  :
 *  Date 7/4/26         │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 6, 2026  │ Harkirat Singh   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class InvalidContractWrapper {
    @AuraEnabled public String contractId;
    @AuraEnabled public String contractNumber;
    @AuraEnabled public String status;
    @AuraEnabled public String recordUrl;
    @AuraEnabled public String errorDetails;
    @AuraEnabled public String contractCategory;
    @AuraEnabled public String syncStatusCode;
}