# moulinet


"moulinet" is a tool for automatic import, creation, modification and suppression of student accounts in a Kwartz server.

---

"moulinet.rb" est un outil pour automatiser l'import (création, modification et suppression) des comptes élèves sur un serveur Kwartz.

Les données élèves proviennent de la base académique (fichier ElevesSansAdresses.xml).
Le fichier XML est converti en fichier CSV grâce à la commande "xml2csv.rb".
Les données des comptes élèves existants doivent être extraites depuis le serveur Kwartz.

"moulinet.rb" tente de repérer :
- les élèves qui ne sont plus inscrits (date de sortie présente, nom/prénom absent de la liste officielle, classe d'affection absente, etc.)
- les élèves qui ont changé d'affectation (correspondances nom/prénom et classe-1) et qu'il faut modifier
- les nouveaux élèves, en tenant compte des homonymes potentiels (ajout incrémental d'un chiffre dans l'identifiant).

L'identifiant national académique (IDNAT) est une donnée pratique pour faciliter l'identification et mise en relation des élèves existants sur le serveur Kwartz par rapport à la liste académique.
IDNAT est stocké dans Kwartz dans le champ IDEXT.

"maj_idnat.rb" permet de retrouver les élèves ayant un IDNAT différent ou absent.
Modifier la base Kwartz puis réexporter après mise à jour des IDNAT permet un traitement plus fiable.


Les scripts utilisent le langage Ruby.




Les fichiers produits sont sous la forme CSV et doivent impérativement être vérifiés avant import dans le serveur Kwartz.
En effet, les résultats sont parfois incomplets et/ou erronés, notamment lorsqu'il y a présence d'homonymes, d'erreurs de typo dans la base officielle, etc.
Principales erreurs : homonymes, élèves non supprimés, IDNAT différent, etc.

Important : le format des logins élèves suit le schéma <initiale du prénom>.<nom>


Les fichiers CSV doivent être au format UTF-8
Les traiter ainsi :
	iconv -f ISO-8859-1 -t UTF-8 ElevesSansAdresses.xml.csv > ElevesSansAdresses.xml.csv.utf8

