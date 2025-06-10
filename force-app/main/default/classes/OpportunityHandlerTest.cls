@isTest
private class OpportunityHandlerTest {

    /**
     * Teste la décrémentation du stock avec stock suffisant
     */
    @isTest
    static void testStockSuffisantClosedWon() {
        // Crée toutes les données de test
        TestDataFactory.TestDataWrapper data = TestDataFactory.createFullOpportunity(
            'Produit Test', 10, 500, 2, 'Opp Stock OK', 'Prospecting', 5
        );

        // Important : mettre à jour l'opportunité pour déclencher le trigger
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :data.opportunity.Id];
        opp.StageName = 'Closed Won';

        Test.startTest();
        update opp; // Cela déclenche le trigger et la méthode du handler
        Test.stopTest();

        // Vérifie que le stock a été mis à jour
        Product2 prod = [SELECT QuantityInStock__c FROM Product2 WHERE Id = :data.product.Id];
        System.assertEquals(8, prod.QuantityInStock__c);
    }

    /**
     * Teste le blocage si stock insuffisant
     */
    @isTest
    static void testStockInsuffisantClosedWon() {
        // Stock initial = 1, mais commande de 3 → doit échouer
        TestDataFactory.TestDataWrapper data = TestDataFactory.createFullOpportunity(
            'Produit KO', 1, 400, 3, 'Opp Stock KO', 'Prospecting', 5
        );

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :data.opportunity.Id];
        opp.StageName = 'Closed Won';

        Test.startTest();
        try {
            update opp;
            System.assert(false, 'Une erreur était attendue pour stock insuffisant');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().toLowerCase().contains('stock'),
                'Le message d’erreur doit mentionner le stock'
            );
        }
        Test.stopTest();
    }
}

