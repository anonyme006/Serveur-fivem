Locales = { fr = { duty_on = 'Vous êtes en service.', duty_off = 'Vous êtes hors service.' } }
function L(k) return Locales.fr[k] or k end
