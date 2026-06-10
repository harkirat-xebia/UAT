/**
 * @author : ALK
 * @date : 30/06/2021
 * @desc : ApplicationExceptionTest
 */

@IsTest
private class ApplicationExceptionTest {
  @IsTest
  static void testBehavior() {
    Test.startTest();
    ApplicationException ae = new ApplicationException('Exception message');
    ae.message = 'Exception message';
    String message = ae.message;
    System.assert(String.isNotBlank(message), 'No exception message');
    Test.stopTest();
  }
}