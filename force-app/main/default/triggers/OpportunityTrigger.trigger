trigger OpportunityTrigger on Opportunity (after update) {

    // Vérifie que le contexte est bien after update
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Opportunity> closedWonOpps = new List<Opportunity>();

        // Parcours des opportunités modifiées
        for (Opportunity opp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);

            // Vérifie le changement de statut vers "Closed Won"
            if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                closedWonOpps.add(opp);
            }
        }

        // Si au moins une opportunité est concernée, déléguer à la classe handler
        if (!closedWonOpps.isEmpty()) {
            OpportunityHandler.processClosedWonOpportunities(closedWonOpps);
        }
    }
}

