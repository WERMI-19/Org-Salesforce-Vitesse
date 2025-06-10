@isTest
private class OpportunityLineItemControllerTest {

    /**
     * Teste la récupération d’une ligne de produit (cas standard).
     */
    @isTest
    static void testGetOpportunityLineItems_SingleLine() {
        TestDataFactory.TestDataWrapper data = TestDataFactory.createFullOpportunity(
            'Produit C', 15, 100, 2, 'Opp Lignes', 'Prospecting', 5
        );

        Test.startTest();
        List<OpportunityLineItem> result = OpportunityLineItemController.getOpportunityLineItems(data.opportunity.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Une seule ligne est attendue');
        System.assertEquals(data.oli.Id, result[0].Id, 'La ligne retournée doit correspondre à celle insérée');
    }

    /**
     * Cas : opportunité sans ligne de produit → résultat vide attendu.
     */
    @isTest
    static void testGetOpportunityLineItems_NoLine() {
        Opportunity emptyOpp = TestDataFactory.createEmptyOpportunity('Opp Sans Ligne', 'Prospecting', 3);

        Test.startTest();
        List<OpportunityLineItem> result = OpportunityLineItemController.getOpportunityLineItems(emptyOpp.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Aucune ligne ne doit être retournée');
    }

    /**
     * Cas : ID d’opportunité inexistant → résultat vide attendu.
     */
    @isTest
    static void testGetOpportunityLineItems_InvalidId() {
        Test.startTest();
        List<OpportunityLineItem> result = OpportunityLineItemController.getOpportunityLineItems('006000000000001AAA');
        Test.stopTest();

        System.assertEquals(0, result.size(), 'ID invalide → aucun résultat attendu');
    }

    /**
     * Vérifie que la méthode delete fonctionne correctement.
     */
    @isTest
    static void testDeleteOpportunityLineItem() {
        TestDataFactory.TestDataWrapper data = TestDataFactory.createFullOpportunity(
            'Produit B', 5, 200, 1, 'Opp Delete', 'Prospecting', 2
        );

        System.assertNotEquals(null, data.oli, 'La ligne de produit doit exister.');

        Test.startTest();
        OpportunityLineItemController.deleteOpportunityLineItem(data.oli.Id);
        Test.stopTest();

        List<OpportunityLineItem> remaining = [SELECT Id FROM OpportunityLineItem WHERE Id = :data.oli.Id];
        System.assertEquals(0, remaining.size(), 'La ligne doit être supprimée.');
    }

    /**
     * Cas : suppression avec un ID null → déclenche AuraHandledException.
     */
    @isTest
    static void testDeleteOpportunityLineItem_NullId() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            OpportunityLineItemController.deleteOpportunityLineItem(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('suppression impossible'), 'Message d’erreur attendu.');
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Une exception était attendue');
    }

    /**
     * Cas : suppression échoue avec un ID inexistant → déclenche le bloc catch.
     */
    @isTest
    static void testDeleteOpportunityLineItem_TriggerCatch_WithFakeId() {
        Boolean exceptionCaught = false;

        Test.startTest();
        try {
            OpportunityLineItemController.deleteOpportunityLineItem('00k000000000001AAA');
        } catch (AuraHandledException e) {
            exceptionCaught = true;
            System.assert(e.getMessage().contains('Erreur suppression'), 'Le message du catch doit apparaître');
        }
        Test.stopTest();

        System.assert(exceptionCaught, 'Le bloc catch doit être déclenché');
    }

    /**
     * Teste la mise à jour de stock avec données valides et invalides.
     */
    @isTest
    static void testUpdateProductStock_ValidAndInvalidData() {
        Product2 p1 = TestDataFactory.createProduct('Produit P1', 5);
        Product2 p2 = TestDataFactory.createProduct('Produit P2', 10);

        List<Map<String, Object>> updates = new List<Map<String, Object>>{
            new Map<String, Object>{'productId' => p1.Id, 'quantityInStock' => 8},
            new Map<String, Object>{'productId' => p2.Id, 'quantityInStock' => 6},
            new Map<String, Object>{'quantityInStock' => 99}, // manquant
            new Map<String, Object>{'productId' => p2.Id, 'quantityInStock' => 'invalide'} // mauvais type
        };

        Test.startTest();
        OpportunityLineItemController.updateProductStock(updates);
        Test.stopTest();

        Product2 updated1 = [SELECT QuantityInStock__c FROM Product2 WHERE Id = :p1.Id];
        Product2 updated2 = [SELECT QuantityInStock__c FROM Product2 WHERE Id = :p2.Id];

        System.assertEquals(8, updated1.QuantityInStock__c);
        System.assertEquals(6, updated2.QuantityInStock__c);
    }

    /**
     * Teste les cas vides et données 100% invalides.
     */
    @isTest
    static void testUpdateProductStock_EmptyAndInvalidOnly() {
        Test.startTest();
        OpportunityLineItemController.updateProductStock(new List<Map<String, Object>>());
        Test.stopTest();

        List<Map<String, Object>> invalidUpdates = new List<Map<String, Object>>{
            new Map<String, Object>{'quantityInStock' => 'non-numérique'},
            new Map<String, Object>{'productId' => null, 'quantityInStock' => null}
        };

        Test.startTest();
        OpportunityLineItemController.updateProductStock(invalidUpdates);
        Test.stopTest();

        System.assert(true, 'Les données invalides ne doivent pas provoquer d’exception');
    }
}