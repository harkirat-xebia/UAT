/**
 * Created by khalilhaddouch on 04/09/2023.
 */

global class BAER08_GenerateAmendedContracts implements Schedulable, Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    String query;

    global BAER08_GenerateAmendedContracts() {
        String userBu = APER10_User_Management.userBU;
        query = Label.LABS_SF_BAER08_GenerateAmendedContracts;
        query = query.replace('XXX', '\'' + userBu + '\'');
    }

    global BAER08_GenerateAmendedContracts(String query) {

        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {

        System.debug('###query : ' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<ER_Bulk_Contract_Amendment__c> scope) {

        APER41_BulkContractAmendment_Management.amendContracts(scope);
    }

    global void execute(SchedulableContext sc) {
        BAER08_GenerateAmendedContracts generateAmendedContracts = new BAER08_GenerateAmendedContracts();
        Database.executeBatch(generateAmendedContracts);
    }

    global void finish(Database.BatchableContext BC) {

    }

}