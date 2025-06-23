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
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        System.assert(!profiles.isEmpty(), 'Le profil "' + profileName + '" est introuvable dans cette organisation.');

        User user = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser' + DateTime.now().getTime() + '@example.com', // Rendre l'email unique
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'fr_FR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'fr',
            ProfileId = profiles[0].Id
        );
        insert user;
        return user;
    }

    /**
     * Crée un produit actif avec un stock spécifié.
     * Le nom est rendu unique pour éviter les conflits dans les tests.
     */
    public static Product2 createProduct(String name, Integer stock) {
        Product2 product = new Product2(
            Name = name + System.currentTimeMillis(), // Correction: Rendre le nom du produit unique
            QuantityInStock__c = stock,
            IsActive = true
        );
        insert product;
        return product;
    }

    /**
     * Crée une entrée de PricebookEntry dans le Pricebook standard.
     * Correction: Vérifie si l'entrée existe déjà pour éviter les erreurs de doublon
     * et utilise Test.getStandardPricebookId().
     */
    public static PricebookEntry createPricebookEntry(Product2 product, Decimal unitPrice) {
        // Obtenir l'ID du catalogue de prix standard de manière fiable en contexte de test
        Id standardPricebookId = Test.getStandardPricebookId();

        // Tenter de trouver une PricebookEntry existante pour ce produit et ce Pricebook standard
        List<PricebookEntry> existingPBEs = [
            SELECT Id, Product2Id, Pricebook2Id, UnitPrice, IsActive
            FROM PricebookEntry
            WHERE Product2Id = :product.Id
            AND Pricebook2Id = :standardPricebookId
            LIMIT 1
        ];

        if (!existingPBEs.isEmpty()) {
            // Si une entrée existe déjà, la retourner.
            // On suppose que l'entrée existante est suffisante pour le test.
            return existingPBEs[0];
        }

        // Si aucune entrée n'existe, créer et insérer une nouvelle entrée
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = product.Id,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pbe; // Cette ligne est la ligne 64 mentionnée dans votre erreur précédente

        return pbe;
    }

        // Crée une opportunité avec un Pricebook donné.

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

      // Crée une ligne de produit associée à une opportunité.

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

      //Génère toutes les données nécessaires à un test d’opportunité complet.
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

    //Crée une opportunité sans ligne produit – utile pour tester les cas limites.
    public static Opportunity createEmptyOpportunity(String name, String stage, Integer daysToClose) {
        
        
        // Utiliser le Pricebook standard pour l'opportunité vide
        Id standardPricebookId = Test.getStandardPricebookId(); // Obtenir l'ID du Pricebook standard
        return createOpportunity(name, stage, daysToClose, standardPricebookId);
    }

    //générer une opportunité prête à être testée dans un trigger.
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