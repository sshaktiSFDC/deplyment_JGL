/**
* @name         : LoyaltyProgramMemberTriggerHandler
* @description  : This class is used to Handle the event for Loyalty Program Member Trigger.
* @testClass    : LoyaltyProgramMemberTriggerHandlerTest
* <Date>        <Modified By>     	<Brief Description of Change>
* 2024-02-12    Vince Vuong         Created
* 2024-03-13    Siddharth Singh     Modified--Bulkify the code
*/
public with sharing class LoyaltyProgramMemberTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
    }

    public override void beforeUpdate() {
    }

    public override void afterInsert() {
        //Generate membership numbers
        generateMembershipNumbers(Trigger.new);
        isMemberRecordChanged(Trigger.new);
    }

    public override void afterUpdate() {
        isMemberRecordChanged(Trigger.new);
    }

    //Private method to generate new membership numbers
    @testVisible private static void generateMembershipNumbers(List<LoyaltyProgramMember> newMembers){
        List<LoyaltyProgramMember> listOfMembersToUpdate = new List<LoyaltyProgramMember>();
        Map<String, LoyaltyProgramMember> programMemberMappings = new Map<String, LoyaltyProgramMember>();

        // Collect unique IDs from the new members
        Set<Id> LoyaltyProgramMemberIds = new Set<Id>();
        for (LoyaltyProgramMember newMember : newMembers) {
            LoyaltyProgramMemberIds.add(newMember.Id);
        }

        for(LoyaltyProgramMember rec : [SELECT Id, MembershipNumber, Unique_ID__c FROM LoyaltyProgramMember WHERE Id IN : LoyaltyProgramMemberIds]){
            programMemberMappings.put(rec.Unique_ID__c, rec);
        }

        // gettng the final customer number from the Utility helper 
        Map<String, String> finalNumberMappings = UtilityHelper.generateMembershipNumbers(programMemberMappings.keyset());
        System.debug('finalNumberMappings = ' + finalNumberMappings);

        for(LoyaltyProgramMember rec : programMemberMappings.Values()){
            //TODO: Copy current membership number (CIM customer ID) to another field.
            rec.MembershipNumber = finalNumberMappings.get(rec.Unique_ID__c);
            listOfMembersToUpdate.add(rec);
        }
        System.debug('listOfMembersToUpdate = ' + listOfMembersToUpdate);

        try {
            if(listOfMembersToUpdate.size()>0){
                update listOfMembersToUpdate;
            }
        }catch (Exception ex) {
            System.debug('An error occurred while updating LoyaltyProgramMembers: ' + ex.getMessage());
            //Logger.error(GlobalConstants.EXCEPTION_MESSAGE_PREFIX + ex.getStackTraceString());
        } 
    }

    //Method to detect whether loyalt member record being updated or changed
    @testVisible private void isMemberRecordChanged(List<LoyaltyProgramMember> members) {

        System.System.debug('isMemberRecordChanged');

        System.System.debug(Trigger.oldMap);
        System.System.debug(Trigger.new);
        
        List<Member_Update_Event__e> memberUpdateEvents = new List<Member_Update_Event__e>();
        try{
            for (LoyaltyProgramMember member : members) {
            	LoyaltyProgramMember oldObj = (LoyaltyProgramMember)Trigger.oldMap.get(Member.Id);
            
                if (oldObj != null) {
                    // Check if specific field values have changed
                    if (oldObj.Contact.FirstName != member.Contact.FirstName 
                        || oldObj.Contact.LastName != member.Contact.LastName 
                        || oldObj.Status_Points__c != member.Status_Points__c 
                        || oldObj.Total_Rewards__c != member.Total_Rewards__c) {

                        // Field value has changed
                        Member_Update_Event__e memberPEvent = new Member_Update_Event__e();
                        memberPEvent.Member_Id__c = Member.Id;
                        memberUpdateEvents.add(memberPEvent);
                    }
                }
                else{
                    Member_Update_Event__e memberPEvent = new Member_Update_Event__e();
                    memberPEvent.Member_Id__c = Member.Id;
                    memberUpdateEvents.add(memberPEvent);
                }
        	}
            // Call method to publish events
            List<Database.SaveResult> results = EventBus.publish(MemberUpdateEvents);
            System.debug('results >> ' + results);
    
            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
       	}
        catch (Exception ex) {
            System.debug('An error occurred while Inserting platorm Events: ' + ex.getMessage());
        }
    }
}