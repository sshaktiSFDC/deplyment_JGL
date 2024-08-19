/**
* @name         : ProcessRewardsAction
* @description  : This invocable action is used to recreate Redemption transaction journals
* @testClass    : TODO -> ProcessRewardsActionTest
* <Date>        <Modified By>     	<Brief Description of Change>
* 2024-04-10    Vince Vuong         Created
* 2024-04-24    Vince Vuong         Updated logic
*/ 
public without sharing class ProcessRewardsAction {

    @InvocableMethod(label='Publish PE for Redemption Rewards')
    public static List<LoyaltyProcessFlowWrapper.FlowOutput> processRewards(List<LoyaltyProcessFlowWrapper.FlowInput> inputs) {

        System.debug('ProcessRewardsAction count = ' + inputs.size());
        System.debug('inputs = ' +  inputs);
        List<Process_Rewards_Event__e> events = new List<Process_Rewards_Event__e>();
        List<LoyaltyProcessFlowWrapper.FlowOutput> outputs = new List<LoyaltyProcessFlowWrapper.FlowOutput>();

        //Publish only the first record to the PE
        //for (LoyaltyProcessFlowWrapper.FlowInput rec : inputs) {
            LoyaltyProcessFlowWrapper.FlowOutput output = new LoyaltyProcessFlowWrapper.FlowOutput();
            events.add(new Process_Rewards_Event__e(
                Member_ID__c = inputs[0].memberId, 
                Program_ID__c = inputs[0].programId,
                Order_No__c = inputs[0].orderId,
                Order_Item_No__c = inputs[0].orderItemId,
                Total_Rewards__c = inputs[0].totalRewards,
                Total_Debit_Points__c = inputs[0].totalPointsToDebit,
                TotalVouchersToIssue__c = inputs[0].totalVouchersToIssue,
                Event_Type__c = inputs[0].eventType,
                Channel__c = inputs[0].channel
            ));

            outputs.add(output);
        //}
            System.debug(events);
        if (!events.isEmpty()) {
            // Call method to publish events
            List<Database.SaveResult> results = EventBus.publish(events);

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
        return outputs;
    }

    //BACKUP
    /*
    public static List<ProcessRewardsOutput> processRewards2(List<ProcessRewardsInput> inputs) {
        System.debug('Inputs count = ' + inputs.size());
        System.debug('inputs = ' +  inputs);

        //Create transaction journals to represent points expiration
        List<TransactionJournal> journals = new List<TransactionJournal>();

        List<Voucher> vouchersToCreate = new List<Voucher>();

        Set<String> orderIdsSet = new Set<String>();
        for (ProcessRewardsInput rec : inputs) {
            if (String.isNotBlank(rec.orderId)) {
                orderIdsSet.add(rec.orderId);
            }
        }

        //Find Matching Order ID
        Map<String, ID> journalMappings = new Map<String, ID>();
        for(TransactionJournal rec : [SELECT Id, Order_ID__c, Order_Item_ID__c FROM TransactionJournal WHERE Order_ID__c =: orderIdsSet]){
            String key = rec.Order_ID__c + '-' + rec.Order_Item_ID__c;
            journalMappings.put(key, rec.Id);
        }
        System.debug('journalMappings = ' +  journalMappings);

        List<LoyaltyManagement.IssueVoucherInput> issueVoucherList = new List<LoyaltyManagement.IssueVoucherInput>();
        List<ProcessRewardsOutput> outputs = new List<ProcessRewardsOutput>();

        for (ProcessRewardsInput rec : inputs) {
            ProcessRewardsOutput output = new ProcessRewardsOutput();
            //output.loyaltyProgramName = GlobalConstants.LOYALTY_PROGRAM_NAME;
            //output.voucherRewardDefinitionName = GlobalConstants.VOUCHER_DEFINITION_REWARD;
            
            String journalKey = rec.orderId + '-' + rec.orderItemId;

            //Issue New Vouchers
            for(Integer count = 0; count < rec.totalRewards; count++) {

                //Create Journals for record tracking
                journals.add(new TransactionJournal(
                    LoyaltyProgramId = rec.programId,
                    MemberId = rec.memberId,
                    JournalTypeId = LoyaltyRuntimeHelper.journalTypeIdMappings.get('Redemption'),
                    JournalSubTypeId = LoyaltyRuntimeHelper.journalSubTypeIdMappings.get('Reward2'),
                    ActivityDate = System.Now(),
                    JournalDate = System.Now(),
                    Status = 'Processed',
                    TransactionAmount = 10,
                    Order_ID__c = rec.orderId,
                    Order_Item_ID__c = rec.orderItemId
                ));
            }
            outputs.add(output);
        }
        System.debug('journals = ' + journals);

        //TODO: Create transaction journal for each voucher issued so we can debit points and create ledger
        if (!journals.isEmpty()) {
            insert journals;
        }

        List<MemberCurrencyHelper.MemberPointWrapper> memberCurrenciesToDebit = new List<MemberCurrencyHelper.MemberPointWrapper>();

        //
        for(TransactionJournal rec : journals){
            LoyaltyManagement.IssueVoucherInputBuilder voucher = new LoyaltyManagement.IssueVoucherInputBuilder();
            voucher.setLoyaltyProgramMemberId(rec.memberId);
            voucher.setProgramName(GlobalConstants.LOYALTY_PROGRAM_NAME);
            voucher.setVoucherDefinitionName(GlobalConstants.VOUCHER_DEFINITION_BIRTHDAY);
            voucher.setJournalId(rec.Id);

            //Optional fields
  	        //voucher.setEffectiveDate(effectiveDate);
  	        //voucher.setExpiryDate(expirationDate);
	        //voucher.setFaceValue(10);

            //issueVoucherList.add(voucher.build());

            //Debit Points for each voucher issued
            MemberCurrencyHelper.MemberPointWrapper wrapper = new MemberCurrencyHelper.MemberPointWrapper();
            wrapper.memberId = rec.MemberId;
            wrapper.journalId = rec.Id;
            wrapper.currencyName = GlobalConstants.CURRENCY_POSITIVE_BALANCE;
            wrapper.debitPoints = 200;

            memberCurrenciesToDebit.add(wrapper);
        }
        System.debug('issueVoucherList = ' + issueVoucherList);
        System.debug('memberCurrenciesToDebit = ' + memberCurrenciesToDebit);

        // Insert vouchers outside the loop
        if (!issueVoucherList.isEmpty()) {
            // insert vouchersToInsert;
            List<LoyaltyManagement.IssueVoucherOutput> issueVoucherActionResults = LoyaltyManagement.LoyaltyResources.issueVoucher(issueVoucherList); 
            System.debug(issueVoucherActionResults);
            System.debug('Issue Voucher Successful Operation:'+ issueVoucherActionResults.get(0));

            //TODO: Stamp Order ID and Order Item ID against vouchers issued
            List<Id> voucherIds = new List<Id>();
            for(LoyaltyManagement.IssueVoucherOutput rec : issueVoucherActionResults) {
                if (rec.isSuccess()) {
                    voucherIds.add(rec.getVoucherId());
                }
            }
            System.debug('voucherIds = ' + voucherIds);

            List<Voucher> vouchersToUpdate = new List<Voucher>();
            for(Voucher rec : [SELECT Id, Order_ID__c, Order_Item_ID__c, 
                                TransactionJournalId, TransactionJournal.Order_ID__c, TransactionJournal.Order_Item_ID__c
                                FROM Voucher 
                                WHERE Id = :voucherIds]) {
                
                vouchersToUpdate.add( new Voucher(
                    Id = rec.Id,
                    Order_ID__c = rec.TransactionJournal.Order_ID__c,
                    Order_Item_ID__c = rec.TransactionJournal.Order_Item_ID__c
                ));
            }
            System.debug('vouchersToUpdate = ' + vouchersToUpdate);

            if (!vouchersToUpdate.isEmpty()){
                update vouchersToUpdate;
            }

        }

        if (!memberCurrenciesToDebit.isEmpty()) {
            //Debit Points
            //MemberCurrencyHelper.debitPoints(memberCurrenciesToDebit);
        }

        return outputs;
    }
    */

    /*public class ProcessRewardsInput {
        @InvocableVariable public ID programId;
        @InvocableVariable public ID memberId;
        @InvocableVariable public String orderId;
        @InvocableVariable public String orderItemId;
        @InvocableVariable public String voucherCodeIssued;
        @InvocableVariable public String voucherFaceValue;
        @InvocableVariable public Integer totalRewards;
        @InvocableVariable public Integer totalPointsToDebit;
        @InvocableVariable public Integer voucherTargetPoints;
        @InvocableVariable public Integer totalVouchersToIssue;
    }

    public class ProcessRewardsOutput {
        @InvocableVariable public String loyaltyProgramName;
        @InvocableVariable public String voucherRewardDefinitionName;
        @InvocableVariable public Integer voucherRewardTargetValue;
        @InvocableVariable public Decimal voucherRewardFaceValue;
    }*/

    /*private static void createRewardJournals() {
        //TODO: Create redemption journals for each voucher issued    
    }
    */

}