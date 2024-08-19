/**
* @name         : LoyaltyProgramMemberTrigger
* @description  : This trigger is used to handle logic for Member Update Event platform event.
* <Date>        <Modified By>       <Brief Description of Change>
* 2024-04-19    Siddharth Singh     Created
* 2024-04-30    Vince Vuong         Cleaned up naming convention
*/
trigger MemberUpdateEventTrigger on Member_Update_Event__e (after insert) {
    new MemberUpdateEventTriggerHandler().run();
}