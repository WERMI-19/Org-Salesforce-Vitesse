// exposée aux composants LWC pour récupérer dynamiquement
// le nom du profil de l’utilisateur "Commercial" ou un "Administrateur système".
public with sharing class UserProfileController {
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserProfile() {
        try {
            return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        } catch (Exception e) {
            // En cas d’erreur d’accès au profil, on retourne une erreur gérée
            throw new AuraHandledException('Erreur sur le profil utilisateur : ' + e.getMessage());
        }
    }
}

