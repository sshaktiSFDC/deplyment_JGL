/**
* @name         : LoyaltyWalletLinksRestServiceTest
* @description  : This is test class of LoyaltyWalletLinksRestService.
* @testClass    : LoyaltyWalletLinksRestServiceTest
* <Date>        <Modified By>     	<Brief Description of Change>
* 2024-03-26    Vince Vuong         Created
*/
@isTest
private class LoyaltyWalletLinksRestServiceTest {
    //TODO
    //
    //
    public class GlobalConstants {
        public Integer HTTP_STATUS_CODE_BAD_REQUEST =400;
       public String CONTENT_TYPE_APPLICATION_JSON = 'application/json'; 
    }
     @isTest
    static void testDoGet() {
        // Create test data
        // Create a test contact
        Contact contact = new Contact();
        contact.LastName = 'Russel';
        contact.Birthdate = Date.Today();
        insert contact;

 LoyaltyProgram  loyaltyProgram = new LoyaltyProgram();
         loyaltyProgram.Name = 'Just Shop';
          insert loyaltyProgram;

        // Create a test loyalty program member
        LoyaltyProgramMember programMember = new LoyaltyProgramMember();
		programMember.MembershipNumber = 'Test1234';
		programMember.MemberStatus = 'Active';
		programMember.EnrollmentDate = Date.Today();
        programMember.MemberType = 'Individual';
        programMember.ContactId = contact.Id;
        programMember.ProgramId = loyaltyProgram.Id;
		insert programMember;
        
        String membership = programMember.MembershipNumber;
        String progName = loyaltyProgram.Name;

        // Set up the mock request
        RestRequest request = new RestRequest();
        request.requestURI = '/loyalty/programs/' + progName + '/members/' + 'Test1234' + '/wallet-links';
        RestContext.request = request;
        
       
        
         // Set up the mock response
        RestResponse response = new RestResponse();
        response.statusCode = 200;
        // Set other response properties as needed
        RestContext.response = response;

        // Call the REST service method
        Test.startTest();
        LoyaltyWalletLinksRestService.doGet();
        Test.stopTest();

        // Verify the response
       // RestResponse response = RestContext.response;
        System.assertEquals(200, response.statusCode, 'Expected status code 200');
        // Add more assertions as needed
    }
    
    
    // 2nd test data
    // 
    @isTest
    static void testDoGet1() {
        // Create test data
        // Create a test contact
        Contact contact = new Contact();
        contact.LastName = 'Russel1';
        contact.Birthdate = Date.Today();
        insert contact;

 LoyaltyProgram  loyaltyProgram = new LoyaltyProgram();
         loyaltyProgram.Name = 'Just Shop';
          insert loyaltyProgram;

        // Create a test loyalty program member
        LoyaltyProgramMember programMember = new LoyaltyProgramMember();
		programMember.MembershipNumber = 'Test12345';
		programMember.MemberStatus = 'Active';
		programMember.EnrollmentDate = Date.Today();
        programMember.MemberType = 'Individual';
        programMember.ContactId = contact.Id;
        programMember.ProgramId = loyaltyProgram.Id;
		insert programMember;
        
        String membership = programMember.MembershipNumber;
        String progName = loyaltyProgram.Name;

        // Set up the mock request
        RestRequest request = new RestRequest();
        request.requestURI = '/loyalty/programs/' + progName + '/members/' + 'Test123456' + '/wallet-links';
        RestContext.request = request;
        
       
        
         // Set up the mock response
        RestResponse response = new RestResponse();
        response.statusCode = 400;
        // Set other response properties as needed
        RestContext.response = response;

        // Call the REST service method
        Test.startTest();
        LoyaltyWalletLinksRestService.doGet();
        Test.stopTest();

        // Verify the response
       // RestResponse response = RestContext.response;
        System.assertEquals(400, response.statusCode, 'Expected status code 400');
        // Add more assertions as needed
    }
}