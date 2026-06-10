/**
 * @author : Noor
 * @date : 04/08/2021
 * @desc : APER34_Event_Management to Process Salesforce standard Event object
 * @see EventTriggerHandler
 */

public with sharing class APER34_Event_Management {
  /**
   * @author ALK
   * @date 12/02/2023
   * @description This method checks if one user is above another user in the role hierarchy
   * @param newItems
   * @param oldMap
   *
   * @return
   */
  public static void isUserAboveInRoleHierarchy(List<Event> newItems, Map<Id, Event> oldMap) {
    Set<Id> eventsOldOwnersIds = new Set<Id>();
    Map<Id, Id> mapOldOwnerUserRole = new Map<Id, Id>();
    List<Event> newEvents = new List<Event>();
    Set<String> admins = new Set<String>{ Constants.PROFILE_ER_INTEGRATION, Constants.PROFILE_SYS_ADMIN };

    for (Event e : newItems) {
      if (e.OwnerId != oldMap.get(e.Id).OwnerId) {
        newEvents.add(e);
        eventsOldOwnersIds.add(oldMap.get(e.Id).OwnerId);
      }
    }

    if (!newEvents.isEmpty()) {
      Map<Id, Profile> mapAdminProfiles = new Map<Id, Profile>([SELECT Id FROM Profile WHERE Name IN :admins]);

      for (User u : [SELECT Id, UserRoleId FROM User WHERE Id IN :eventsOldOwnersIds]) {
        if (u.UserRoleId != null)
          mapOldOwnerUserRole.put(u.Id, u.UserRoleId);
      }

      for (Event e : newEvents) {
        if (
          oldMap.get(e.Id).OwnerId != UserInfo.getUserId() &&
          !mapAdminProfiles.keySet().contains(UserInfo.getProfileId())
        ) {
          Map<Id, UserRole> mapChildRoles = Utils.getRoleSubordinates(UserInfo.getUserRoleId());
          if (
            mapChildRoles.isEmpty() ||
            (mapChildRoles != null &&
            !mapChildRoles.isEmpty() &&
            mapOldOwnerUserRole.containsKey(oldMap.get(e.Id).OwnerId) &&
            !mapChildRoles.containsKey(mapOldOwnerUserRole.get(oldMap.get(e.Id).OwnerId)))
          )
            e.addError(Label.LAB_SF_EVENT_CHANGE_OWNER_MSG);
        }
      }
    }
  }
}