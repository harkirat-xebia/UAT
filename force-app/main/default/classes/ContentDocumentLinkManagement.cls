/**
 * @author : Snehil
 * @date : 29/11/2024
 * @desc : ContentDocumentLinkManagement
 * @see ContentDocumentLinkManagement
 */
public class ContentDocumentLinkManagement {
    public static void attachDocumentFromQuoteToOpportunity(List<ContentDocumentLink> contentDocLinkList){
        
        Set<Id> quoteIdSet = new Set<Id>();
        List<ContentDocumentLink> cdInsertList = new List<ContentDocumentLink>();
        List<ContentDocumentLink> filteredcdList = new List<ContentDocumentLink>();
        
        for(ContentDocumentLink contentDocLinkObj : contentDocLinkList){
            if(String.valueOf(contentDocLinkObj.LinkedEntityId).startsWith('0Q0')){
                quoteIdSet.add(contentDocLinkObj.LinkedEntityId);
                filteredcdList.add(contentDocLinkObj);
            } 
        }
        
        Map<Id,Quote> quoteMap = new Map<Id,Quote>([SELECT Id, OpportunityId FROM Quote where Id IN: quoteIdSet]);
        
        for(ContentDocumentLink contentDocLinkObj : filteredcdList){
            ContentDocumentLink contDocLinkObj = new ContentDocumentLink();
            contDocLinkObj.LinkedEntityId = quoteMap.get(contentDocLinkObj.LinkedEntityId).OpportunityId;
            contDocLinkObj.ContentDocumentId = contentDocLinkObj.ContentDocumentId;
            contDocLinkObj.ShareType = contentDocLinkObj.ShareType;  
            contDocLinkObj.Visibility = contentDocLinkObj.Visibility; 
            cdInsertList.add(contDocLinkObj);
        }
        
        if(!cdInsertList.isEmpty()){
            insert cdInsertList;
        }
        
    }
    
}