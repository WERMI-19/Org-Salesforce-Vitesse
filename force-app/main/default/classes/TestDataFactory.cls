@isTest
public class TestDataFactory {

    /**
     * Wrapper regroupant tous les objets nécessaires à un test sur les opportunités.
     */
    public class TestDataWrapper {
        public Product2 product;
        public PricebookEntry pbe;
        public Opportunity opportunity;
        public OpportunityLineItem oli;

        public TestDataWrapper(Product2 product, PricebookEntry pbe, Opportunity opportunity, OpportunityLineItem oli) {
            this.product = product;
            this.pbe = pbe;
            this.opportunity = opportunity;
            this.oli = oli;
        }
    }

    /**
     * Crée un utilisateur de test avec le profil spécifié.
     */
    public static User createUserWithProfile(String profileName) {
        Profile profile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User user = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'fr_FR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'fr',
            ProfileId = profile.Id
        );
        insert user;
        return user;
    }

    /**
     * Crée un produit actif avec un stock spécifié.
     */
    public static Product2 createProduct(String name, Integer stock) {
        Product2 product = new Product2(
            Name = name,
            QuantityInStock__c = stock,
            IsActive = true
        );
        insert product;
        return product;
    }

    /**
     * Crée une entrée de PricebookEntry dans le Pricebook standard.
     * Gère l’activation automatique du Pricebook si nécessaire.
     */
    public static PricebookEntry createPricebookEntry(Product2 product, Decimal unitPrice) {
        // Vérifie que le Pricebook standard existe et est actif
        Pricebook2 standardPB = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];

        if (!standardPB.IsActive) {
            standardPB.IsActive = true;
            update standardPB;
        }

        // Création de l’entrée de prix
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPB.Id,
            Product2Id = product.Id,
            UnitPrice = unitPrice,
            IsActive = true
        );

        insert pbe;
        return pbe;
    }

    /**
     * Crée une opportunité avec un Pricebook donné.
     */
    public static Opportunity createOpportunity(String name, String stage, Integer daysToClose, Id pricebookId) {
        Opportunity opp = new Opportunity(
            Name = name,
            StageName = stage,
            CloseDate = Date.today().addDays(daysToClose),
            Pricebook2Id = pricebookId
        );
        insert opp;
        return opp;
    }

    /**
     * Crée une ligne de produit associée à une opportunité.
     */
    public static OpportunityLineItem createOpportunityLine(Opportunity opp, PricebookEntry pbe, Integer quantity, Decimal unitPrice) {
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = quantity,
            PricebookEntryId = pbe.Id,
            UnitPrice = unitPrice
        );
        insert oli;
        return oli;
    }

    /**
     * Génère toutes les données nécessaires à un test d’opportunité complet.
     */
    public static TestDataWrapper createFullOpportunity(
        String productName,
        Integer stock,
        Decimal unitPrice,
        Integer quantity,
        String oppName,
        String stage,
        Integer daysToClose
    ) {
        Product2 product = createProduct(productName, stock);
        PricebookEntry pbe = createPricebookEntry(product, unitPrice);
        Opportunity opp = createOpportunity(oppName, stage, daysToClose, pbe.Pricebook2Id);
        OpportunityLineItem oli = createOpportunityLine(opp, pbe, quantity, unitPrice);
        return new TestDataWrapper(product, pbe, opp, oli);
    }

    /**
     * Crée une opportunité sans ligne produit – utile pour tester les cas limites.
     */
    public static Opportunity createEmptyOpportunity(String name, String stage, Integer daysToClose) {
        // Création d’un Pricebook spécifique pour cette opportunité vide
        Pricebook2 pb = new Pricebook2(Name = 'PB Empty Test', IsActive = true);
        insert pb;
        return createOpportunity(name, stage, daysToClose, pb.Id);
    }

    /**
     * Variante simplifiée pour générer une opportunité prête à être testée dans un trigger.
     */
    public static TestDataWrapper createOpportunityForTrigger(
        String productName,
        Integer stockInitial,
        Decimal unitPrice,
        Integer qtyCommandee
    ) {
        return createFullOpportunity(
            productName,
            stockInitial,
            unitPrice,
            qtyCommandee,
            'Opp Test Trigger',
            'Prospecting',
            3
        );
    }
}