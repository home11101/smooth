class QuickResponsesService {
  static const Map<String, List<String>> quickResponses = {
    'premier_message': [
      "Salut ! J'ai vu ton profil et [compliment personnalisé]. Comment ça va ?",
      "Hey ! Ton [détail du profil] m'a fait sourire. Tu fais quoi de beau aujourd'hui ?",
      "Coucou ! J'adore [élément du profil]. Dis-moi, tu es plutôt [question ouverte] ?",
    ],
    
    'relancer_conversation': [
      "Hey ! Comment s'est passé ton [référence à conversation précédente] ?",
      "Salut ! J'espère que tu passes une bonne semaine. Tu fais quoi de sympa ce weekend ?",
      "Coucou ! Ça fait un moment, j'espère que tout va bien pour toi 😊",
    ],
    
    'proposer_rendez_vous': [
      "Ça te dirait qu'on se rencontre autour d'un café ? Je connais un endroit sympa !",
      "Et si on continuait cette conversation en vrai ? Tu es libre quand cette semaine ?",
      "J'aimerais bien te rencontrer ! Tu préfères un café, un verre ou une balade ?",
    ],
    
    'apres_match': [
      "Super match ! 🎉 Raconte-moi, qu'est-ce qui t'a plu dans mon profil ?",
      "Hello ! Ravi qu'on ait matché 😊 Tu fais quoi de beau aujourd'hui ?",
      "Salut ! Content de ce match ! Alors, team café ou team apéro ? ☕🍷",
    ],
    
    'conversation_morte': [
      "Hey ! J'espère que tu vas bien. Au fait, [nouvelle question/sujet] ?",
      "Salut ! Comment ça va depuis la dernière fois ? Moi j'ai [anecdote courte]",
      "Coucou ! Alors, des nouvelles de [référence conversation] ?",
    ],
  };

  static List<String> getQuickResponses(String category) {
    return quickResponses[category] ?? [];
  }

  static String getRandomResponse(String category) {
    final responses = getQuickResponses(category);
    if (responses.isEmpty) return '';
    return responses[(DateTime.now().millisecondsSinceEpoch % responses.length)];
  }
}
