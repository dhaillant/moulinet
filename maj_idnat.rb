#!/usr/bin/env ruby
=begin
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

$Version = "20210831"


=begin
	A FAIRE :
	20150827 - Détecter les changements de noms (pour un même ID NAT, NOM ou PRENOM différent)
	20150827 - Détecter les changements d'ID NAT (pour une même paire NOM / PRENOM, ID NAT différent)
	20150827 - Eliminer les traits d'union des noms et prénoms, remplacer par rien (voir traitement accents ?)
=end


=begin
	Les fichiers traités doivent être au format UTF-8

	Les traiter ainsi :
	XXX iconv -f ISO-8859-1 -t UTF-8 EXP_Liste_des_eleves_par_division.csv > EXP_Liste_des_eleves_par_division.csv.utf8
	iconv -f ISO-8859-1 -t UTF-8 ElevesSansAdresses.xml.csv > ElevesSansAdresses.xml.csv.utf8
=end

$div_exclues = File.read("div_exclues.conf")


$profil_web_eleve = "eleves"


$EnteteKwartz = "#Nom;Prénom;groupe d'affectation;login actuel;nouveau login;mot de passe;droits;groupes invités;groupes responsable;serveur mail externe; login mail externe; mot de passe mail externe; adresse email; identifiant externe; profil windows; profil d'accès à internet"
$EnteteKwartz = "#Nom;Prénom;groupe d'affectation;login actuel;nouveau login;mot de passe;droits;groupes invités;groupes responsable;serveur mail externe; login mail externe; mot de passe mail externe; adresse email; identifiant externe; profil windows; profil d'accès à internet; compte désactivé"

class Eleve < Hash
	def initialize
		self[:nom] = ""
		self[:login] = ""
		self[:nlogin] = ""
		self[:droits] = ""
		self[:invite] = ""
		self[:responsable] = ""
		self[:serveurmailext] = ""
		self[:loginmailext] = ""
		self[:mdpmailext] = ""
		self[:mail] = ""
		self[:idext] = ""
		self[:profilwin] = ""
		self[:profilweb] = $profil_web_eleve
		self[:prenom] = ""
		self[:iprenom] = ""
		self[:date] = ""
		self[:div] = ""
		self[:login] = ""
		self[:divprec] = ""
		self[:doublant] = ""
		self[:invite] = ""
		self[:responsable] = ""
		self[:entree] = ""
		self[:sortie] = ""
		self[:idnat] = ""
		self[:modifie] = ""	# savoir si le compte a été modifié au cours d'un traitement du script
		self[:desactive] = ""	# nouvelle info Kwartz
	end
end

class Liste_eleves < Array


end


def suppr_accents (chaine)
	accents 	= ['à', 'â', 'ç', 'è', 'é', 'ê', 'ë', 'î', 'ô', 'ù', 'û', 'ï', 'À', 'Â', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Î', 'Ô', 'Ù', 'Û', 'Ï']
	sansAccents	= ['a', 'a', 'c', 'e', 'e', 'e', 'e', 'i', 'o', 'u', 'u', 'i', 'A', 'A', 'C', 'E', 'E', 'E', 'E', 'I', 'O', 'U', 'U', 'I']

	i = 0
	accents.length.times do
		chaine = chaine.gsub(accents[i], sansAccents[i])
		i += 1
	end

	return chaine
end

def lire_liste_kwartz(fichier)
	#eleves = []
	eleves = Liste_eleves.new
	
	File.open(fichier).each do |record|
		fields = []

		record.split(";").each do |field|
			field.chomp!
			fields.push field
		end
		if fields[0] != "#Nom"	#ne pas prendre l'entête

#Nom 0;Pr�nom 1;groupe d'affectation 2;login actuel 3;nouveau login 4;mot de passe 5;droits 6;groupes invit�s 7;groupes responsable 8;serveur mail externe 9; login mail externe 10; mot de passe mail externe 11; adresse email 12; identifiant externe 13; profil windows 14; profil d'acc�s � internet 15
			eleve = Eleve.new

			eleve[:nom] = fields[0].gsub(/[\s']/, '')
			eleve[:prenom] = fields[1]
			eleve[:iprenom] = fields[1] #[0].chr,
			eleve[:date] = ""	# la date n'est pas fournie par kwartz
			eleve[:div] = fields[2].upcase #.gsub(/["=]/, ''),
			eleve[:login] = fields[3]
			eleve[:nlogin] = fields[3].scan(/[\d]/)[0]	# numéro ajouté en cas de doublon
			eleve[:divprec] = ""		# non fourni par kwartz
			eleve[:doublant] = ""	# non fourni par kwartz
			eleve[:droits] = fields[6]
			eleve[:invite] = fields[7]
			eleve[:responsable] = fields[8]
			eleve[:serveurmailext] = fields[9]
			eleve[:loginmailext] = fields[10]
			eleve[:mdpmailext] = fields[11]
			eleve[:mail] = fields[12]
			eleve[:idext] = fields[13]
			eleve[:profilwin] = fields[14]
			eleve[:profilweb] = fields[15]
			eleve[:desactive] = fields[16]

			eleve[:nlogin] = 0 if eleve[:nlogin] == nil
			eleve[:iprenom] = eleve[:iprenom][0].chr unless eleve[:iprenom][0] == nil	# supprimer les numéros anti doublons

			eleves.push eleve
		end
	end

	return eleves
end


def lire_liste_sconet(fichier)
	#eleves = []
	eleves = Liste_eleves.new

# déterminer la version du fichier sconet importé en fonction de la première ligne
# puis affecter à chaque champs le numéro de colone correspondant

	col_NOM = 0
	col_PRENOM = 0
	col_DATE = 0
	col_DIV = 0
	col_DIVPREC = 0
	col_DOUBLANT = 0
	# nouveau avec xml2csv :
	col_ENTREE = 0
	col_SORTIE = 0
	col_IDNAT = 0
	col_IDELETAB = 0

	File.open(fichier) do |f|
		premiere = f.readline
		if premiere == "NOM;PRENOM;NE(E) LE;MEF;DIV.;REG.;OPT1;OPT2;OPT3;OPT4;OPT5;OPT6;OPT7;OPT8;OPT9;OPT10;OPT11;OPT12;DIV. PREC.;Doublant" + "\n"
			col_NOM = 0
			col_PRENOM = 1
			col_DATE = 2
			col_DIV = 4
			col_DIVPREC = 18
			col_DOUBLANT = 19

		elsif premiere == "NOM;PRENOM;NE(E) LE;DIV.;REG.;OPT1;OPT2;OPT3;OPT4;OPT5;OPT6;OPT7;OPT8;OPT9;OPT10;OPT11;OPT12;DIV. PREC.;Doublant" + "\n"
			col_NOM = 0
			col_PRENOM = 1
			col_DATE = 2
			col_DIV = 3
			col_DIVPREC = 17
			col_DOUBLANT = 18

		elsif premiere == "NOM;PRENOM;SEXE;NE(E) LE;MEF;DIV.;REG.;OPT1;OPT2;OPT3;OPT4;OPT5;OPT6;OPT7;OPT8;OPT9;OPT10;OPT11;OPT12;DIV. PREC.;Doublant" + "\n"
			col_NOM = 0
			col_PRENOM = 1
			col_DATE = 3
			col_DIV = 5
			col_DIVPREC = 19
			col_DOUBLANT = 20

		elsif premiere == "NOM;PRENOM;NE(E) LE;DIV.;DIV. PREC.;Doublant;date_entree;date_sortie;id_national;id_eleve_etab" + "\n"
# format proposé par xml2csv.rb :
# NOM;PRENOM;NE(E) LE;DIV.;DIV. PREC.;Doublant;date_entree;date_sortie;id_national;id_eleve_etab
			col_NOM = 0
			col_PRENOM = 1
			col_DATE = 2
			col_DIV = 3
			col_DIVPREC = 4
			col_DOUBLANT = 5
			col_ENTREE = 6
			col_SORTIE = 7
			col_IDNAT = 8
			col_IDELETAB = 9

		else
			puts "erreur dans le format de fichier Sconet !"
			break
		end
	end

# ouvrir le fichier sconet en lecture
# parcourir chaque enregistrement (ligne) et pour chacun,
# découper les champs séparés par ";",
# sauvegarder les champs extraits dans un objet eleve et l'ajouter aux autres élèves

	File.open(fichier).each do |record|
		#puts record
		fields = []
		record.split(";").each do |field|
			field.chomp!
			fields.push field
		end

		if fields[0] != "NOM"	#ne pas prendre l'entête
			eleve = Eleve.new



			#eleve[:nom] = fields[col_NOM].gsub(/[-'\s]/, '')	# pas d'espaces ni de ' ni de -
			eleve[:nom] = fields[col_NOM].gsub(/['\s]/, '')		# pas d'espaces ni de '
			eleve[:prenom] = fields[col_PRENOM]
			eleve[:iprenom] = fields[col_PRENOM][0].chr
			eleve[:date] = fields[col_DATE].gsub("/", '')
			eleve[:div] = fields[col_DIV].gsub(/["=]/, '').upcase
			eleve[:login] = ""
			eleve[:nlogin] = 0
			eleve[:divprec] = fields[col_DIVPREC].gsub(/["=]/, '').upcase
			eleve[:doublant] = fields[col_DOUBLANT]

			# nouveau avec xml2csv :
			eleve[:entree] = fields[col_ENTREE]
			eleve[:sortie] = fields[col_SORTIE]
			eleve[:idnat] = fields[col_IDNAT]

			eleve[:nom] = suppr_accents(eleve[:nom])
			eleve[:prenom] = suppr_accents(eleve[:prenom])

			eleves.push eleve
		end
	end

	return eleves
end



def ecrire_fichier_modifies(eleves, fichier)
	puts "Ecriture de #{fichier}..."
	f = File.open(fichier, "w")
	f.puts "#Fichier créé avec moulinet.rb version #{$VersionMoulinet}, le #{Time.now}. Vérifiez l'exactitude du contenu avant d'utiliser ce fichier !"
	f.puts $EnteteKwartz
	# "#Nom;Pr�nom;groupe d'affectation;login actuel;nouveau login;mot de passe;droits;groupes invit�s;groupes responsable;serveur mail externe; login mail externe; mot de passe mail externe; adresse email; identifiant externe; profil windows; profil d'acc�s � internet"

	n = 0
	eleves.each do |e|
		f.puts "#{e[:nom]};#{e[:prenom]};#{e[:div]};#{e[:login]};#{e[:login]};;#{e[:droits]};#{e[:invite]};#{e[:responsable]};#{e[:serveurmailext]};#{e[:loginmailext]};#{e[:mdpmailext]};#{e[:mail]};#{e[:idext]};#{e[:profilwin]};#{e[:profilweb]}"
		n += 1
	end

	return n
end


def ecrire_fichier_info(eleves, fichier)
	puts "Ecriture de #{fichier}..."
	f = File.open(fichier, "w")
	f.puts "#Fichier créé avec moulinet.rb version #{$VersionMoulinet}, le #{Time.now}. Fichier pour information uniquement ! Ne pas importer !"
	f.puts $EnteteKwartz

	n = 0
	eleves.each do |e|
		f.puts "#{e[:nom]};#{e[:prenom]};#{e[:div]};#{e[:login]};#{e[:login]};;#{e[:droits]};#{e[:invite]};#{e[:responsable]};;;;;#{e[:idext]};;#{e[:profilweb]}"
		n += 1
	end

	return n
end


def afficher_eleve(eleve, index=0)
	unless eleve == nil

		texte = "    "
		texte = " %3d" % index if index > 0
		texte += " %-16s | %-16s | %-18s | %-8s | %-9s | %-10s | %-11s | %-11s | %-8s" % [eleve[:nom], eleve[:prenom], eleve[:login], eleve[:div], eleve[:divprec], eleve[:date], eleve[:idext],  eleve[:idnat], eleve[:sortie]]
	end
	puts texte unless texte == nil
end

def afficher_tous(eleves)
	entete = "     %-16s | %-16s | %-18s | %-8s | %-8s | %-10s | %-11s | %-11s | %-8s" % ["NOM", "Prenom", "Login", "Classe", "Classe -1", "Naissance", "ID EXT", "ID NAT", "Sortie"]
	puts entete
	puts "-" * entete.length
	i = 0
	eleves.each do |e|
		i += 1
		afficher_eleve e, i
	end
	puts "-" * entete.length
	puts "Total = " + eleves.length.to_s + "\n\n\n"
end

def afficher_10_premiers(eleves)
	# afficher les 10 premiers élèves
	entete = "     %-16s | %-16s | %-18s | %-8s | %-9s | %-10s | %-11s | %-11s | %-8s" % ["NOM", "Prenom", "Login", "Classe", "Classe -1", "Naissance", "ID EXT", "ID NAT", "Sortie"]
	puts entete
	puts "-" * entete.length
	i = 0
	10.times do
		afficher_eleve eleves[i], i + 1
		i += 1
	end
	puts "(...)"
	puts "-" * entete.length
	puts "Total = " + eleves.length.to_s + "\n\n\n"
end






#trouver les exclus (ceux depuis Kwartz qui font parti des div exclues, ex: profs)
def trouver_exclus(liste_kwartz, div_exclues)
	exclus = []
	liste_kwartz.each do |eleve_kwartz|
		if div_exclues.include? eleve_kwartz[:div]
			# on l'ajoute aux utilisateurs exclus
			exclus.push eleve_kwartz
		end
	end
	return exclus
end





def trouver_modifies(liste_kwartz)
	modifies = []

	liste_kwartz.each do |eleve_kwartz|
		if (eleve_kwartz[:modifie] == true) and (eleve_kwartz[:idext] != "")
			# si l'élève a été marqué "modifié" et a un IDEXT

			# on l'ajoute aux élèves à modifier
			modifies.push eleve_kwartz
		end
	end

	return modifies
end




def trouver_inchanges liste_kwartz
	inchanges = []

	liste_kwartz.each do |eleve_kwartz|
		if (eleve_kwartz[:modifie] != true)
			# si l'élève N'a PAS été marqué "modifié"

			# on l'ajoute aux élèves inchangés
			inchanges.push eleve_kwartz
		end
	end

	return inchanges
end









def compter_eleves_sconet_presents liste_sconet
	presents = 0

	liste_sconet.each do |eleve_sconet|
		if (eleve_sconet[:sortie] == "")
			presents = presents + 1
		end
	end

	return presents
end

def extraire_nouvelles_classes(liste_sconet)
# obtenir les (nouvelles) classes telles que listées par sconet :
# parcourir les élèves sconet, récupérer la classe de chacun, puis éliminer les doublons

	nouvelles_classes = []
	liste_sconet.each do |eleve_sconet|
		nouvelles_classes.push eleve_sconet[:div]
	end

	return nouvelles_classes.uniq
end

def affecter_id_national liste_sconet, liste_kwartz, options
# pour tous les élèves KWARTZ non exclus sans IDEXT ou IDEXT != de IDNAT, chercher tous les homonymes NOM/PRENOM dans liste sconet
# et PROPOSER un choix d'affectation/correspondance
# la liste_kwartz est modifiée avec la nouvelle donnée

#	liste_kwartz_sans_idext = liste_kwartz.select { |k| k[:idext] == "" && (not $div_exclues.include? k[:div]) }

#	puts "Eleves sans IDEXT :"
#	afficher_10_premiers liste_kwartz_sans_idext

	puts "Trouver les élèves homonymes avec IDNAT différent de IDEXT :"

	i = 0
	# parcourir tous les élèves Kwartz
	liste_kwartz.each do |eleve_kwartz|
		# pour chaque élève Kwartz
		i = i + 1
		#puts "\n\n" + i.to_s + " Pour l'élève :"
		#afficher_eleve eleve_kwartz

		# chercher les homonymes NOM/PRENOM
		#homonymes = liste_sconet.select { |eleve_sconet| eleve_sconet[:nom] == eleve_kwartz[:nom] && eleve_sconet[:prenom] == eleve_kwartz[:prenom]}

		if options == "NP" then
			puts "Recherche sur NOM et PRENOM"
			# chercher les homonymes NOM/PRENOM et dont l'IDNAT est DIFFERENT
			homonymes = liste_sconet.select { |eleve_sconet| eleve_sconet[:nom] == eleve_kwartz[:nom] && eleve_sconet[:prenom] == eleve_kwartz[:prenom] && eleve_sconet[:idnat] != eleve_kwartz[:idext]}
		elsif options == "ND" then
			puts "Recherche sur NOM et DIV"
			# chercher les homonymes NOM/DIV et dont l'IDNAT est DIFFERENT
			homonymes = liste_sconet.select { |eleve_sconet| eleve_sconet[:nom] == eleve_kwartz[:nom] && eleve_sconet[:div] == eleve_kwartz[:div] && eleve_sconet[:idnat] != eleve_kwartz[:idext]}
		elsif options == "NDP" then
			puts "Recherche sur NOM et DIV/DIV-1"
			# chercher les homonymes NOM/DIV-1 et dont l'IDNAT est DIFFERENT
			homonymes = liste_sconet.select { |eleve_sconet| eleve_sconet[:nom] == eleve_kwartz[:nom] && eleve_sconet[:divprec] == eleve_kwartz[:div] && eleve_sconet[:idnat] != eleve_kwartz[:idext]}
		else
			puts "Recherche sur NOM"
			# chercher les homonymes NOM et dont l'IDNAT est DIFFERENT
			homonymes = liste_sconet.select { |eleve_sconet| eleve_sconet[:nom] == eleve_kwartz[:nom] && eleve_sconet[:idnat] != eleve_kwartz[:idext]}
		end

#if eleve_kwartz[:nom] == "MAC-INTOSCH"
#	binding.pry
#end

		if homonymes.length > 0
			# il existe au moins une correspondance homonyme

			# si UNE seule correspondance...
			if (homonymes.length == 1) && (homonymes[0][:div] == eleve_kwartz[:div]) && homonymes[0][:prenom] == eleve_kwartz[:prenom]
					afficher_eleve homonymes[0]
					# On affecte directement
					eleve_kwartz[:idext]	= homonymes[0][:idnat]
					# marquer l'élève comme modifié, afin de le faire apparaitre dans la liste des modifiés :
					eleve_kwartz[:modifie] = true
					puts "\n" + i.to_s + " Affectation automatique :"
					afficher_eleve eleve_kwartz
					#print "o"
#				else
#					# possible que plusieurs élèves dans différentes classes n'apparaissent qu'une fois : BUG
#					#print "x"
#					puts "\n"
#					afficher_eleve eleve_kwartz
#				end
			else
				puts "\n\n\n" + i.to_s + " Pour l'élève :"
				afficher_eleve eleve_kwartz
				puts "\nCorrepondances possibles :"
				afficher_tous homonymes
				puts "Faire correspondre ? (1, 2, 3... pour choisir l'élève. 0 ou <entrée> pour ne pas choisir) :"

				reponse = STDIN.gets.chomp

				if reponse.to_i > 0
					eleve_kwartz[:idext]	= homonymes[reponse.to_i - 1][:idnat]
					# marquer l'élève comme modifié, afin de le faire apparaitre dans la liste des modifiés :
					eleve_kwartz[:modifie] = true
				end
			end

		else
			#Pas de correspondance trouvée ou IDNAT identique...
			print "No match - "
			afficher_eleve eleve_kwartz
			#puts "next!"
			#print "."
		end
	end

	puts "\n"
	return liste_kwartz
end

titre = "  Mise à jour de l'IDNAT version " + $Version
puts "\n"
puts "=" * (titre.length + 2)
puts titre
puts "=" * (titre.length + 2)
puts "\n\n"

fichier_kwartz = ARGV[0].to_s
fichier_sconet = ARGV[1].to_s


# option de recherche des homonymes potentiels : NP = Nom + Prenom, N = Nom seul, ND = Nom + Div
options = ARGV[2].to_s
if options != "N" && options != "ND" && options != "NDP" then
	options = "NP"
end
# à améliorer !


if fichier_kwartz.length > 0 and fichier_sconet.length > 0 then
	puts "Fichier KWARTZ : " + fichier_kwartz
	puts "Fichier SCONET : " + fichier_sconet
	puts "\n"

	puts "Liste (d'après KWARTZ) :"
	liste_kwartz = lire_liste_kwartz fichier_kwartz
	afficher_10_premiers liste_kwartz

	puts "Liste (d'après SCONET) :"
	liste_sconet = lire_liste_sconet fichier_sconet
	afficher_10_premiers liste_sconet

	puts "Les classes de l'année : "
	extraire_nouvelles_classes(liste_sconet).each { |classe| print classe + " " }
	puts "\n\n"

	# utilisateurs faisant parties de classes blacklistées :
	puts "Divisions exclues : " + $div_exclues

	puts "\n\nUtilisateurs Kwartz exclus de la moulinette :"
	exclus = trouver_exclus(liste_kwartz, $div_exclues)
	afficher_10_premiers exclus



	# Mettre à jour l'IDNAT si difference de idnat/idext dans liste_kwartz
	liste_kwartz = affecter_id_national liste_sconet, liste_kwartz - exclus, options



	puts "Élèves à modifier :"
	modifies = trouver_modifies liste_kwartz
	afficher_10_premiers modifies


	puts "Élèves inchangés :"
	inchanges = trouver_inchanges liste_kwartz
	afficher_10_premiers inchanges



	
	ecrire_fichier_modifies 	modifies, 	"comptes_a_modifier.txt"
	ecrire_fichier_info	 	inchanges, 	"pour_info_comptes_inchanges.txt"

else
	puts "Usage :"
	puts " maj_idnat.rb export_kwartz export_sconet"
	puts ""
	puts "Les fichiers traités doivent être au format UTF-8"
	puts ""
	puts "Les traiter ainsi :"
	puts "iconv -f ISO-8859-1 -t UTF-8 ElevesSansAdresses.xml.csv > ElevesSansAdresses.xml.csv.utf8"
	puts "iconv -f ISO-8859-1 -t UTF-8 20170901.export.txt > 20170901.export.txt.utf8"
	puts ""

end
