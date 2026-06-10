/**
 * @author Oussama LASFAR
 * @date 26/09/2018 (dd/mm/yyyy)
 * @description This class allows users to Cases from case list view.
 *              This class assign accepted cases to the current user + change the status of the first Case to 'In progress' and open it in a new tab
 */

public class VFCER02_Case_Accept {
  public Boolean selected { get; set; }
  public String url { get; set; }
  public List<Case> selectedCases;
  public string recId { get; set; }
  private ApexPages.StandardSetController standardController;

  public VFCER02_Case_Accept(ApexPages.StandardSetController standardController) {
    this.standardController = standardController;
  }
  public void Redirect() {
    try {
      this.standardController = standardController;
      List<Case> selectedCases = (List<Case>) standardController.getSelected();
      String usrId = UserInfo.getUserId();
      Integer index;
      url = standardController.cancel().getUrl();
      if (selectedCases.size() > 0) {
        selected = true;
        index = 0;
        for (case cc : selectedCases) {
          cc.ownerId = usrId;
          if (index == 0) {
            System.debug('#### First Case Change Status: ' + cc);
            if (
              cc.RecordTypeId ==
              Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ER_User_Case_RT').getRecordTypeId()
            ) {
              cc.Status = Label.LAB_SF_Case_inProgress;
            }
          }
          index++;
        }
        update selectedCases;
        recId = selectedCases[0].Id;
      } else {
        selected = false;
      }
    } catch (Exception e) {
      System.debug(e.getmessage());
    }
  }
}