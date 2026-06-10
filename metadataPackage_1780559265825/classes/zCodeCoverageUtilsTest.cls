@isTest
public with sharing class zCodeCoverageUtilsTest {
  static testMethod void GetFinstatInfos() {
    Test.StartTest();
    Boolean result = zCodeCoverageUtils.cover();
    Test.stopTest();

    System.assert(result);
  }
}