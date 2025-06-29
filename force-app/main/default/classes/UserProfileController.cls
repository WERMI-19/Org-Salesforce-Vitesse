// exposée aux composants LWC pour récupérer dynamiquement
// le nom du profil de l’utilisateur "Commercial" ou un "Administrateur système".
public with sharing class UserProfileController {
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserProfile() {
        return getCurrentUserProfileInternal(false); // appel normal
    }

    // Méthode interne utilisable en test pour simuler une erreur
    public static String getCurrentUserProfileInternal(Boolean forceError) {
        try {
            if (forceError) {
                throw new QueryException('Erreur simulée');
            }
            return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur sur le profil utilisateur : ' + e.getMessage());
        }
    }
}

