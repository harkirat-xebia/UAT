/**
 * @author AAZ
 * @date 28/04/2021
 * @description
 */
global class ER_ZuoraQuoteDefaultValues extends zqu.CreateQuoteController.PopulateDefaultFieldValuePlugin {
  public static final Integer MAX_LENGTH = 80;

  global override void populateDefaultFieldValue(SObject record, zqu.PropertyComponentController.ParentController pcc) {
    if (!Test.isRunningTest())
      super.populateDefaultFieldValue(record, pcc);

    //Retrieve the account ID from the quote
    Id accountId = (Id) record.get('zqu__Account__c');
    //Retrieve the opportunity ID from the quote
    Id opportunityId = (Id) record.get('zqu__Opportunity__c');
    //Retrieve the zuora account number
    String bAccountNumber = (String) record.get('zqu__Zuora_Account_Number__c');
    //startDate
    Date startDate = null;
    String quoteDefaultName;

    if (String.isNotBlank(opportunityId)) {
      List<Opportunity> opps = [
        SELECT
          Id,
          Name,
          Account.ER_Registration_Number__c,
          Account.Name,
          ER_BUPicklist__c,
          ER_Contract_Expected_Start_Date__c,
          ER_Reason__c,
          Account.ER_BUPicklist__c,
          ER_PaymentTerms__c,
          (SELECT Id, zqu__Number__c, Name FROM zqu__Quotes__r ORDER BY zqu__Number__c DESC)
        FROM Opportunity
        WHERE Id = :opportunityId
        LIMIT 1
      ];

      if (!opps.isEmpty()) {
        record.put('zqu__Amendment_Name__c', ('AM-' + opps[0].Name).left(MAX_LENGTH));

        if (String.isNotBlank(opps[0].ER_Reason__c))
          record.put('zqu__QuoteBusinessType__c', opps[0].ER_Reason__c);

        if (opps[0].ER_Contract_Expected_Start_Date__c != null) {
          record.put('zqu__StartDate__c', opps[0].ER_Contract_Expected_Start_Date__c);
          //record.put('zqu__TermStartDate__c', opp.ER_Contract_Expected_Start_Date__c);
          startDate = opps[0].ER_Contract_Expected_Start_Date__c;
        } else {
          record.put('zqu__StartDate__c', Date.today());
          //record.put('zqu__TermStartDate__c', Date.today());
          startDate = Date.today();
        }

        if (String.isNotBlank(opps[0].ER_BUPicklist__c))
          record.put('ER_Business_Unit__c', opps[0].ER_BUPicklist__c);

        //if(String.isNotBlank(opp.ER_PaymentTerms__c)) record.put('zqu__PaymentTerm__c', opp.ER_PaymentTerms__c);

        if (!opps[0].zqu__Quotes__r.isEmpty()) {
          zqu__Quote__c q = opps[0].zqu__Quotes__r[0];
          Integer lastSequenceNumber = (String.isNotBlank(q.Name) &&
            String.valueOf(q.Name.substringAfterLast('-')).isNumeric()
            ? Integer.valueOf(q.Name.substringAfterLast('-'))
            : 0);
          quoteDefaultName =
            opps[0].ER_BUPicklist__c +
            '-' +
            (String.isNotBlank(opps[0].Account.ER_Registration_Number__c)
              ? opps[0].Account.ER_Registration_Number__c
              : opps[0].Account.Name) +
            '-' +
            Datetime.now().format('yyyy-MM-dd') +
            '-' +
            (lastSequenceNumber + 1);
        } else {
          quoteDefaultName =
            opps[0].ER_BUPicklist__c +
            '-' +
            (String.isNotBlank(opps[0].Account.ER_Registration_Number__c)
              ? opps[0].Account.ER_Registration_Number__c
              : opps[0].Account.Name) +
            '-' +
            Datetime.now().format('yyyy-MM-dd') +
            '-' +
            1;
        }

        record.put('Name', quoteDefaultName.left(MAX_LENGTH));

        //Subscription dates calculation
        Integer startDateYear = startDate.year();
        Date firstDayOfYear = Date.newInstance(startDateYear, 1, 1);
        record.put('zqu__TermStartDate__c', firstDayOfYear);

        if (startDate.day() == 1) {
          record.put('zqu__Service_Activation_Date__c', startDate);
          record.put('zqu__Customer_Acceptance_Date__c', startDate);
        } else {
          if (startDate.month() == 12)
            startDateYear = startDateYear + 1;
          record.put(
            'zqu__Service_Activation_Date__c',
            Date.newInstance(startDateYear, startDate.addMonths(1).month(), 1)
          );
          record.put(
            'zqu__Customer_Acceptance_Date__c',
            Date.newInstance(startDateYear, startDate.addMonths(1).month(), 1)
          );
        }

        //Populate Payment Term
        if (String.isNotBlank(bAccountNumber)) {
          //Zuora__CustomerAccount__c ba = [SELECT Zuora__PaymentTerm__c, Zuora__DefaultPaymentMethod__c FROM Zuora__CustomerAccount__c  WHERE Zuora__AccountNumber__c = :bAccountNumber LIMIT 1];
          Zuora__CustomerAccount__c ba = ZuoraUtils.getBillingAccountByNumber(bAccountNumber, opps[0].ER_BUPicklist__c);
          if (ba != null) {
            record.put('zqu__PaymentTerm__c', ba.Zuora__PaymentTerm__c);
            
            Switch on ba.Zuora__DefaultPaymentMethod__c {
              When 'CreditCard' {
                  record.put('zqu__PaymentMethod__c', 'Credit Card');
              }
              When 'WireTransfer' {
                  record.put('zqu__PaymentMethod__c', 'Wire Transfer');
              }
              When 'BankTransfer' {
                  record.put('zqu__PaymentMethod__c', 'Bank Transfer');
              }
            }
          }
        }
      }
    }

    record.put('zqu__ValidUntil__c', Date.today().addDays(30));
    record.put('zqu__BillingMethod__c', 'Email');
    record.put('zqu__Subscription_Term_Type__c', 'Evergreen');
    //record.put('zqu__RenewalSetting__c', 'RENEW_TO_EVERGREEN');

    //Find the contacts associated with the account
    List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE Account.Id = :accountId];

    //Assuming the contacts are present, set the billTo and soldTo to the first contact
    if (!contacts.isEmpty()) {
      record.put('zqu__BillToContact__c', contacts[0].Id);
      record.put('zqu__SoldToContact__c', contacts[0].Id);

      //Before retrieving  the lookup  options, needs to populate the map first
      if (!Test.isRunningTest()) {
        super.setLookupOptions(pcc);

        //Now retrieve the lookup component options
        zqu.LookupComponentOptions billToOptions = super.getLookupOption('zqu__BillToContact__c');
        billToOptions.targetId = contacts[0].Id;
        billToOptions.targetName = contacts[0].Name;
        zqu.LookupComponentOptions soldToOptions = super.getLookupOption('zqu__SoldToContact__c');
        soldToOptions.targetId = contacts[0].Id;
        soldToOptions.targetName = contacts[0].Name;
      }
    }
  }
}