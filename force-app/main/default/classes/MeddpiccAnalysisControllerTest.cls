@IsTest
private class MeddpiccAnalysisControllerTest {
    @TestSetup
    static void setup() {
        Account acct = new Account(Name = 'Test MEDDPICC Account', Industry = 'Technology');
        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'Test Deal',
            AccountId = acct.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(60),
            Amount = 250000
        );
        insert opp;

        MEDDPICC_Assessment__c assessment = new MEDDPICC_Assessment__c(
            Account__c = acct.Id,
            Opportunity__c = opp.Id,
            Assessment_Date__c = Date.today(),
            Synced_From_Clari__c = true,
            Last_Clari_Sync__c = Datetime.now(),
            Metrics__c = 'Revenue increase of 15% projected through improved distribution network efficiency.',
            Economic_Buyer__c = 'CFO Jane Smith — budget authority confirmed, engaged in last two meetings.',
            Decision_Criteria__c = 'Technical: API integration, scalability. Business: ROI within 12 months.',
            Decision_Process__c = 'Technical eval → Business review → CFO sign-off. Timeline: 6 weeks.',
            Paper_Process__c = 'Standard procurement, legal review 2-3 weeks, MSA already on file.',
            Identify_Pain__c = 'Current system causes 20% order fulfillment delays, costing $2M annually.',
            Champion__c = 'VP of Operations Mike Chen — actively advocating internally.',
            Competition__c = 'Oracle Supply Chain competing. Our edge: faster implementation and better UX.',
            Score_Metrics__c = 8,
            Score_Economic_Buyer__c = 7,
            Score_Decision_Criteria__c = 6,
            Score_Decision_Process__c = 5,
            Score_Paper_Process__c = 4,
            Score_Identify_Pain__c = 9,
            Score_Champion__c = 8,
            Score_Competition__c = 6
        );
        insert assessment;
    }

    @IsTest
    static void testGetMeddpiccData() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Test MEDDPICC Account' LIMIT 1];

        Test.startTest();
        MeddpiccAnalysisController.MeddpiccResult result = MeddpiccAnalysisController.getMeddpiccData(acct.Id);
        Test.stopTest();

        System.assertEquals('Test MEDDPICC Account', result.accountName, 'Account name should match');
        System.assertNotEquals(null, result.assessments, 'Assessments list should not be null');
        System.assertEquals(1, result.assessments.size(), 'Should have one assessment');

        MeddpiccAnalysisController.AssessmentData ad = result.assessments[0];
        System.assertEquals(8, ad.scoreMetrics, 'Metrics score should be 8');
        System.assertEquals(9, ad.scoreIdentifyPain, 'Identify Pain score should be 9');
        System.assertEquals('Test Deal', ad.opportunityName, 'Opportunity name should match');
        System.assertEquals(true, ad.syncedFromClari, 'Should be synced from Clari');
        System.assert(String.isNotBlank(ad.metrics), 'Metrics notes should be populated');
    }

    @IsTest
    static void testGetMeddpiccDataNoAssessments() {
        Account emptyAcct = new Account(Name = 'Empty Account');
        insert emptyAcct;

        Test.startTest();
        MeddpiccAnalysisController.MeddpiccResult result = MeddpiccAnalysisController.getMeddpiccData(emptyAcct.Id);
        Test.stopTest();

        System.assertEquals('Empty Account', result.accountName);
        System.assertEquals(0, result.assessments.size(), 'Should have no assessments');
    }

    @IsTest
    static void testAnalyzeMeddpiccNoAssessments() {
        Account emptyAcct = new Account(Name = 'No Data Account');
        insert emptyAcct;

        Test.startTest();
        MeddpiccAnalysisController.MeddpiccResult result = MeddpiccAnalysisController.analyzeMeddpicc(
            emptyAcct.Id,
            null,
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, result.error, 'Should return error for no assessments');
        System.assert(result.error.contains('No MEDDPICC assessments'), 'Error should mention no assessments');
    }
}
