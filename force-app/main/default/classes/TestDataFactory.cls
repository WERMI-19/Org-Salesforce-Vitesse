@isTest
// Fournit des méthodes utilitaires pour générer des données 
//de test complètes et réutilisables.

public class TestDataFactory {

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

    public static User createUserWithProfile(String profileName) {
        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name = :profileName LIMIT 1];
        System.assert(!profiles.isEmpty(), 'Le profil "' + profileName + '" est introuvable.');

        User user = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser' + DateTime.now().getTime() + '@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profiles[0].Id
        );
        insert user;
        return user;
    }

    public static Product2 createProduct(String name, Integer stock) {
        Product2 product = new Product2(
            Name = name + System.currentTimeMillis(),
            QuantityInStock__c = stock,
            IsActive = true
        );
        insert product;
        return product;
    }

    public static PricebookEntry createPricebookEntry(Product2 product, Decimal unitPrice) {
        Id standardPricebookId = Test.getStandardPricebookId();

        List<PricebookEntry> existingPBEs = [
            SELECT Id, Product2Id, Pricebook2Id, UnitPrice, IsActive
            FROM PricebookEntry
            WHERE Product2Id = :product.Id
            AND Pricebook2Id = :standardPricebookId
            LIMIT 1
        ];

        if (!existingPBEs.isEmpty()) {
            return existingPBEs[0];
        }

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = product.Id,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

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

    public static List<OpportunityLineItem> createMultipleOpportunityLines(Opportunity opp, Integer numberOfLines) {
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        for (Integer i = 0; i < numberOfLines; i++) {
            Product2 prod = createProduct('Product Multi-' + System.currentTimeMillis() + i, 100);
            PricebookEntry pbe = createPricebookEntry(prod, 10 + i);
            olis.add(new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 1,
                PricebookEntryId = pbe.Id,
                UnitPrice = 10 + i
            ));
        }
        insert olis;
        return olis;
    }

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

    public static Opportunity createEmptyOpportunity(String name, String stage, Integer daysToClose) {
        Id standardPricebookId = Test.getStandardPricebookId();
        return createOpportunity(name, stage, daysToClose, standardPricebookId);
    }

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