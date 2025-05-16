@isTest
private class OpportunityLineItemControllerTest {

    @isTest
    static void testGetDeleteAndUpdateOpportunityLineItems() {
        // crée les prérequis: pricebook, produit, compte, opp, entry
        Pricebook2 pb = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if (!pb.IsActive) { pb.IsActive = true; update pb; }

        Product2 prod = new Product2(Name = 'Test Car', IsActive = true, QuantityInStock__c = 50);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(Product2Id = prod.Id, Pricebook2Id = pb.Id, UnitPrice = 20000, IsActive = true);
        insert pbe;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = acc.Id, Pricebook2Id = pb.Id);
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Quantity = 1, UnitPrice = 20000, PricebookEntryId = pbe.Id);
        insert oli;

        // test recup
        Test.startTest();
        List<OpportunityLineItem> results = OpportunityLineItemController.getOpportunityLineItems(opp.Id);
        Test.stopTest();
        System.assertEquals(1, results.size(), 'doit retourner 1 ligne');

        // test suppression
        Test.startTest();
        OpportunityLineItemController.deleteOpportunityLineItem(oli.Id);
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM OpportunityLineItem WHERE Id = :oli.Id]);

        // test update stock
        Map<String, Object> updateRow = new Map<String, Object>{ 'productId' => prod.Id, 'quantityInStock' => 75 };
        List<Map<String, Object>> updates = new List<Map<String, Object>>{ updateRow };

        Test.startTest();
        OpportunityLineItemController.updateProductStock(updates);
        Test.stopTest();

        Product2 updatedProd = [SELECT QuantityInStock__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals(75, updatedProd.QuantityInStock__c, 'stock doit etre mis a jour');

        // 🆕 test suppression id null
        Boolean errorThrown = false;
        try {
            Test.startTest();
            OpportunityLineItemController.deleteOpportunityLineItem(null);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            errorThrown = true; // doit throw
        }
        System.assertEquals(true, errorThrown, 'Suppression null doit throw erreur');
    }
}

