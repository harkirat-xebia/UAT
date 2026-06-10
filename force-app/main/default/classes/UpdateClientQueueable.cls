public class UpdateClientQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> accountIdList;
    private Integer currentIndex;
    
    /*public UpdateClientQueueable(List<Id> accountIdList, Integer currentIndex) {
        this.accountIdList = accountIdList;
        this.currentIndex = currentIndex;
    }*/
    
    public void execute(QueueableContext context) {
        /*Map<String, Object> responseMap;
        if (currentIndex >= accountIdList.size()) {
            return;
        }

        Id accId = accountIdList[currentIndex];
        
        try {
            SyncClientContractService service = new SyncClientContractService();
            responseMap = service.updateClientCallout(accId);
        } catch (Exception e) {
            System.debug('Callout failed: ' + e.getMessage());
        }

        System.enqueueJob(new UpdateClientQueueable(accountIdList, currentIndex + 1));*/
    }

}