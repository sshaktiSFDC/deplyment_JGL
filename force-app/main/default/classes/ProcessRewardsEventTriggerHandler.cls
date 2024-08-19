/**
* @name         : ProcessRewardsEventTriggerHandler
* @description  : Handler class for Process Rewards Event Platform event trigger
* @testClass    : ProcessRewardsEventTriggerHandlerTest
* <Date>        <Modified By>     	<Brief Description of Change>
* 2024-04-10    Vince Vuong         Created
*/
public with sharing class ProcessRewardsEventTriggerHandler extends TriggerHandler {

    public override void afterInsert() {
        //Subscribe to platform events
        subscribeEvents(Trigger.New);    
    }
    
    //Subscribe to PEs - Determine whether to 1. Issue Vouchers or 2. Split Redemption/Reward Journals
    private static void subscribeEvents(List<Process_Rewards_Event__e> newEvents){
        System.debug('subscribeEvents >> ' + newEvents);

        List<LoyaltyProcessFlowWrapper.FlowInput> issueVoucherInputs = new List<LoyaltyProcessFlowWrapper.FlowInput>();
        List<LoyaltyProcessFlowWrapper.FlowInput> redemptionInputs = new List<LoyaltyProcessFlowWrapper.FlowInput>();

        // Iterate through each event.
        for (Process_Rewards_Event__e event : newEvents) {

            LoyaltyProcessFlowWrapper.FlowInput input = new LoyaltyProcessFlowWrapper.FlowInput();
            input.memberId = event.Member_ID__c;
            input.programId = event.Program_ID__c;
            input.orderId = event.Order_No__c;
            input.orderItemId = event.Order_Item_No__c;

            input.totalRewards = Integer.valueOf(event.Total_Rewards__c);
            input.totalPointsToDebit = Integer.valueOf(event.Total_Debit_Points__c);
            input.totalVouchersToIssue = Integer.valueOf(event.TotalVouchersToIssue__c);
            input.eventType = event.Event_Type__c;
            input.channel = event.Channel__c;

			//system.debug(event.Event_Type__c );
			//system.debug('LoyaltyProcessFlowWrapper.FlowInput >>' + input);

            if (event.Event_Type__c == 'Redemption') {
                redemptionInputs.add(input);
            }
            else {
                issueVoucherInputs.add(input);
            }
        }
		System.debug('issueVoucherInputs >> ' + issueVoucherInputs);
		System.debug('redemptionInputs >> ' + redemptionInputs);

        if (!issueVoucherInputs.isEmpty()) {
            issueRewardVouchers(issueVoucherInputs);
        }

		system.debug('redemptionInputs >> ' + redemptionInputs);
        if (!redemptionInputs.isEmpty()) {
            splitRedemptionJournals(redemptionInputs);
        }
    }

    //Handle and split Transaction Journals
    private static void splitRedemptionJournals(List<LoyaltyProcessFlowWrapper.FlowInput> inputs) {

        System.debug('splitRedemptionJournals = ' + inputs);
        //Recreate new TJ with Type = Redemption, Sub-Type = Reward, Amount = 200 and debit 200 points from Balance Currency
        //Create Program Ledger

        try {
            Set<String> orderIds = new Set<String>();
            List<TransactionJournal> tjList = new  List<TransactionJournal>();
            List<TransactionJournal> oldTjList = new  List<TransactionJournal>();
            List<LoyaltyLedger> transactionJournalLedgerList = new  List<LoyaltyLedger>();

            Map<String,String> orderIdVsflow = new Map<String,String>();
            Map<String,String> orderIdVsEventType = new Map<String,String>();
            Map<String,String> orderIdVsCurrency = new Map<String,String>();

            //Store Order IDs to Channel mappings
            Map<String, String> orderIdChannelMappings = new Map<String, String>();

            for(LoyaltyProcessFlowWrapper.FlowInput input: inputs){
                orderIds.add(input.orderId);
                orderIdChannelMappings.put(input.orderId, input.channel);
            }
            System.debug('orderIdChannelMappings = ' + orderIdChannelMappings);

            //Retrieve Journals matching Type = Redemption and Sub Type = Reward only!
            for(TransactionJournal tj : [SELECT Id,Order_ID__c,Order_Item_ID__c,Channel,Brand,TransactionAmount,LoyaltyProgramId,JournalSubTypeId,JournalTypeId,MemberId,ActivityDate,JournalDate,
                                            PartnerId,Channel_Name__c,
                                            (SELECT EventType,Points,LoyaltyProgramMemberId,LoyaltyProgramCurrencyId,TransactionJournalId,Flow,ActivityDate FROM TransactionJournalLedger) 
                                        FROM TransactionJournal 
                                        WHERE Order_ID__c IN :orderIds
                                        AND JournalType.Name =: GlobalConstants.JOURNAL_TYPE_REDEMPTION
                                        AND JournalSubType.Name =: GlobalConstants.JOURNAL_SUBTYPE_REWARD]){

                //Get total points to Debit
                Integer debitedPoints = (Integer)tj.TransactionJournalLedger[0].Points;
                System.debug('debitedPoints = ' + debitedPoints);

                //Make sure it's the right Redemption journals matching Order IDs and Channel!
                if (!orderIdChannelMappings.containsKey(tj.Order_ID__c) ) {
                    continue;
                }

                //Do we need to split journals?
                if(debitedPoints > GlobalConstants.REWARD_VOUCHER_TARGET_POINTS){
                    //Calculate total # of journals to split
                    Integer noOfTJ = Math.round(debitedPoints / GlobalConstants.REWARD_VOUCHER_TARGET_POINTS);

                    orderIdVsflow.put(tj.Order_ID__c, tj.TransactionJournalLedger[0].Flow);
                    orderIdVsCurrency.put(tj.Order_ID__c, tj.TransactionJournalLedger[0].LoyaltyProgramCurrencyId);
                    orderIdVsEventType.put(tj.Order_ID__c, tj.TransactionJournalLedger[0].EventType);

                    //Create new redemption journals
                    for(Integer i=0; i<noOfTJ; i++){
                        TransactionJournal newObj = new TransactionJournal();
                        newObj.LoyaltyProgramId = tj.LoyaltyProgramId;
                        newObj.MemberId = tj.MemberId;

                        newObj.Order_ID__c = tj.Order_ID__c;
                        newObj.Order_Item_ID__c = tj.Order_Item_ID__c;
                        newObj.TransactionAmount = GlobalConstants.REWARD_VOUCHER_TARGET_POINTS;    //Amount should be 200
                        newObj.JournalSubTypeId = tj.JournalSubTypeId;
                        newObj.JournalTypeId = tj.JournalTypeId;

                        //TODO: Convert these dates to UTC
                        newObj.ActivityDate = tj.ActivityDate;
                        newObj.JournalDate = tj.JournalDate;
                        newObj.Brand = tj.Brand;
                        newObj.PartnerId = tj.PartnerId;

                        //Take Channel from custom field if standard channel has no value.
                        newObj.Channel = (tj.Channel != null) ? tj.Channel : tj.Channel_Name__c;

                        //Make sure Status = Processed
                        newObj.Status = GlobalConstants.JOURNAL_STATUS_PROCESSED;

                        //TODO: Copy other fields as required here...

                        tjList.add(newObj);
                    }
                }
                oldTjList.add(tj);
            }

            //TODO: We need to use Atomic transaction - All or Nothing using SavePoints
            if (!tjList.isEmpty()) {
                insert tjList;
                delete oldTjList;   //Only delete old journals if we're splitting into multiple
            }

            //Create new ledgers and associated with the new journals
            for (TransactionJournal insertedTJ : tjList) {
                LoyaltyLedger tjl = new LoyaltyLedger();
                tjl.EventType = orderIdVsEventType.get(insertedTJ.Order_ID__c);
                tjl.Points = GlobalConstants.REWARD_VOUCHER_TARGET_POINTS;
                tjl.LoyaltyProgramMemberId = insertedTJ.MemberId;
                tjl.LoyaltyProgramCurrencyId = orderIdVsCurrency.get(insertedTJ.Order_ID__c);
                tjl.TransactionJournalId = insertedTJ.Id;
                tjl.Flow = orderIdVsflow.get(insertedTJ.Order_ID__c);
                tjl.ActivityDate= insertedTJ.ActivityDate;
                transactionJournalLedgerList.add(tjl);
            }
            
            if (!transactionJournalLedgerList.isEmpty()) {
                insert transactionJournalLedgerList;
            }
        
        } catch (Exception ex) {
            system.debug('Exception = ' + ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    //Issue reard vouchers
    private static void issueRewardVouchers(List<LoyaltyProcessFlowWrapper.FlowInput> inputs) {

        //List<Process_Rewards_Event__e> events = new List<Process_Rewards_Event__e>();
        List<LoyaltyProcessFlowWrapper.FlowOutput> outputs = new List<LoyaltyProcessFlowWrapper.FlowOutput>();
        List<LoyaltyManagement.IssueVoucherInput> issueVoucherList = new List<LoyaltyManagement.IssueVoucherInput>();

        for (LoyaltyProcessFlowWrapper.FlowInput rec : inputs) {
            LoyaltyProcessFlowWrapper.FlowOutput output = new LoyaltyProcessFlowWrapper.FlowOutput();

            //Loop through # of vouchers to create
            for(Integer count = 1; count <= rec.totalVouchersToIssue; count++) {
                LoyaltyManagement.IssueVoucherInputBuilder voucher = new LoyaltyManagement.IssueVoucherInputBuilder();
                voucher.setLoyaltyProgramMemberId(rec.memberId);
                voucher.setProgramName(GlobalConstants.LOYALTY_PROGRAM_NAME);
                voucher.setVoucherDefinitionName(GlobalConstants.VOUCHER_DEFINITION_REWARD);
                //voucher.setJournalId(rec.Id);

                //TODO: We need to use Accrual journal date to as Effective Date when issuing vouchers
  	            //voucher.setEffectiveDate(effectiveDate);
  	            //voucher.setExpiryDate(expirationDate);
	            //voucher.setFaceValue(10);

                issueVoucherList.add(voucher.build());
            }

            outputs.add(output);
        }
        System.debug('issueVoucherList = ' + issueVoucherList);

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
            for(Id voucherId : voucherIds) {
                vouchersToUpdate.add( new Voucher(
                    Id = voucherId,
                    Order_Id_Issue__c = inputs[0].orderId,
                    Order_Id_Issue_Channel__c = inputs[0].channel
                ));
            }
            System.debug('vouchersToUpdate = ' + vouchersToUpdate);

            if (!vouchersToUpdate.isEmpty()){
                update vouchersToUpdate;
            }
        }
    }
    
}