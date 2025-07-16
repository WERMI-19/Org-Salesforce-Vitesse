@isTest
private class OpportunityHandlerTest {

    // Méthode de configuration pour les données communes
    @TestSetup
    static void setupTestData() {
        // Créer un produit
        Product2 prod = new Product2(
            Name = 'Test Product',
            QuantityInStock__c = 100,
            IsActive = true
        );
        insert prod;

        // Créer une entrée dans le pricebook standard
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Créer un compte
        Account acc = new Account(Name = 'Test Account');
        insert acc;
    }

    /**
     * Test 1: Décrémentation normale du stock (cas standard)
     */
    @isTest
    static void testStockSuffisantClosedWon() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Test Opp - Stock OK',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            Quantity = 5,
            UnitPrice = 100,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1].Id
        );
        insert oli;

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        // Vérification : Le stock doit être décrémenté de 5
        Product2 updatedProd = [SELECT QuantityInStock__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals(95, updatedProd.QuantityInStock__c, 'Le stock devrait diminuer de 5 unités');
    }

    /**
     * Test 2: Blocage si stock insuffisant
     */
    @isTest
    static void testStockInsuffisantClosedWon() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Mettre à jour le stock pour qu'il soit insuffisant
        prod.QuantityInStock__c = 2;
        update prod;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp - Stock KO',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            Quantity = 3, // Quantité > Stock disponible (2)
            UnitPrice = 100,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1].Id
        );
        insert oli;

        Test.startTest();
        opp.StageName = 'Closed Won';
        try {
            update opp;
            System.assert(false, 'Une erreur était attendue (stock insuffisant)');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('souci de quantité'),
                'Le message d’erreur doit mentionner le problème de stock'
            );
        }
        Test.stopTest();

        // Vérifier que le stock n'a pas changé
        Product2 updatedProd = [SELECT QuantityInStock__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals(2, updatedProd.QuantityInStock__c, 'Le stock ne doit pas changer en cas d’erreur');
    }

    /**
     * Test 3: Plusieurs lignes pour le même produit (pour couvrir produitsAmettreAJour.get(p.Id).QuantityInStock__c)
     */
    @isTest
    static void testMultipleLineItemsSameProduct() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Test Opp - Multi-Lignes',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        // Créer DEUX lignes pour le MÊME produit
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = opp.Id,
                Product2Id = prod.Id,
                Quantity = 2,
                UnitPrice = 100,
                PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1].Id
            ),
            new OpportunityLineItem(
                OpportunityId = opp.Id,
                Product2Id = prod.Id,
                Quantity = 3,
                UnitPrice = 100,
                PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1].Id
            )
        };
        insert olis;

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        // Vérification : Le stock doit être décrémenté de 2 + 3 = 5
        Product2 updatedProd = [SELECT QuantityInStock__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals(95, updatedProd.QuantityInStock__c, 'Le stock doit diminuer de 5 unités (2+3)');
    }

    /**
     * Test 4: Opportunité sans lignes (pour couvrir le cas où lineItems est vide)
     */
    @isTest
    static void testOpportunityWithoutLineItems() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Test Opp - Sans Lignes',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp; // Ne doit pas déclencher d'erreur
        Test.stopTest();

        // Aucune vérification nécessaire, le test passe si aucune exception est levée
    }
}
