/**
* @name         : LoyaltyProgramMemberTriggerHandlerTest
* @description  : This is test class of LoyaltyProgramMemberTriggerHandler.
* @testClass    : 
* <Date>        <Modified By>     	<Brief Description of Change>
* 2024-03-13    Siddharth Singh     Created
*/
@isTest
private class LoyaltyProgramMemberTriggerHandlerTest {

    @isTest
    static void testAfterInsert() {
        // Create test data
        // Create Contact
 
        Contact contact = new Contact(
            LastName = 'Test'
        );
        insert contact;
        // Create LoyaltyProgram
        LoyaltyProgram loyaltyProgram = new LoyaltyProgram(
            Name = 'TestProgram2'
            
        );
        insert loyaltyProgram;

        List<LoyaltyProgramMember> testMembers = new List<LoyaltyProgramMember>();
        for (Integer i = 0; i < 5; i++) {
            LoyaltyProgramMember member = new LoyaltyProgramMember(
                ProgramId = loyaltyProgram.Id,
                MembershipNumber = 'M11'+i,
                ContactId = contact.Id,
                EnrollmentDate = Date.today(), // Set EnrollmentDate
                MemberStatus = 'Active' // Set MemberStatus
            );
            testMembers.add(member);
        }
        insert testMembers;

        // Call the afterInsert method
        Test.startTest();
        LoyaltyProgramMemberTriggerHandler.generateMembershipNumbers(testMembers);
        Test.stopTest();

    }
}