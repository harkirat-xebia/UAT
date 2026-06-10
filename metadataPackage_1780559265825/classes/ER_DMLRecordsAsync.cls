/**
 * @author: ALK
 * @date: 23/12/2021
 * @desc: ER_DMLRecordsAsync
 * @see: ER_DMLRecordsAsync
 */

public with sharing class ER_DMLRecordsAsync implements Queueable {
  public String dmlType;
  public List<SObject> objects = new List<SObject>();
  List<ER_Solution_Line_Item__c> solutionsItemsAsync = new List<ER_Solution_Line_Item__c>();
  List<ER_Store__c> storesAsync = new List<ER_Store__c>();
  List<ER_StoreCategory__c> storeCategoriesAsync = new List<ER_StoreCategory__c>();
  List<ER_Acceptor__c> acceptorsAsync = new List<ER_Acceptor__c>();
  List<ER_Contact_Role__c> contactRolesAsync = new List<ER_Contact_Role__c>();

  public ER_DMLRecordsAsync(List<SObject> obj, String dmlType) {
    this.objects = obj;
    this.dmlType = dmlType;
  }

  public ER_DMLRecordsAsync(
    List<ER_Solution_Line_Item__c> solutionsItemsAsync,
    List<ER_Store__c> storesAsync,
    List<ER_StoreCategory__c> storeCategoriesAsync,
    List<ER_Acceptor__c> acceptorsAsync,
    List<ER_Contact_Role__c> contactRolesAsync,
    String dmlType
  ) {
    this.solutionsItemsAsync = solutionsItemsAsync;
    this.storesAsync = storesAsync;
    this.storeCategoriesAsync = storeCategoriesAsync;
    this.acceptorsAsync = acceptorsAsync;
    this.contactRolesAsync = contactRolesAsync;
    this.dmlType = dmlType;
  }

  public void execute(QueueableContext context) {
    switch on dmlType {
      when 'INSERT' {
        if (this.objects != null && !this.objects.isEmpty())
          insert objects;
      }
      when 'UPDATE' {
        if (this.objects != null && !this.objects.isEmpty())
          update objects;
        if (this.solutionsItemsAsync != null && !this.solutionsItemsAsync.isEmpty())
          update solutionsItemsAsync;
        if (this.storesAsync != null && !this.storesAsync.isEmpty())
          update storesAsync;
        if (this.storeCategoriesAsync != null && !this.storeCategoriesAsync.isEmpty())
          update storeCategoriesAsync;
        if (this.acceptorsAsync != null && !this.acceptorsAsync.isEmpty())
          update acceptorsAsync;
        if (this.contactRolesAsync != null && !this.contactRolesAsync.isEmpty())
          update contactRolesAsync;
      }
    }
  }
}