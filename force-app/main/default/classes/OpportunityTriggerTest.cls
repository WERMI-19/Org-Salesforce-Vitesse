@isTest
// Vérifie que le trigger met à jour le stock ou bloque 
//l’opportunité selon la disponibilité.

private class OpportunityTriggerTest {

    /**
     * Teste que le trigger détecte correctement un passage à "Closed Won"
     * et que le stock est mis à jour en conséquence.
     */
    @isTest
    static void testTriggerWithStockSuffisant() {
        // Création d’un jeu de données via la factory
        TestDataFactory.TestDataWrapper data = TestDataFactory.createFullOpportunity(
            'Produit Trigger Test',
            10,          // Stock initial
            500,         // Prix unitaire
            4,           // Quantité commandée
            'Opp Trigger OK',
            'Prospecting',
            3
        );

        // Mise à jour de l’opportunité vers "Closed Won"
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :data.opportunity.Id];
        opp.StageName = 'Closed Won';

        Test.startTest();
        update opp; // Ce update déclenche le trigger et donc appelle le handler
        Test.stopTest();

        // Vérifie que le stock a bien été décrémenté
        Product2 updatedProduct = [
            SELECT QuantityInStock__c FROM Product2 WHERE Id = :data.product.Id
        ];
        System.assertEquals(6, updatedProduct.QuantityInStock__c, 'Le stock doit être mis à jour à 6 (10 - 4)');
    }

    /**
     * Teste que le trigger bloque une opportunité en "Closed Won"
     * si le stock est insuffisant.
     */
    @isTest
    static void testTriggerWithStockInsuffisant() {
        // Produit avec stock trop bas pour la quantité commandée
        TestDataFactory.TestDataWrapper data = TestDataFactory.createFullOpportunity(
            'Produit KO Trigger',
            2,          // Stock insuffisant
            700,
            5,          // Quantité commandée
            'Opp Trigger KO',
            'Prospecting',
            3
        );

        // Mise à jour vers "Closed Won"
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :data.opportunity.Id];
        opp.StageName = 'Closed Won';

        Test.startTest();
        try {
            update opp; // Doit échouer car stock insuffisant
            System.assert(false, 'Une exception était attendue à cause du stock insuffisant');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('stock'), 'L’erreur doit mentionner un problème de stock');
        }
        Test.stopTest();
    }
}
