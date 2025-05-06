@isTest
private class OpportunityLineItemControllerTest {

    @isTest
    static void testGetAndDeleteOpportunityLineItems() {
        Product2 prod = new Product2(Name='Test Car', IsActive=true, QuantityInStock__c=100);
        insert prod;

        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        PricebookEntry pbe = new PricebookEntry(Product2Id=prod.Id, Pricebook2Id=pb.Id, UnitPrice=10000, IsActive=true);
        insert pbe;

        Account acc = new Account(Name='Test Account');
        insert acc;

        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(), AccountId=acc.Id);
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp.Id, Quantity=1, UnitPrice=10000, PricebookEntryId=pbe.Id);
        insert oli;

        Test.startTest();
        List<OpportunityLineItem> results = OpportunityLineItemController.getOpportunityLineItems(opp.Id);
        System.assertEquals(1, results.size());
        OpportunityLineItemController.deleteOpportunityLineItem(oli.Id);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM OpportunityLineItem WHERE Id = :oli.Id]);
    }
}
