/**
 * @author : ALK
 * @date : 01/03/2021
 * @desc : UtilsBypass
 * @see UtilsBypass
 */

public without sharing class UtilsBypass {
  private static Set<String> executeOnce = new Set<String>(); /**  Set of classes to be executed only once */
  private static Set<String> hasBeenExecuted = new Set<String>(); /** Set of classes which has been executed*/
  private static Set<String> bypassedTriggers; /** Set of classes to be bypassed*/
  private static User currentUser; /** Current User **/
  private static Datetime nowDatetime;

  public static Map<String, String> SKIP_STRIGGER_MAP = new Map<String, String>(); //triggerName -> Reason to skip
  public static Map<String, String> SKIP_METHOD_MAP = new Map<String, String>(); //MethodName -> Reason to skip

  /**
   * @author ALK
   * @date 01/03/2021
   * Static getter returning the current user.
   * Current User is queried in the Database if not loaded yet in Cache.
   *
   * @return User The context User
   */
  public static User getCurrentUser() {
    if (currentUser == null) {
      currentUser = [
        SELECT
          Id,
          ER_Bypass_Triggers__c,
          ER_BypassVR__c,
          Username,
          CurrencyIsoCode,
          ER_Business_Unit__c,
          Profile.Name,
          ER_bypassTrigger__c,
          ProfileId,
          Email,
          Name,
          Phone,
          LanguageLocaleKey,
          toLabel(LanguageLocaleKey) labelLanguage
        FROM User
        WHERE Id = :UserInfo.getUserId()
      ];
    }
    return currentUser;
  }

  /**
   * @author ALK
   * @date 01/03/2021
   * @description  Static getter returning true if the current user bypasses validation rules
   *
   * @return Boolean True if current user bypasses Validation Rules, else False
   */
  public static Boolean getBypassVR() {
    return getCurrentUser().ER_BypassVR__c;
  }

  /**
   * @author ALK
   * @date 01/03/2021
   * @description  Static method returning true when an apex class can execute, false if
   * it must be bypassed
   *
   * @param aClassName Name of the Apex Class written the same way it has been entered in the
   *                  BypassTriggers__c field of the user
   * @return Boolean true if the trigger can execute, false else
   */
  public static Boolean canTrigger(String aClassName) {
    Boolean canTrigger = true;

    if (getBypassedTriggers().contains(aClassName)) {
      canTrigger = false;
    }

    if (executeOnce.contains(aClassName)) {
      if (hasBeenExecuted.contains(aClassName)) {
        canTrigger = false;
      } else {
        hasBeenExecuted.add(aClassName);
      }
    }

    return canTrigger && !getCurrentUser().ER_bypassTrigger__c;
  }

  /**
   * @author ALK
   * @date 01/03/2021
   * @description Static method returning the set of apex classes to bypass
   *
   * @return Set<String> The set of classes to be bypassed
   */
  private static Set<String> getBypassedTriggers() {
    if (bypassedTriggers == null) {
      bypassedTriggers = new Set<String>();
      String bypassedTriggerString = getCurrentUser().ER_Bypass_Triggers__c;

      if (bypassedTriggerString != null) {
        bypassedTriggers.addAll(bypassedTriggerString.split(Constants.SEMICOLON));
      }
    }

    return bypassedTriggers;
  }

  /**
   * @author ALK
   * @date 01/03/2021
   * @description Reset all bypasses
   */
  public static void reset() {
    hasBeenExecuted.clear();
    bypassedTriggers = null;
    currentUser = null;
  }

  /**
   * @author ALK
   * @date 01/03/2021
   * @description this method allows us to bypass a trigger or method in apex code
   * Use to bypass a trigger in code
   * @param classesToBypass
   */
  public static void setBypassedTriggersByApex(Set<String> classesToBypass) {
    if (bypassedTriggers == null)
      bypassedTriggers = new Set<String>();
    if (classesToBypass != null && !classesToBypass.isEmpty())
      bypassedTriggers.addAll(classesToBypass);
  }

  public static void setExecuteOnce(String aClassName) {
    if (executeOnce == null)
      executeOnce = new Set<String>();
    executeOnce.add(aClassName);
  }

  /**
   * @author ALK
   * @date 01/03/2021
   * @description Set Current User
   * @param u
   */
  public static void setCurrentUserParameter(User u) {
    currentUser = u;
  }

  /**
   * @author ALK
   * @date 01/03/2021
   * @description enable / disable bypass VR
   * @param userId
   * @param bypass
   */
  public static void setBypassAllVR(Id userId, Boolean bypass) {
    if (String.isNotBlank(userId) && bypass != null)
      update new User(Id = userId, ER_BypassVR__c = bypass);
  }
}