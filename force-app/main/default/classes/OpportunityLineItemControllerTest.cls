@isTest
// Teste la suppression, récupération et mise à jour des lignes d’opportunité.

private class OpportunityLineItemControllerTest {

    // Vérifie que la suppression d'une ligne fonctionne
    @isTest
    static void testDeleteOpportunityLineItem() {
        TestDataFactory.TestDataWrapper data = TestDataFactory.createFullOpportunity(
            'Produit B', 5, 200, 1, 'Opp Delete', 'Prospecting', 2
        );

        System.assertNotEquals(null, data.oli);

        Test.startTest();
        OpportunityLineItemController.deleteOpportunityLineItem(data.oli.Id);
        Test.stopTest();

        List<OpportunityLineItem> remaining = [
            SELECT Id, IsDeleted FROM OpportunityLineItem WHERE Id = :data.oli.Id ALL ROWS
        ];
        System.assertEquals(true, remaining.isEmpty() || remaining[0].IsDeleted);
    }

    // Vérifie qu'une ligne est bien récupérée
    @isTest
    static void testGetOpportunityLineItems_SingleLine() {
        TestDataFactory.TestDataWrapper data = TestDataFactory.createFullOpportunity(
            'Produit C', 15, 100, 2, 'Opp Lignes', 'Prospecting', 5
        );

        Test.startTest();
        List<OpportunityLineItem> result = OpportunityLineItemController.getOpportunityLineItems(data.opportunity.Id);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(data.oli.Id, result[0].Id);
    }

    // Vérifie que zéro ligne est retournée si l'opportunité est vide
    @isTest
    static void testGetOpportunityLineItems_NoLine() {
        Opportunity emptyOpp = TestDataFactory.createEmptyOpportunity('Opp Sans Ligne', 'Prospecting', 3);

        Test.startTest();
        List<OpportunityLineItem> result = OpportunityLineItemController.getOpportunityLineItems(emptyOpp.Id);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    // Vérifie que l’appel ne plante pas avec un ID d’opportunité invalide
    @isTest
    static void testGetOpportunityLineItems_InvalidId() {
        Test.startTest();
        List<OpportunityLineItem> result = OpportunityLineItemController.getOpportunityLineItems('006000000000001AAA');
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    // Vérifie que plusieurs lignes sont bien récupérées
    @isTest
    static void testGetOpportunityLineItems_MultipleLines() {
        Id standardPricebookId = Test.getStandardPricebookId();
        Opportunity opp = TestDataFactory.createOpportunity('Opp Multi-Lignes', 'Qualification', 10, standardPricebookId);
        List<OpportunityLineItem> createdOlis = TestDataFactory.createMultipleOpportunityLines(opp, 3);

        Test.startTest();
        List<OpportunityLineItem> result = OpportunityLineItemController.getOpportunityLineItems(opp.Id);
        Test.stopTest();

        System.assertEquals(3, result.size());
        Set<Id> createdOliIds = new Set<Id>();
        for (OpportunityLineItem oli : createdOlis) {
            createdOliIds.add(oli.Id);
        }
        for (OpportunityLineItem resultOli : result) {
            System.assert(createdOliIds.contains(resultOli.Id));
        }
    }

    // Vérifie la mise à jour de stock avec données valides et invalides
    @isTest
    static void testUpdateProductStock_ValidAndInvalidData() {
        Product2 p1 = TestDataFactory.createProduct('Produit P1', 5);
        Product2 p2 = TestDataFactory.createProduct('Produit P2', 10);
        Product2 p3 = TestDataFactory.createProduct('Produit P3', 15);

        List<Map<String, Object>> updates = new List<Map<String, Object>>{
            new Map<String, Object>{'productId' => p1.Id, 'quantityInStock' => 8},
            new Map<String, Object>{'productId' => p2.Id, 'quantityInStock' => 6.5},
            new Map<String, Object>{'quantityInStock' => 99},
            new Map<String, Object>{'productId' => p2.Id, 'quantityInStock' => 'invalide'}
        };

        Test.startTest();
        OpportunityLineItemController.updateProductStock(updates);
        Test.stopTest();

        Product2 updated1 = [SELECT QuantityInStock__c FROM Product2 WHERE Id = :p1.Id];
        Product2 updated2 = [SELECT QuantityInStock__c FROM Product2 WHERE Id = :p2.Id];
        Product2 updated3 = [SELECT QuantityInStock__c FROM Product2 WHERE Id = :p3.Id];

        System.assertEquals(8, updated1.QuantityInStock__c);
        System.assertEquals(6.5, updated2.QuantityInStock__c);
        System.assertEquals(15, updated3.QuantityInStock__c);
    }

    // Vérifie que les données vides ou invalides ne provoquent pas d’erreur
    @isTest
    static void testUpdateProductStock_EmptyAndInvalidOnly() {
        Product2 pEmptyTest1 = TestDataFactory.createProduct('Produit EmptyTest1', 10);

        Test.startTest();
        OpportunityLineItemController.updateProductStock(new List<Map<String, Object>>());

        List<Map<String, Object>> invalidUpdates = new List<Map<String, Object>>{
            new Map<String, Object>{'quantityInStock' => 'non-numérique'},
            new Map<String, Object>{'productId' => null, 'quantityInStock' => null}
        };
        OpportunityLineItemController.updateProductStock(invalidUpdates);
        Test.stopTest();

        Product2 updatedPEmptyTest1 = [SELECT QuantityInStock__c FROM Product2 WHERE Id = :pEmptyTest1.Id];
        System.assertEquals(10, updatedPEmptyTest1.QuantityInStock__c);
    }
}
