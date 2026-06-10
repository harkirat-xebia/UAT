/*
----------------------------------------------------------------------
-- - Name          : APER10_User_Management
-- - Author        : OLA
-- - Description   : User Management, This class is used to group all the functionnality linked to the object User(user informations/ Bypass triggers ..)
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Nov-2018       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public class APER10_User_Management {
  public static boolean canTrigger { get; private set; } // User can trigger ?
  //public static string  userRoleName {get; private set;}     // User Role Name
  public static string userProfileName { get; private set; } // User Profile Name
  //public static string  userLicenseName {get; private set;}  // User Profile Name
  public static string userBU { get; private set; } // User Profile Name

  static {
    initAPER10_User_Management();
  }

  @TestVisible
  static void initAPER10_User_Management() {
    System.debug('## >>> APER10_User_Management constructor :BEGIN <<< run by ' + UserInfo.getName());

    User user = [
      SELECT ER_bypassTrigger__c, Profile.Name, ER_Business_Unit__c
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    canTrigger = !user.ER_bypassTrigger__c;
    userProfileName = user.Profile.Name;
    userBU = user.ER_Business_Unit__c;

    if (
      UserInfo.getUserType() == Constants.AUTOMATED_PROCESS &&
      !String.isBlank(APER30_AutoEnrollment_Management.syncRecordBU)
    )
      userBU = APER30_AutoEnrollment_Management.syncRecordBU;
    System.debug('>>> userBU: ' + userBU);
    System.debug('## >>> APER10_User_Management constructor : END <<<');
  }
}