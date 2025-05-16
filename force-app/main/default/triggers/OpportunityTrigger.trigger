// Déclencheur qui s'exécute après la mise à jour d'une opportunité
trigger OpportunityTrigger on Opportunity (after update) {
    // Créer une liste pour stocker les opportunités qui viennent de passer à l'étape "Closed Won"
    List<Opportunity> closedWonOpps = new List<Opportunity>();

    // Parcourir toutes les opportunités mises à jour
    for (Opportunity opp : Trigger.new) {
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
        
        // Vérifier si l'étape de vente a changé et si la nouvelle étape est "Closed Won"
        if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
            closedWonOpps.add(opp); // Ajouter cette opportunité à notre liste
        }
    }

    // Si au moins une opportunité est concernée, lancer le traitement dans la classe handler
    if (!closedWonOpps.isEmpty()) {
        OpportunityHandler.processClosedWonOpportunities(closedWonOpps);
    }
}
