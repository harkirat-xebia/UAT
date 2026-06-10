public class APER05_DoNotRunTrigger {
  /*
----------------------------------------------------------------------
-- - Name          : APER05_DoNotRunTrigger
-- - Author        : AAB
-- - Description   : Is used to desable trigger process        
-- Maintenance History:
--
-- Date         Name  				Version  	Remarks 
-- -----------  ----------- 		--------  	---------------------------------------
-- 27-SEPT-2018  AAB    				1.0      	Initial version
---------------------------------------------------------------------------------------
*/
  public static Boolean doNotRunTrigger = false;

  public void setDoNotRunTrigger() {
    doNotRunTrigger = true;
  }

  /*public static Boolean shouldRunTrigger() {
        return !doNotRunTrigger;
    }*/
}