/**
 * Created by noorgoolamnabee on 13/03/2023.
 */

@IsTest
private class SmarterAssetCardManagementTest {
  @TestSetup
  static void setup() {
    Asset newAsset = APER07_UtilityTestMethod.getAsset('12335333', 'Edenred_plus', 'ER_Mono-Wallet');
    newAsset.ER_Card_Operational_System_ID__c = '23232-334457-3634';
    newAsset.ER_BUPicklist__c = 'FR';
    insert newAsset;
  }

  @IsTest
  static void blockUnBlockCard_shouldReturnSuccess() {
    List<Asset> assets = [SELECT Id, ER_Card_Operational_System_ID__c, ER_BUPicklist__c, Status FROM Asset LIMIT 1];
    SmarterAssetCardManagement.Request req = new SmarterAssetCardManagement.Request();
    req.Id = assets[0].Id;
    req.ER_Card_Operational_System_ID = 'ca8dc50e-0902-4ad3-93e1-6c520a5af016';
    req.ER_BUPicklist = 'fr';
    req.Status = 'UNBLOCKED';
    List<SmarterAssetCardManagement.Request> recordIds = new List<SmarterAssetCardManagement.Request>{ req };

    // When
    Test.startTest();
    SmarterAPIMock smarterMock = new SmarterAPIMock();
    Test.setMock(HttpCalloutMock.class, smarterMock);
    List<SmarterAssetCardManagement.Response> result = SmarterAssetCardManagement.blockUnBlockCard(recordIds);
    Test.stopTest();

    // Then
    System.assertEquals(1, result.size());
    System.assertEquals('Succeeded', result[0].status);
  }
}