// DML, Teste les opérations sur les lignes d’opportunité

public with sharing class OpportunityLineItemController {
  // Récupère les lignes de produit associées à une opp

    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOpportunityLineItems(Id opportunityId) {
        return [
            SELECT Id, Quantity, UnitPrice, TotalPrice,
                   Product2.Id, Product2.Name, Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId // Filtre par ID d'opportunité
        ];
    }

     // Supprime une ligne de produit de l'opportunité.
    
    @AuraEnabled
    public static void deleteOpportunityLineItem(Id lineItemId) {
        delete new OpportunityLineItem(Id = lineItemId);
    }
    
    // MAJ stock +ieurs produits à partir d’une liste de maps. Ignore les entrées invalides
    @AuraEnabled
    public static void updateProductStock(List<Map<String, Object>> updates) {
        List<Product2> produitsAMettreAJour = new List<Product2>();

        // Rien à faire si la liste est vide ou nulle
        if (updates == null || updates.isEmpty()) {
            return;
        }

        for (Map<String, Object> ligne : updates) {
            try {
                // vérifie que les clés nécessaires sont présentes
                if (ligne == null || !ligne.containsKey('productId') || !ligne.containsKey('quantityInStock')) {
                    continue;
                }

                // Conversion de la quantité vers Decimal 
                Id productId = (Id) ligne.get('productId');
                Decimal quantity = Decimal.valueOf(String.valueOf(ligne.get('quantityInStock')));

                produitsAMettreAJour.add(new Product2(Id = productId, QuantityInStock__c = quantity));
            } catch (Exception e) {
                // ignorer les lignes incorrectes sans planter toute l'opération
                continue;
            }
        }

        // MAJ en masse si  produits valides 
        if (!produitsAMettreAJour.isEmpty()) {
            update produitsAMettreAJour;
        }
    }
}
