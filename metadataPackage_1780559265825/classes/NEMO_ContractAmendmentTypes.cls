global without sharing class NEMO_ContractAmendmentTypes {

    global class ChangeDTO {
        public String action; // "UPDATE" (default) or "ADD"
        public MatchDTO match;
        public UpdatesDTO updates;
    }

    global class MatchDTO {
        public String cliId;      // ER_ContractLineItem__c Id (optional)
        public String product2Id; // Product2 Id (optional)
        public String productCode; // optional (if you implement)
    }

    global class UpdatesDTO {
        public Decimal quantity;
        public Decimal unitPrice;
        public Decimal discount;

        public Decimal percentage;
        public Decimal min;
        public Decimal max;
        public String lineType;
        public Date offerValidityEndDate;

        public Boolean mpv;
        public Decimal edenredMarginTur;

        public Boolean freeToSetMargin;
        public Boolean cumulativeWithPromotions;
    }

    global class ApplyResult {
        public List<String> updatedLineItemIds = new List<String>();
        public List<String> createdLineItemIds = new List<String>();
    }
}