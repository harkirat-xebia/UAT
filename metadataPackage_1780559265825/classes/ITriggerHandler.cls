/**
 * @author : ALK
 * @date : 01/03/2021
 * @desc : ITriggerHandler
 * @see ITriggerHandler
 */

public interface ITriggerHandler {
  void beforeInsert(List<SObject> newItems);

  void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);

  void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);

  void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);

  void beforeDelete(Map<Id, SObject> oldItems);

  void afterDelete(Map<Id, SObject> oldItems);

  void afterUndelete(Map<Id, SObject> oldItems);

  Boolean isDisabled();
}