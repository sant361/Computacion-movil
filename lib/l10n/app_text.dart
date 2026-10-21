import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Traducciones de interfaz; los títulos del catálogo conservan su nombre.
class AppStrings {
  final Locale locale;
  const AppStrings(this.locale);
  static const delegate = _AppStringsDelegate();
  static AppStrings of(BuildContext context) =>
    Localizations.of<AppStrings>(context, AppStrings) ?? const AppStrings(Locale('es'));

  String text(String value) {
    final code = locale.languageCode;
    if (code == 'es') return value;
    final exact = _translations[value]?[code];
    if (exact != null) return exact;
    if (value.startsWith('Vence ')) {
      return '${code == 'en' ? 'Expires' : 'Expire le'} ${value.substring(6)}';
    }
    if (value.startsWith('Se eliminará "') && value.endsWith('" de tu cuenta.')) {
      final name = value.substring(14, value.length - 15);
      return code == 'en' ? 'Remove "$name" from your account?' : 'Supprimer "$name" de votre compte ?';
    }
    if (value.startsWith('No se pudo iniciar sesión (')) {
      return code == 'en' ? 'Could not sign in. Try again.' : 'Connexion impossible. Réessayez.';
    }
    if (value.startsWith('No se pudo crear la cuenta (')) {
      return code == 'en' ? 'Could not create the account. Try again.' : 'Création du compte impossible. Réessayez.';
    }
    return value;
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();
  @override
  bool isSupported(Locale locale) => ['es', 'en', 'fr'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) => SynchronousFuture(AppStrings(locale));
  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

String tr(BuildContext context, String value) => AppStrings.of(context).text(value);

/// Se suscribe a Localizations incluso cuando el widget padre es constante.
class AppText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  const AppText(this.data, {super.key, this.style, this.textAlign, this.maxLines, this.overflow});
  @override
  Widget build(BuildContext context) => Text(tr(context, data), style: style,
    textAlign: textAlign, maxLines: maxLines, overflow: overflow);
}

const Map<String, Map<String, String>> _translations = {
  "Inicio": {
    "en": "Home",
    "fr": "Accueil"
  },
  "Menú": {
    "en": "Menu",
    "fr": "Menu"
  },
  "Idioma": {
    "en": "Language",
    "fr": "Langue"
  },
  "Selecciona el idioma de la aplicación": {
    "en": "Choose the application language",
    "fr": "Choisissez la langue de l’application"
  },
  "Panel de administrador": {
    "en": "Admin dashboard",
    "fr": "Panneau d’administration"
  },
  "Contenido": {
    "en": "Content",
    "fr": "Contenu"
  },
  "Usuarios y roles": {
    "en": "Users and roles",
    "fr": "Utilisateurs et rôles"
  },
  "Usuarios": {
    "en": "Users",
    "fr": "Utilisateurs"
  },
  "Planes": {
    "en": "Plans",
    "fr": "Abonnements"
  },
  "Promociones": {
    "en": "Promotions",
    "fr": "Promotions"
  },
  "Analítica": {
    "en": "Analytics",
    "fr": "Statistiques"
  },
  "Región y seguridad": {
    "en": "Region and security",
    "fr": "Région et sécurité"
  },
  "Cerrar sesión": {
    "en": "Sign out",
    "fr": "Se déconnecter"
  },
  "No se pudo cerrar sesión. Intenta de nuevo.": {
    "en": "Could not sign out. Try again.",
    "fr": "Déconnexion impossible. Réessayez."
  },
  "No se pudo guardar. Intenta de nuevo.": {
    "en": "Could not save. Try again.",
    "fr": "Enregistrement impossible. Réessayez."
  },
  "Sugerencias": {
    "en": "Suggestions",
    "fr": "Suggestions"
  },
  "Seguir viendo": {
    "en": "Continue watching",
    "fr": "Continuer à regarder"
  },
  "Para ti": {
    "en": "For you",
    "fr": "Pour vous"
  },
  "Comedia": {
    "en": "Comedy",
    "fr": "Comédie"
  },
  "Suspenso": {
    "en": "Thriller",
    "fr": "Suspense"
  },
  "Acción": {
    "en": "Action",
    "fr": "Action"
  },
  "Infantil": {
    "en": "Kids",
    "fr": "Jeunesse"
  },
  "Romance": {
    "en": "Romance",
    "fr": "Romance"
  },
  "Tipo": {
    "en": "Type",
    "fr": "Type"
  },
  "Películas": {
    "en": "Movies",
    "fr": "Films"
  },
  "Series": {
    "en": "Series",
    "fr": "Séries"
  },
  "Serie": {
    "en": "Series",
    "fr": "Série"
  },
  "Documentales": {
    "en": "Documentaries",
    "fr": "Documentaires"
  },
  "Perfiles": {
    "en": "Profiles",
    "fr": "Profils"
  },
  "Control parental": {
    "en": "Parental controls",
    "fr": "Contrôle parental"
  },
  "Búsqueda": {
    "en": "Search",
    "fr": "Recherche"
  },
  "Búsqueda aquí": {
    "en": "Search here",
    "fr": "Rechercher ici"
  },
  "No se encontraron resultados": {
    "en": "No results found",
    "fr": "Aucun résultat"
  },
  "Año · Idioma · Duración (próximamente)": {
    "en": "Year · Language · Duration (coming soon)",
    "fr": "Année · Langue · Durée (bientôt)"
  },
  "Mi suscripción": {
    "en": "My subscription",
    "fr": "Mon abonnement"
  },
  "Mis tokens": {
    "en": "My tokens",
    "fr": "Mes jetons"
  },
  "Notificaciones": {
    "en": "Notifications",
    "fr": "Notifications"
  },
  "Descargas": {
    "en": "Downloads",
    "fr": "Téléchargements"
  },
  "Login": {
    "en": "Sign in",
    "fr": "Connexion"
  },
  "LOGIN": {
    "en": "SIGN IN",
    "fr": "SE CONNECTER"
  },
  "Password": {
    "en": "Password",
    "fr": "Mot de passe"
  },
  "Correo electrónico": {
    "en": "Email address",
    "fr": "Adresse e-mail"
  },
  "Contraseña": {
    "en": "Password",
    "fr": "Mot de passe"
  },
  "¿Olvidaste tu contraseña?": {
    "en": "Forgot your password?",
    "fr": "Mot de passe oublié ?"
  },
  "Recordarme": {
    "en": "Remember me",
    "fr": "Se souvenir de moi"
  },
  "Autocompletar datos": {
    "en": "Autofill details",
    "fr": "Remplir automatiquement"
  },
  "¿No tienes cuenta? Regístrate": {
    "en": "No account? Sign up",
    "fr": "Pas de compte ? Inscrivez-vous"
  },
  "Ingresa tu correo": {
    "en": "Enter your email",
    "fr": "Saisissez votre e-mail"
  },
  "Ingresa un correo válido": {
    "en": "Enter a valid email",
    "fr": "Saisissez un e-mail valide"
  },
  "Ingresa tu contraseña": {
    "en": "Enter your password",
    "fr": "Saisissez votre mot de passe"
  },
  "Debe tener al menos 6 caracteres": {
    "en": "Must have at least 6 characters",
    "fr": "Au moins 6 caractères requis"
  },
  "No existe una cuenta con ese correo.": {
    "en": "No account exists with that email.",
    "fr": "Aucun compte avec cet e-mail."
  },
  "Correo o contraseña incorrectos.": {
    "en": "Incorrect email or password.",
    "fr": "E-mail ou mot de passe incorrect."
  },
  "El correo no tiene un formato válido.": {
    "en": "Invalid email format.",
    "fr": "Format d’e-mail invalide."
  },
  "Esta cuenta fue deshabilitada.": {
    "en": "This account has been disabled.",
    "fr": "Ce compte a été désactivé."
  },
  "Demasiados intentos. Intenta de nuevo más tarde.": {
    "en": "Too many attempts. Try again later.",
    "fr": "Trop de tentatives. Réessayez plus tard."
  },
  "Crear cuenta": {
    "en": "Create account",
    "fr": "Créer un compte"
  },
  "Nombre completo": {
    "en": "Full name",
    "fr": "Nom complet"
  },
  "Ingresa tu nombre": {
    "en": "Enter your name",
    "fr": "Saisissez votre nom"
  },
  "Confirmar contraseña": {
    "en": "Confirm password",
    "fr": "Confirmer le mot de passe"
  },
  "Las contraseñas no coinciden": {
    "en": "Passwords do not match",
    "fr": "Les mots de passe ne correspondent pas"
  },
  "Correo no válido": {
    "en": "Invalid email",
    "fr": "E-mail invalide"
  },
  "Ya existe una cuenta con ese correo.": {
    "en": "An account with this email already exists.",
    "fr": "Un compte avec cet e-mail existe déjà."
  },
  "La contraseña es muy débil.": {
    "en": "The password is too weak.",
    "fr": "Le mot de passe est trop faible."
  },
  "Debes autorizar el tratamiento de tus datos personales": {
    "en": "You must consent to personal data processing",
    "fr": "Vous devez autoriser le traitement de vos données personnelles"
  },
  "Métodos de pago": {
    "en": "Payment methods",
    "fr": "Moyens de paiement"
  },
  "Agregar método": {
    "en": "Add payment method",
    "fr": "Ajouter un moyen de paiement"
  },
  "+ Agregar método": {
    "en": "+ Add payment method",
    "fr": "+ Ajouter un moyen de paiement"
  },
  "Número de tarjeta": {
    "en": "Card number",
    "fr": "Numéro de carte"
  },
  "Debe tener 16 dígitos": {
    "en": "Must have 16 digits",
    "fr": "16 chiffres requis"
  },
  "Formato MM/AA": {
    "en": "Use MM/YY format",
    "fr": "Format MM/AA requis"
  },
  "La tarjeta está vencida": {
    "en": "The card has expired",
    "fr": "La carte a expiré"
  },
  "CVV inválido": {
    "en": "Invalid CVV",
    "fr": "CVV invalide"
  },
  "Nombre del titular": {
    "en": "Cardholder name",
    "fr": "Nom du titulaire"
  },
  "Ingresa el nombre del titular": {
    "en": "Enter the cardholder name",
    "fr": "Saisissez le nom du titulaire"
  },
  "Guardar como principal": {
    "en": "Set as default",
    "fr": "Définir par défaut"
  },
  "Principal": {
    "en": "Default",
    "fr": "Par défaut"
  },
  "Solo se guardan los últimos 4 dígitos. No se realizan cobros reales.": {
    "en": "Only the last 4 digits are saved. No real charges are made.",
    "fr": "Seuls les 4 derniers chiffres sont enregistrés. Aucun débit réel."
  },
  "GUARDAR MÉTODO": {
    "en": "SAVE METHOD",
    "fr": "ENREGISTRER"
  },
  "Método de pago guardado": {
    "en": "Payment method saved",
    "fr": "Moyen de paiement enregistré"
  },
  "No tienes métodos de pago guardados": {
    "en": "No saved payment methods",
    "fr": "Aucun moyen de paiement enregistré"
  },
  "¿Eliminar este método?": {
    "en": "Delete this method?",
    "fr": "Supprimer ce moyen de paiement ?"
  },
  "Eliminar": {
    "en": "Delete",
    "fr": "Supprimer"
  },
  "Cancelar": {
    "en": "Cancel",
    "fr": "Annuler"
  },
  "Facturación": {
    "en": "Billing",
    "fr": "Facturation"
  },
  "Seguridad": {
    "en": "Security",
    "fr": "Sécurité"
  },
  "Dispositivos": {
    "en": "Devices",
    "fr": "Appareils"
  },
  "Estándar": {
    "en": "Standard",
    "fr": "Standard"
  },
  "Renueva el 00/00/0000": {
    "en": "Renews on 00/00/0000",
    "fr": "Renouvellement le 00/00/0000"
  },
  "Renovación automática": {
    "en": "Auto renewal",
    "fr": "Renouvellement automatique"
  },
  "Cambiar plan": {
    "en": "Change plan",
    "fr": "Changer d’abonnement"
  },
  "¿Cancelar tu plan?": {
    "en": "Cancel your plan?",
    "fr": "Résilier votre abonnement ?"
  },
  "Seguirás con acceso hasta el final del periodo ya pagado. Después no se renovará.": {
    "en": "You keep access until the end of the paid period. It will not renew.",
    "fr": "Vous gardez l’accès jusqu’à la fin de la période payée. Il ne sera pas renouvelé."
  },
  "Mantener mi plan": {
    "en": "Keep my plan",
    "fr": "Conserver mon abonnement"
  },
  "Confirmar cancelación": {
    "en": "Confirm cancellation",
    "fr": "Confirmer la résiliation"
  },
  "Tu plan se cancelará al final del periodo": {
    "en": "Your plan will end at the end of the period",
    "fr": "Votre abonnement prendra fin à la fin de la période"
  },
  "Cancelar plan": {
    "en": "Cancel plan",
    "fr": "Résilier l’abonnement"
  },
  "Esta sesión": {
    "en": "This session",
    "fr": "Cette session"
  },
  "Cerrar todas": {
    "en": "Sign out of all",
    "fr": "Tout déconnecter"
  },
  "CERRAR TODAS LAS SESIONES": {
    "en": "SIGN OUT OF ALL SESSIONS",
    "fr": "DÉCONNECTER TOUTES LES SESSIONS"
  },
  "¿Cerrar todas las sesiones?": {
    "en": "Sign out of all sessions?",
    "fr": "Déconnecter toutes les sessions ?"
  },
  "Tendrás que volver a iniciar sesión en todos tus dispositivos, incluido este.": {
    "en": "You will need to sign in again on this device. Remote sessions require a server.",
    "fr": "Vous devrez vous reconnecter sur cet appareil. Les sessions distantes nécessitent un serveur."
  },
  "Sesión cerrada en ese dispositivo": {
    "en": "Session removed from demo list",
    "fr": "Session retirée de la liste de démonstration"
  },
  "REPRODUCIR": {
    "en": "PLAY",
    "fr": "LIRE"
  },
  "En mi lista": {
    "en": "In my list",
    "fr": "Dans ma liste"
  },
  "+ Mi lista": {
    "en": "+ My list",
    "fr": "+ Ma liste"
  },
  "Compartir": {
    "en": "Share",
    "fr": "Partager"
  },
  "Enlace copiado para compartir": {
    "en": "Link copied to share",
    "fr": "Lien copié pour partager"
  },
  "Descargado": {
    "en": "Downloaded",
    "fr": "Téléchargé"
  },
  "Descargar": {
    "en": "Download",
    "fr": "Télécharger"
  },
  "Descarga completa": {
    "en": "Download complete",
    "fr": "Téléchargement terminé"
  },
  "Este episodio está restringido": {
    "en": "This episode is restricted",
    "fr": "Cet épisode est restreint"
  },
  "+ Nuevo": {
    "en": "+ New",
    "fr": "+ Nouveau"
  },
  "Roles y permisos": {
    "en": "Roles and permissions",
    "fr": "Rôles et autorisations"
  },
  "Editar": {
    "en": "Edit",
    "fr": "Modifier"
  },
  "+ Crear rol": {
    "en": "+ Create role",
    "fr": "+ Créer un rôle"
  },
  "Registro de auditoría": {
    "en": "Audit log",
    "fr": "Journal d’audit"
  },
  "Disponibilidad por territorio": {
    "en": "Availability by region",
    "fr": "Disponibilité par région"
  },
  "Dispositivos autorizados": {
    "en": "Authorized devices",
    "fr": "Appareils autorisés"
  },
  "Límite por plan: 4 dispositivos": {
    "en": "Plan limit: 4 devices",
    "fr": "Limite : 4 appareils"
  },
  "Pantalla Dispositivos": {
    "en": "Devices screen",
    "fr": "Écran des appareils"
  },
  "Actividad inusual detectada": {
    "en": "Unusual activity detected",
    "fr": "Activité inhabituelle détectée"
  },
  "3 accesos desde ubicaciones distintas en 1 hora.": {
    "en": "3 logins from different locations in 1 hour.",
    "fr": "3 connexions depuis des lieux différents en 1 heure."
  },
  "Ver alertas de seguridad": {
    "en": "View security alerts",
    "fr": "Voir les alertes de sécurité"
  },
  "Temporadas y episodios": {
    "en": "Seasons and episodes",
    "fr": "Saisons et épisodes"
  },
  "Panel de temporadas": {
    "en": "Seasons panel",
    "fr": "Panneau des saisons"
  },
  "Panel de episodios": {
    "en": "Episodes panel",
    "fr": "Panneau des épisodes"
  },
  "Formulario de carga multimedia": {
    "en": "Media upload form",
    "fr": "Formulaire d’envoi multimédia"
  },
  "Estados: borrador · revisión · programado": {
    "en": "States: draft · review · scheduled",
    "fr": "États : brouillon · révision · programmé"
  },
  "Métricas": {
    "en": "Metrics",
    "fr": "Indicateurs"
  },
  "Reproducciones por semana": {
    "en": "Weekly views",
    "fr": "Vues par semaine"
  },
  "Contenido popular": {
    "en": "Popular content",
    "fr": "Contenu populaire"
  },
  "Ver errores del sistema": {
    "en": "View system errors",
    "fr": "Voir les erreurs système"
  },
  "Límites: dispositivos, calidad y descargas": {
    "en": "Limits: devices, quality and downloads",
    "fr": "Limites : appareils, qualité et téléchargements"
  },
  "Los cambios aplican a nuevas suscripciones": {
    "en": "Changes apply to new subscriptions",
    "fr": "Les changements s’appliquent aux nouveaux abonnements"
  },
  "Configurar código nuevo": {
    "en": "Set up new code",
    "fr": "Configurer un nouveau code"
  },
  "Los códigos vencidos no se pueden aplicar": {
    "en": "Expired codes cannot be applied",
    "fr": "Les codes expirés ne peuvent pas être appliqués"
  },
  "Activo": {
    "en": "Active",
    "fr": "Actif"
  },
  "Inactivo": {
    "en": "Inactive",
    "fr": "Inactif"
  },
  "Publicado": {
    "en": "Published",
    "fr": "Publié"
  },
  "Borrador": {
    "en": "Draft",
    "fr": "Brouillon"
  },
  "En revisión": {
    "en": "In review",
    "fr": "En révision"
  },
  "Administrador": {
    "en": "Administrator",
    "fr": "Administrateur"
  },
  "Editor": {
    "en": "Editor",
    "fr": "Éditeur"
  },
  "Usuario": {
    "en": "User",
    "fr": "Utilisateur"
  },
  "Saldo disponible": {
    "en": "Available balance",
    "fr": "Solde disponible"
  },
  "Historial": {
    "en": "History",
    "fr": "Historique"
  },
  "Ver historial": {
    "en": "View history",
    "fr": "Voir l’historique"
  },
  "Obtener tokens": {
    "en": "Get tokens",
    "fr": "Obtenir des jetons"
  },
  "Elige un juego": {
    "en": "Choose a game",
    "fr": "Choisissez un jeu"
  },
  "Jugar": {
    "en": "Play",
    "fr": "Jouer"
  },
  "Disponible en todos los dispositivos": {
    "en": "Available on all devices",
    "fr": "Disponible sur tous les appareils"
  },
  "Capítulo restringido": {
    "en": "Restricted episode",
    "fr": "Épisode restreint"
  },
  "Elige cómo quieres continuar": {
    "en": "Choose how to continue",
    "fr": "Choisissez comment continuer"
  },
  "Desbloquear con tokens": {
    "en": "Unlock with tokens",
    "fr": "Débloquer avec des jetons"
  },
  "Ver anuncio o jugar": {
    "en": "Watch an ad or play",
    "fr": "Regarder une publicité ou jouer"
  },
  "Contratar un plan": {
    "en": "Subscribe to a plan",
    "fr": "Souscrire un abonnement"
  },
  "Acceso ilimitado": {
    "en": "Unlimited access",
    "fr": "Accès illimité"
  },
  "¡Buen trabajo!": {
    "en": "Good job!",
    "fr": "Bravo !"
  },
  "JUGAR OTRA VEZ": {
    "en": "PLAY AGAIN",
    "fr": "REJOUER"
  },
  "Desbloquear capítulo": {
    "en": "Unlock episode",
    "fr": "Débloquer l’épisode"
  },
  "Capítulo desbloqueado": {
    "en": "Episode unlocked",
    "fr": "Épisode débloqué"
  },
  "DESBLOQUEAR": {
    "en": "UNLOCK",
    "fr": "DÉBLOQUER"
  },
  "Ver anuncio": {
    "en": "Watch an ad",
    "fr": "Regarder une publicité"
  },
  "Recuperar contraseña": {
    "en": "Reset password",
    "fr": "Réinitialiser le mot de passe"
  },
  "Enviar enlace": {
    "en": "Send link",
    "fr": "Envoyer le lien"
  },
  "Volver": {
    "en": "Back",
    "fr": "Retour"
  },
  "Pago aprobado": {
    "en": "Payment approved",
    "fr": "Paiement approuvé"
  },
  "Pago rechazado": {
    "en": "Payment declined",
    "fr": "Paiement refusé"
  },
  "Ir al inicio": {
    "en": "Go home",
    "fr": "Aller à l’accueil"
  },
  "Reintentar": {
    "en": "Try again",
    "fr": "Réessayer"
  },
  "Cambiar método": {
    "en": "Change method",
    "fr": "Changer de moyen"
  },
  "Ver factura": {
    "en": "View invoice",
    "fr": "Voir la facture"
  },
  "Pagar": {
    "en": "Pay",
    "fr": "Payer"
  },
  "Cambiar": {
    "en": "Change",
    "fr": "Changer"
  },
  "Confirmar cambio": {
    "en": "Confirm change",
    "fr": "Confirmer le changement"
  },
  "Descargar PDF": {
    "en": "Download PDF",
    "fr": "Télécharger le PDF"
  },
  "Solicitar factura": {
    "en": "Request invoice",
    "fr": "Demander une facture"
  },
  "+50 tokens acreditados": {
    "en": "+50 tokens credited",
    "fr": "+50 jetons crédités"
  },
  "00/00/0000 · Pagada": {
    "en": "00/00/0000 · Paid",
    "fr": "00/00/0000 · Payée"
  },
  "120 tokens": {
    "en": "120 tokens",
    "fr": "120 jetons"
  },
  "1200 vistas": {
    "en": "1200 views",
    "fr": "1200 vues"
  },
  "2400 vistas": {
    "en": "2400 views",
    "fr": "2400 vues"
  },
  "Aplicar": {
    "en": "Apply",
    "fr": "Appliquer"
  },
  "App autenticadora": {
    "en": "Authenticator app",
    "fr": "Application d’authentification"
  },
  "Autoplay": {
    "en": "Autoplay",
    "fr": "Lecture automatique"
  },
  "Autorizo el tratamiento de mis datos personales": {
    "en": "I consent to personal data processing",
    "fr": "J’autorise le traitement de mes données personnelles"
  },
  "Bloquear compras": {
    "en": "Block purchases",
    "fr": "Bloquer les achats"
  },
  "Buscar usuario": {
    "en": "Find user",
    "fr": "Rechercher un utilisateur"
  },
  "Cada perfil guarda su propio historial": {
    "en": "Each profile keeps its own history",
    "fr": "Chaque profil conserve son historique"
  },
  "Cambiar contraseña": {
    "en": "Change password",
    "fr": "Changer le mot de passe"
  },
  "Clasificación máxima": {
    "en": "Maximum age rating",
    "fr": "Classification maximale"
  },
  "Control parental actualizado": {
    "en": "Parental controls updated",
    "fr": "Contrôle parental mis à jour"
  },
  "Código aplicado (demo)": {
    "en": "Code applied (demo)",
    "fr": "Code appliqué (démo)"
  },
  "Código promocional": {
    "en": "Promo code",
    "fr": "Code promotionnel"
  },
  "Código reenviado": {
    "en": "Code resent",
    "fr": "Code renvoyé"
  },
  "Descargando factura en PDF...": {
    "en": "Downloading PDF invoice...",
    "fr": "Téléchargement de la facture PDF..."
  },
  "Doble autenticación": {
    "en": "Two-factor authentication",
    "fr": "Authentification à deux facteurs"
  },
  "ENVIAR ENLACE": {
    "en": "SEND LINK",
    "fr": "ENVOYER LE LIEN"
  },
  "Editar perfiles": {
    "en": "Edit profiles",
    "fr": "Modifier les profils"
  },
  "El código expira en 04:59": {
    "en": "The code expires in 04:59",
    "fr": "Le code expire dans 04:59"
  },
  "Episodios": {
    "en": "Episodes",
    "fr": "Épisodes"
  },
  "GUARDAR CAMBIOS": {
    "en": "SAVE CHANGES",
    "fr": "ENREGISTRER LES MODIFICATIONS"
  },
  "Ganar tokens": {
    "en": "Earn tokens",
    "fr": "Gagner des jetons"
  },
  "Ganar tokens con juegos": {
    "en": "Earn tokens with games",
    "fr": "Gagner des jetons en jouant"
  },
  "Historial reciente": {
    "en": "Recent history",
    "fr": "Historique récent"
  },
  "Lista": {
    "en": "List",
    "fr": "Liste"
  },
  "Límite de dispositivos y tiempo de disponibilidad según tu plan.": {
    "en": "Device limit and availability depend on your plan.",
    "fr": "La limite d’appareils et la disponibilité dépendent de votre abonnement."
  },
  "Límite diario: 4 anuncios": {
    "en": "Daily limit: 4 ads",
    "fr": "Limite quotidienne : 4 publicités"
  },
  "MM/AA": {
    "en": "MM/YY",
    "fr": "MM/AA"
  },
  "Método": {
    "en": "Method",
    "fr": "Moyen"
  },
  "Método de pago": {
    "en": "Payment method",
    "fr": "Moyen de paiement"
  },
  "No tienes suficientes tokens para este capítulo.": {
    "en": "You do not have enough tokens for this episode.",
    "fr": "Vous n’avez pas assez de jetons pour cet épisode."
  },
  "PAGAR": {
    "en": "PAY",
    "fr": "PAYER"
  },
  "PIN de control parental": {
    "en": "Parental control PIN",
    "fr": "Code PIN parental"
  },
  "Pago": {
    "en": "Payment",
    "fr": "Paiement"
  },
  "Plan Estándar": {
    "en": "Standard plan",
    "fr": "Abonnement Standard"
  },
  "Preferencias": {
    "en": "Preferences",
    "fr": "Préférences"
  },
  "REGISTRARME": {
    "en": "SIGN UP",
    "fr": "S’INSCRIRE"
  },
  "Recibe 50 tokens al completar la reproducción del anuncio.": {
    "en": "Get 50 tokens after watching the full ad.",
    "fr": "Recevez 50 jetons après avoir regardé toute la publicité."
  },
  "Recomendamos activar 2FA": {
    "en": "We recommend enabling 2FA",
    "fr": "Nous recommandons d’activer la double authentification"
  },
  "Recuperar cuenta": {
    "en": "Recover account",
    "fr": "Récupérer le compte"
  },
  "Renovación automática. Cancela cuando quieras.": {
    "en": "Automatic renewal. Cancel anytime.",
    "fr": "Renouvellement automatique. Résiliez à tout moment."
  },
  "Renovación mensual": {
    "en": "Monthly renewal",
    "fr": "Renouvellement mensuel"
  },
  "Reproduciendo siguiente episodio (demo)": {
    "en": "Playing next episode (demo)",
    "fr": "Lecture du prochain épisode (démo)"
  },
  "Restringir por perfil": {
    "en": "Restrict by profile",
    "fr": "Restreindre par profil"
  },
  "SMS al número guardado": {
    "en": "SMS to saved number",
    "fr": "SMS au numéro enregistré"
  },
  "SUSCRIBIRME": {
    "en": "SUBSCRIBE",
    "fr": "S’ABONNER"
  },
  "Siguiente episodio ▶": {
    "en": "Next episode ▶",
    "fr": "Épisode suivant ▶"
  },
  "Total": {
    "en": "Total",
    "fr": "Total"
  },
  "VER ANUNCIO": {
    "en": "WATCH AD",
    "fr": "REGARDER LA PUBLICITÉ"
  },
  "VERIFICAR": {
    "en": "VERIFY",
    "fr": "VÉRIFIER"
  },
  "Ver anuncio y ganar tokens": {
    "en": "Watch an ad and earn tokens",
    "fr": "Regarder une publicité et gagner des jetons"
  },
  "Ver desde inicio": {
    "en": "Watch from beginning",
    "fr": "Lire depuis le début"
  },
  "Verifica tu correo": {
    "en": "Verify your email",
    "fr": "Vérifiez votre e-mail"
  },
  "Verificación adicional al iniciar sesión": {
    "en": "Additional verification when signing in",
    "fr": "Vérification supplémentaire à la connexion"
  },
  "o": {
    "en": "or",
    "fr": "ou"
  },
  "¿No llegó el código? Reenviar código": {
    "en": "No code? Resend code",
    "fr": "Pas de code ? Renvoyer le code"
  },
  "¿Quién ve ahora?": {
    "en": "Who is watching?",
    "fr": "Qui regarde ?"
  },
  "Abriendo alertas de seguridad (demo)": {
    "en": "Opening security alerts (demo)",
    "fr": "Ouverture des alertes de sécurité (démo)"
  },
  "Abriendo dispositivos autorizados (demo)": {
    "en": "Opening authorized devices (demo)",
    "fr": "Ouverture des appareils autorisés (démo)"
  },
  "Abriendo formulario de carga (demo)": {
    "en": "Opening upload form (demo)",
    "fr": "Ouverture du formulaire d’envoi (démo)"
  },
  "Abriendo panel de episodios (demo)": {
    "en": "Opening episodes panel (demo)",
    "fr": "Ouverture du panneau des épisodes (démo)"
  },
  "Abriendo panel de temporadas (demo)": {
    "en": "Opening seasons panel (demo)",
    "fr": "Ouverture du panneau des saisons (démo)"
  },
  "Abriendo registro de auditoría (demo)": {
    "en": "Opening audit log (demo)",
    "fr": "Ouverture du journal d’audit (démo)"
  },
  "Abriendo registro de errores (demo)": {
    "en": "Opening error log (demo)",
    "fr": "Ouverture du journal des erreurs (démo)"
  },
  "Contenido eliminado (demo)": {
    "en": "Content deleted (demo)",
    "fr": "Contenu supprimé (démo)"
  },
  "Editar contenido (demo)": {
    "en": "Edit content (demo)",
    "fr": "Modifier le contenu (démo)"
  },
  "Editar permisos del rol (demo)": {
    "en": "Edit role permissions (demo)",
    "fr": "Modifier les autorisations du rôle (démo)"
  },
  "Editar plan (demo)": {
    "en": "Edit plan (demo)",
    "fr": "Modifier l’abonnement (démo)"
  },
  "Formulario de código nuevo (demo)": {
    "en": "New code form (demo)",
    "fr": "Formulaire de nouveau code (démo)"
  },
  "Formulario de nueva promoción (demo)": {
    "en": "New promotion form (demo)",
    "fr": "Formulaire de nouvelle promotion (démo)"
  },
  "Formulario de nuevo plan (demo)": {
    "en": "New plan form (demo)",
    "fr": "Formulaire de nouvel abonnement (démo)"
  },
  "Formulario de nuevo rol (demo)": {
    "en": "New role form (demo)",
    "fr": "Formulaire de nouveau rôle (démo)"
  },
  "Plan eliminado (demo)": {
    "en": "Plan deleted (demo)",
    "fr": "Abonnement supprimé (démo)"
  },
  "Sinopsis: descripción del contenido, lista para reemplazar con los datos reales del catálogo (reparto, director, temporadas, episodios).": {
    "en": "Synopsis: demo description, ready to be replaced with catalog data (cast, director, seasons, episodes).",
    "fr": "Synopsis : description de démonstration à remplacer par les données du catalogue (distribution, réalisateur, saisons, épisodes)."
  },
  "Todavía no has descargado nada.\nBusca un contenido y toca \"Descargar\".": {
    "en": "No downloads yet.\nFind a title and tap \"Download\".",
    "fr": "Aucun téléchargement.\nChoisissez un titre et appuyez sur « Télécharger »."
  },
  "Se cerrará la sesión de este dispositivo. Las otras sesiones son de demostración.": {
    "en": "This device will be signed out. Other sessions are demo entries.",
    "fr": "Cet appareil sera déconnecté. Les autres sessions sont des exemples."
  }
};
