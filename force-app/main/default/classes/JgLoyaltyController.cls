public class JgLoyaltyController {
    
    public class SearchWrapper {
        @AuraEnabled public Boolean result;
        @AuraEnabled public String lastError;
        @AuraEnabled public List<LoyaltyProgramMember> loyaltyMembers;
    }

    public class MemberWrapper {
        @AuraEnabled public Boolean result;
        @AuraEnabled public String lastError;
        @AuraEnabled public LoyaltyProgramMember loyaltyMember;
    }
    
    @AuraEnabled public static SearchWrapper searchLoyaltyMemebers(String searchTerm) {    
        SearchWrapper wrapper = new SearchWrapper();
        try {
            // SOQL query to find LoyaltyProgramMember records based on the MembershipNumber or Contact's details
            wrapper.loyaltyMembers = [SELECT Id, MembershipNumber, Contact.FirstName, Contact.LastName, Contact.Email
                                                         FROM LoyaltyProgramMember 
                                                         WHERE MembershipNumber = :searchTerm 
                                                         OR Contact.FirstName LIKE :('%' + searchTerm + '%') 
                                                         OR Contact.LastName LIKE :('%' + searchTerm + '%')
                                                         OR Contact.Email LIKE :('%' + searchTerm + '%')];
            
            wrapper.result = true;
        }
        catch (Exception e) {
            wrapper.result = false;
            wrapper.lastError = 'Exception occured searchLoyaltyMemebers: ' + e.getMessage() + ' line: ' + e.getLineNumber();
        }
        return wrapper;
    }

    @AuraEnabled public static MemberWrapper getLoyaltyMemeber(String memberNumber) {    
        MemberWrapper wrapper = new MemberWrapper();
        try {
            // SOQL query to find LoyaltyProgramMember records based on the MembershipNumber or Contact's details
            List<LoyaltyProgramMember> loyaltyMembers = [SELECT Id, MembershipNumber, Contact.FirstName, Contact.LastName, Contact.Email  
                                                         FROM LoyaltyProgramMember 
                                                         WHERE MembershipNumber = :memberNumber];
            if (loyaltyMembers.Size() > 0) {
                wrapper.loyaltyMember = loyaltyMembers[0];
                wrapper.result = true;
            } else {
                wrapper.lastError = 'Loyalty Member not found for Membership Number: ' + memberNumber;
                wrapper.result = false;
            } 
        }
        catch (Exception e) {
            wrapper.result = false;
            wrapper.lastError = 'Exception occured getLoyaltyMemeber: ' + e.getMessage() + ' line: ' + e.getLineNumber();
        }
        return wrapper;
    }
    
    
}