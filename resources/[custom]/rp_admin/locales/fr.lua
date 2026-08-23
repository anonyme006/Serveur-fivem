Locales = {
    fr = {
        no_perm = 'Permission administrateur requise.',
        done = 'Action effectuée.',
        invalid = 'Cible ou arguments invalides.',
        banned = 'Joueur banni.',
        unbanned = 'Joueur débanni.',
        kicked = 'Joueur expulsé.',
    }
}
function L(k) return Locales.fr[k] or k end
