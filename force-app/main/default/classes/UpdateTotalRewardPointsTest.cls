@isTest
private class UpdateTotalRewardPointsTest {
    
    @isTest
    static void testExecute() {
       	UpdateTotalRewardPoints schedulableClass = new UpdateTotalRewardPoints();
       	Test.startTest();
        String jobId = System.schedule('Test Job', '0 0 0 * * ?', schedulableClass);
		CronTrigger cronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                                   FROM CronTrigger WHERE Id = :jobId];
        
        System.assertNotEquals(null, cronTrigger);
        
        Test.stopTest();
        
     }
}