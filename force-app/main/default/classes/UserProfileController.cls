//author: WERMI ADAMA - Mai 2025
// recupere Userprofile Name: "Commercial" ou un "System Administrator".
public with sharing class UserProfileController {
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserProfile() {
        return getCurrentUserProfileInternal(false); // appel normal
    }
     //Méthode interne utilise forceError pour forcer une erreur dans les tests
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

