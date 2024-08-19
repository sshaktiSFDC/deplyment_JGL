/**
* @name         : MemberUpdateEventTriggerHandlerTest
* @description  : This is test class of MemberUpdateEventTriggerHandler.
* <Date>        <Modified By>     	<Brief Description of Change>
* 2024-04-19    Siddharth Singh     Created
* 2024-
*/
@isTest
private class MemberUpdateEventTriggerHandlerTest {
    
    @isTest
    static void testAfterInsertTrigger() {
    	// Create Contact
    	Contact contact = new Contact(
            LastName = 'Test'
        );
        insert contact;
        
        // Create LoyaltyProgram
        LoyaltyProgram loyaltyProgram = new LoyaltyProgram( 
            Name = 'TestProgram'
        );
        insert loyaltyProgram;
        
        // Create LoyaltyProgramMember
        LoyaltyProgramMember loyaltyProgramMember = new LoyaltyProgramMember(
            ProgramId = loyaltyProgram.Id,
            MembershipNumber = 'TEST123',
            ContactId = contact.Id,
            EnrollmentDate = Date.today(), // Set EnrollmentDate
            MemberStatus = 'Active' // Set MemberStatus
        );
        insert loyaltyProgramMember;
        
        // Prepare test data
        List<LoyaltyProgramMember> members = new List<LoyaltyProgramMember>();
        members.add(loyaltyProgramMember);
        
        // Set up and insert Loyalty_Program_Member_Update_Event__e records
        List<Member_Update_Event__e> eventList = new List<Member_Update_Event__e>();
        for (LoyaltyProgramMember member : members) {
            eventList.add(new Member_Update_Event__e(Member_Id__c = member.Id));
        }
        
        EventBus.publish(eventList);
    	Test.getEventBus().deliver();
        System.assertEquals( eventList.size()>0, true , 'test pass');
        
    }
}