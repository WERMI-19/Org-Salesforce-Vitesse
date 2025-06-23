trigger OpportunityTrigger on Opportunity (before update) {
    System.debug('DEBUG: OpportunityTrigger - Déclencheur activé.'); // Indique le début du déclencheur
    if (Trigger.isBefore && Trigger.isUpdate) {
        List<Opportunity> closedWonOpps = new List<Opportunity>();

        for (Opportunity newOpp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(newOpp.Id);

            if (newOpp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                closedWonOpps.add(newOpp);
            }
        }

        if (!closedWonOpps.isEmpty()) {
            System.debug('DEBUG: OpportunityTrigger - Appel de OpportunityHandler.processClosedWonOpportunities avec ' + closedWonOpps.size() + ' opportunité(s).'); // Indique le début du traitement clé
            OpportunityHandler.processClosedWonOpportunities(closedWonOpps);
        }
    }
}
