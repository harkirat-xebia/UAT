public class ApprovalLinkController {
    public Id recordId { get; set; }
    
    public ApprovalLinkController() {}
    
    public String urlStr{
        get{
            return generateApprovalURL(recordId);
        }
    }
    
    public static String generateApprovalURL(String recordID){
        if (recordId == null) return '';
        String url = '';
        List<ProcessInstanceWorkitem> workItemLst = [
            SELECT Id, ProcessInstance.Status, ProcessInstance.TargetObjectId
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :recordId
            LIMIT 1
        ];
        
        if (!workItemLst.isEmpty()) {
            String host = System.URL.getOrgDomainUrl().getHost();
            if (host != null) {
                String workItemId = workItemLst[0].Id;
                url = 'https://' + host + '/lightning/r/ProcessInstanceWorkitem/' + workItemId + '/view';
            }
        }
        return url;
    }
}