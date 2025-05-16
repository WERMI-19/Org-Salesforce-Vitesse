@isTest
private class OpportunityHandlerTest {
    @isTest
    static void testProcessClosedWonOpportunities_ValidStock() {
        // Produit avec stock suffisant
        Product2 product = new Product2(Name = 'Voiture Électrique A', QuantityInStock__c = 10);
        insert product;

        // Récupérer le Pricebook standard
        Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];

        // Lier le produit au Pricebook
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 50000,
            IsActive = true
        );
        insert pbe;

        // Créer une opportunité non fermée
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // Ajouter une ligne d’opportunité
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 5,
            PricebookEntryId = pbe.Id,
            TotalPrice = 250000
        );
        insert oli;

        // Passer l’opportunité à Closed Won
        opp.StageName = 'Closed Won';
        update opp;

        // Afficher la quantité en stock
        System.debug('Stock: ' + product.QuantityInStock__c);

        // Vérifier le stage de l’opportunité
        System.assertEquals('Closed Won', [SELECT StageName FROM Opportunity WHERE Id = :opp.Id].StageName);
    }

    @isTest
    static void testProcessClosedWonOpportunities_InvalidStock() {
        // Produit avec stock insuffisant
        Product2 product = new Product2(Name = 'Voiture Électrique B', QuantityInStock__c = 3);
        insert product;

        // Récupérer le Pricebook standard
        Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];

        // Lier le produit au Pricebook
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 40000,
            IsActive = true
        );
        insert pbe;

        // Créer une opportunité non fermée
        Opportunity opp = new Opportunity(
            Name = 'Test Opp Invalid',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // Ajouter ligne avec quantité excessive
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 5,
            PricebookEntryId = pbe.Id,
            TotalPrice = 200000
        );
        insert oli;

        // Essayer de passer à Closed Won
        try {
            opp.StageName = 'Closed Won';
            update opp;
            System.assert(false, 'Une erreur aurait dû être levée lors de la mise à jour');
        } catch (DmlException e) {
            // Vérifier le message d’erreur
            System.assert(e.getMessage().contains('souci de quantité'), 'Le message d\'erreur attendu n’a pas été trouvé');
        }
    }
}
