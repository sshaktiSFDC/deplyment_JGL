public with sharing class SearchLoyaltyLedgerByContactController {

    @AuraEnabled
    public static Id getContactId(Id sObjectRecordId){
        try {
            Id contactId = null;

            String sObjectName = String.valueOf(sObjectRecordId.getSObjectType());
            if (sObjectName == GlobalConstants.ACCOUNT_NAME) {
                Account personAccount = [SELECT Id, PersonContactId FROM Account WHERE Id = :sObjectRecordId];
                contactId = personAccount.PersonContactId;
            } else if (sObjectName == GlobalConstants.LOYALTY_PROGRAM_MEMBER_NAME) {
                LoyaltyProgramMember programMember = [SELECT Id, ContactId FROM LoyaltyProgramMember WHERE Id = :sObjectRecordId];
                contactId = programMember.ContactId;
            } else {
                throw new AuraHandledException('Component do not support this Sobject');
            }

            return contactId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<LoyaltyProgramMember> fetchMembershipDetails(Id contactId){
        try {
            List<LoyaltyProgramMember> loyaltyProgramMembers = new List<LoyaltyProgramMember>();
            loyaltyProgramMembers = [SELECT Id, MembershipNumber, Total_Rewards__c, Current_Status_Points__c, (SELECT Id, Name, PointsBalance FROM Loyalty_Member_Currency WHERE Name=:GlobalConstants.CURRENCY_POSITIVE_BALANCE) FROM LoyaltyProgramMember WHERE ContactId = :contactId];
            return loyaltyProgramMembers;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<sObject> searchLoyaltyLedger(Id contactId, String fromDate, String toDate, String orderNumber){
        try {

            String loyaltyLedgerQuey = 'SELECT Id, Points, EventType, ';
            loyaltyLedgerQuey += 'TransactionJournal.Name, TransactionJournal.Brand, TransactionJournal.ActivityDate, TransactionJournal.TransactionLocation, TransactionJournal.JournalType.Name, TransactionJournal.JournalSubType.Name, TransactionJournal.Order_ID__c, TransactionJournal.Order_Item_ID__c, TransactionJournal.Product.Description, TransactionJournal.Quantity, TransactionJournal.TransactionAmount';
            loyaltyLedgerQuey += ' FROM LoyaltyLedger WHERE LoyaltyProgramMember.ContactId = :contactId';

            if (!String.isBlank(orderNumber) && !String.isEmpty(orderNumber)) {
                loyaltyLedgerQuey += ' AND TransactionJournal.Order_ID__c = :orderNumber';
            } else if (!String.isBlank(fromDate) && !String.isEmpty(fromDate) && !String.isBlank(toDate) && !String.isEmpty(toDate)) {
                loyaltyLedgerQuey += ' AND TransactionJournal.ActivityDate >= ' + fromDate + 'T00:00:00.000+0000' + ' AND TransactionJournal.ActivityDate <= ' + toDate + 'T00:00:00.000+0000';
            }

            List<sObject> loyaltyRecordsList = Database.query(loyaltyLedgerQuey);
            return loyaltyRecordsList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
}