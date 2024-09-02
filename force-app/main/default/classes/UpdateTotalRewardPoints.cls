global class UpdateTotalRewardPoints implements Schedulable {
    global void execute(SchedulableContext sc) {
        Map<String, Object> flowParams = new Map<String, Object>();
        //Instantiate the flow
     Flow.Interview.Update_total_reward_on_Loyalty_Program_Member_Autolaunched flow = new Flow.Interview.Update_total_reward_on_Loyalty_Program_Member_Autolaunched(flowParams);
        //Start the flow
       flow.start();
    }
}