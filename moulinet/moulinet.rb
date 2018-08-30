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

$VersionMoulinet = "20170914"


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

$div_exclues = "PROFS INFO SETUP GRETA STAGES EXAMEN SURVEILLANTS INTERNES AGENTS WEB QUADOR"
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



			eleve[:nom] = fields[col_NOM].gsub(/[-'\s]/, '')	# pas d'espaces ni de ' ni de -
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

def ecrire_fichier_nouveaux(eleves, fichier)
	puts "Ecriture de #{fichier}..."

	f = File.open(fichier, "w")
	f.puts "#Fichier créé avec moulinet.rb version #{$VersionMoulinet}, le #{Time.now}. Vérifiez l'exactitude du contenu avant d'utiliser ce fichier !"
	f.puts $EnteteKwartz
	# "#Nom;Pr�nom;groupe d'affectation;login actuel;nouveau login;mot de passe;droits;groupes invit�s;groupes responsable;serveur mail externe; login mail externe; mot de passe mail externe; adresse email; identifiant externe; profil windows; profil d'acc�s � internet"

	n = 0
	eleves.each do |e|
		f.puts "#{e[:nom]};#{e[:prenom]};#{e[:div]};#{e[:login]};#{e[:login]};#{e[:date]};#{e[:droits]};#{e[:invite]};;;;;;#{e[:idext]};;#{e[:profilweb]}"
		n += 1
	end

	return n
end


def ecrire_fichier_modifies(eleves, fichier)
	puts "Ecriture de #{fichier}..."
	f = File.open(fichier, "w")
	f.puts "#Fichier créé avec moulinet.rb version #{$VersionMoulinet}, le #{Time.now}. Vérifiez l'exactitude du contenu avant d'utiliser ce fichier !"
	f.puts $EnteteKwartz

	n = 0
	eleves.each do |e|
		f.puts "#{e[:nom]};#{e[:prenom]};#{e[:div]};#{e[:login]};#{e[:login]};;#{e[:droits]};#{e[:invite]};#{e[:responsable]};#{e[:serveurmailext]};#{e[:loginmailext]};#{e[:mdpmailext]};#{e[:mail]};#{e[:idext]};#{e[:profilwin]};#{e[:profilweb]}"
		n += 1
	end

	return n
end

def ecrire_fichier_supprimes(eleves, fichier)
	puts "Ecriture de #{fichier}..."
	f = File.open(fichier, "w")
	f.puts "#Fichier créé avec moulinet.rb version #{$VersionMoulinet}, le #{Time.now}. Vérifiez l'exactitude du contenu avant d'utiliser ce fichier !"
	f.puts $EnteteKwartz

	n = 0
	eleves.each do |e|
		f.puts "#{e[:nom]};#{e[:prenom]};#{e[:div]};#{e[:login]};#{e[:login]};;;;;;;;;#{e[:idext]};;#{e[:profilweb]}"
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
		texte += " %-12s %-12s %-14s %-8s %-8s %-9s %-11s %-11s %-8s" % [eleve[:nom], eleve[:prenom], eleve[:login], eleve[:div], eleve[:divprec], eleve[:date], eleve[:idext],  eleve[:idnat], eleve[:sortie]]
	end
	puts texte unless texte == nil
end

def afficher_tous(eleves)
	entete = "     %-12s %-12s %-14s %-8s %-8s %-9s %-11s %-11s %-8s" % ["NOM", "Prenom", "Login", "Classe", "Classe -1", "Naissance", "ID EXT", "ID NAT", "Sortie"]
	puts entete
	puts "-" * entete.length
	i = 0
	eleves.each do |e|
		i += 1
		afficher_eleve e, i
	end
	puts "-" * entete.length
	puts "Total = " + eleves.length.to_s + "\n\n"
end

def afficher_10_premiers(eleves)
	# afficher les 10 premiers élèves
	entete = "     %-12s %-12s %-14s %-8s %-8s %-9s %-11s %-11s %-8s" % ["NOM", "Prenom", "Login", "Classe", "Classe -1", "Naissance", "ID EXT", "ID NAT", "Sortie"]
	puts entete
	puts "-" * entete.length
	i = 0
	10.times do
		afficher_eleve eleves[i], i + 1
		i += 1
	end
	puts "-" * entete.length
	puts "Total = " + eleves.length.to_s + "\n\n"
end

#trouver les nouveaux
#def trouver_nouveaux(liste_sconet, options = [], liste_kwartz = [])
def trouver_nouveaux liste_sconet, liste_kwartz
# anciens est la liste des élèves importées depuis kwartz
# actuels est la liste des élèves d'après sconet
	nouveaux = []


	# nouvelle méthode, par comparaison nom, prenom, idnat, (entree et sortie)
	liste_sconet.each do |eleve_sconet|
		trouve = false
		liste_kwartz.each do |eleve_kwartz|
			if (eleve_sconet[:nom] == eleve_kwartz[:nom]) and (eleve_sconet[:prenom] == eleve_kwartz[:prenom]) and (eleve_sconet[:idnat] == eleve_kwartz[:idext])
				trouve = true	# si l'élève correspond, on dit qu'il est trouvé
			end
		end
		if trouve == false	# s'il n'a pas été trouvé, c'est qu'il est nouveau
			# si il a une classe et qu'il n'est pas sorti, c'est qu'il est vraiment nouveau, hein, bon
			if (eleve_sconet[:div] != "") and (eleve_sconet[:sortie] == "")
				eleve_sconet[:idext] = eleve_sconet[:idnat]

				nouveaux.push eleve_sconet
			end
		end
	end

	return nouveaux
end


#trouver les disparus
def trouver_disparus(liste_sconet, liste_kwartz)
=begin
	les disparus sont les élèves donnés par kwartz, mais introuvable dans la liste sconet.
	attention aux faux positifs (ortographe, id nat différent...)
	proposer une liste différente de la liste des sortants.
=end
	disparus = []

	liste_kwartz.each do |eleve_kwartz|
		trouve = false	# l'élève est non trouvé par défaut

		# s'il s'agit d'un élève, c'est à dire appartenant à une classe non blacklistée : pas prof, pas greta, pas info, etc
		if not $div_exclues.include? eleve_kwartz[:div]
			# ON LE RECHERCHE :
			
			# si l'élève a un idnat/idext
			if eleve_kwartz[:idext] != ""
				# on recherche l'élève kwartz dans les élèves sconet
				eleve_sconet = liste_sconet.find {|e| e[:idnat] == eleve_kwartz[:idext] }
				# s'il est trouvé
				if eleve_sconet !=  nil
					# il n'est pas un disparu ! tant mieux pour lui...
					trouve = true
				end
			else
				# si pas d'idnat/idext on va chercher les homonymes :
				# parcourir tous les élèves sconet
				liste_sconet.each do |eleve_sconet|

					if (eleve_kwartz[:nom] == eleve_sconet[:nom]) and (eleve_kwartz[:prenom] == eleve_sconet[:prenom])
					

						# si l'élève kwartz a au moins un homonyme ('nom' ET 'prénom') dans la liste sconet,
						# on dit qu'il est trouvé, donc non disparu
						# (c'est peut être un autre élève qui a été trouvé, mais dans le doute, on va conserver l'élève)
						trouve = true
					end
				end
			end
		else
			# il s'agit d'un autre utilisateur (classe blacklistée)
			# bien que non trouvé dans sconet, et pour cause, on dit qu'il est trouvé pour ne pas l'éliminer
			trouve = true
		end


		if trouve == false
			# si au final l'élève n'a pas été trouvé, il s'agit donc d'un "disparu",
			# c'est à dire un élève qui ne se trouve plus au lycée mais encore présent dans la liste kwartz

			# il faut l'éliminer !

			disparus.push eleve_kwartz
		end
	end

	return disparus
end




#trouver les sortants
def trouver_sortants(liste_sconet, liste_kwartz)
=begin
	les sortants sont les élèves donnés par sconet et dont les données indiquent qu'ils ne sont pas ou plus dans le lycée :
	2 cas à traiter :
	- date de sortie présente
	- pas de classe affectée

	il faut bien sûr que l'élève soit présent dans la liste kwartz pour le supprimer
=end
	sortants = []
	non_trouves = 0

	# parcourir les élèves de sconet
	liste_sconet.each do |eleve_sconet|
		# si l'élève a une date de sortie OU qu'il n'a pas de div, c'est qu'il a quitté l'établissement !
		if (eleve_sconet[:sortie] != "") or (eleve_sconet[:div] == "")
			# si l'élève a un idnat
			if eleve_sconet[:idnat] != ""
				# si l'élève est dans la liste kwartz, c'est qu'il faut le supprimer de kwartz !
				eleve_kwartz = liste_kwartz.find {|e| e[:idext] == eleve_sconet[:idnat] }
				if eleve_kwartz !=  nil

					eleve_sconet[:login]		= eleve_kwartz[:login]
					eleve_sconet[:nlogin]		= eleve_kwartz[:nlogin]
					eleve_sconet[:droits]		= eleve_kwartz[:droits]
					eleve_sconet[:invite]		= eleve_kwartz[:invite]
					eleve_sconet[:responsable]	= eleve_kwartz[:responsable]
					eleve_sconet[:serveurmailext]	= eleve_kwartz[:serveurmailext]
					eleve_sconet[:loginmailext]	= eleve_kwartz[:loginmailext]
					eleve_sconet[:mdpmailext]	= eleve_kwartz[:mdpmailext]
					eleve_sconet[:mail]		= eleve_kwartz[:mail]
					eleve_sconet[:idext]		= eleve_kwartz[:idext]
					eleve_sconet[:profilwin]	= eleve_kwartz[:profilwin]
					eleve_sconet[:profilweb]	= eleve_kwartz[:profilweb]

					sortants.push eleve_sconet

				else
					# l'élève n'est pas dans la liste Kwartz : on l'ignore, mais on le comptabilise
					non_trouves += 1
				end
			end


		end


	end

	puts "Eleves Sconet sortants non trouvés dans la liste Kwartz (ignorés) : #{non_trouves}"

	return sortants
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


#modifier les restants
def trouver_modifies(liste_sconet, liste_kwartz)
	modifies = []
	liste_sconet.each do |eleve_sconet|
		liste_kwartz.each do |eleve_kwartz|
#			if (eleve_sconet[:nom] == eleve_kwartz[:nom]) and (eleve_sconet[:prenom] == eleve_kwartz[:prenom]) and (eleve_sconet[:div] != eleve_kwartz[:div]) and ($ClassesLycee.include? eleve_kwartz[:div]) and (eleve_sconet[:idnat] == eleve_kwartz[:idext]) and (eleve_kwartz[:idext] != "") and (eleve_sconet[:div] != "")

# trouver les élèves ayant changé de div, en excluant les élèves sans idnat/idext :
#			if (eleve_sconet[:nom] == eleve_kwartz[:nom]) and (eleve_sconet[:prenom] == eleve_kwartz[:prenom]) and (eleve_sconet[:div] != eleve_kwartz[:div]) and (eleve_sconet[:idnat] == eleve_kwartz[:idext]) and (eleve_kwartz[:idext] != "") and (eleve_sconet[:div] != "")


# trouver les élèves ayant changé de div, non sortant, en excluant PAS les élèves sans idnat/idext :
#			if (eleve_sconet[:nom] == eleve_kwartz[:nom]) and (eleve_sconet[:prenom] == eleve_kwartz[:prenom]) and (eleve_sconet[:div] != eleve_kwartz[:div]) and (eleve_sconet[:idnat] == eleve_kwartz[:idext]) and eleve_sconet[:sortie] == ""


# trouver les élèves par IDNAT ayant changé de div, non sortant
#			if (eleve_sconet[:idnat] == eleve_kwartz[:idext]) and (eleve_sconet[:div] != eleve_kwartz[:div]) and (eleve_sconet[:sortie] == "") and (eleve_kwartz[:idext] != "") and (eleve_sconet[:div] != "")
# trouver les élèves par IDNAT ayant changé de div OU marqués "modifiés" (ex. affectation IDEXT), non sortant
			if (eleve_sconet[:idnat] == eleve_kwartz[:idext]) and ((eleve_sconet[:div] != eleve_kwartz[:div]) or (eleve_kwartz[:modifie] == true)) and (eleve_sconet[:sortie] == "") and (eleve_kwartz[:idext] != "") and (eleve_sconet[:div] != "")
				# si l'élève correspond,

				# on récupère les infos intéressantes
				eleve_sconet[:login]			= eleve_kwartz[:login]
				eleve_sconet[:nlogin]			= eleve_kwartz[:nlogin]
				eleve_sconet[:droits]			= eleve_kwartz[:droits]
				eleve_sconet[:invite]			= eleve_kwartz[:invite]
				eleve_sconet[:responsable]		= eleve_kwartz[:responsable]
				eleve_sconet[:serveurmailext]		= eleve_kwartz[:serveurmailext]
				eleve_sconet[:loginmailext]		= eleve_kwartz[:loginmailext]
				eleve_sconet[:mdpmailext]		= eleve_kwartz[:mdpmailext]
				eleve_sconet[:mail]			= eleve_kwartz[:mail]
				eleve_sconet[:idext]			= eleve_kwartz[:idext]
				eleve_sconet[:profilwin]		= eleve_kwartz[:profilwin]
				eleve_sconet[:profilweb]		= eleve_kwartz[:profilweb]
				eleve_sconet[:droits]			= eleve_kwartz[:droits]
				eleve_sconet[:invite]			= eleve_kwartz[:invite]
				eleve_sconet[:responsable]		= eleve_kwartz[:responsable]

				# on l'ajoute aux élèves à modifier
				modifies.push eleve_sconet
			end
		end
	end
	return modifies
end

# trouver les inchangés
# inchanges = liste_kwartz - modifies - sortants


def trouver_inchanges liste_sconet, liste_kwartz
	inchanges = []

	liste_kwartz.each do |eleve_kwartz|
		# attention : ne détecte pas les supprimés !
		eleve = liste_sconet.detect { |eleve_sconet| eleve_sconet[:idnat] == eleve_kwartz[:idext] && eleve_sconet[:div] == eleve_kwartz[:div] && eleve_sconet[:idnat] != "" }
		unless eleve.nil?


			# on récupère les infos intéressantes
			eleve[:login]			= eleve_kwartz[:login]
			eleve[:nlogin]			= eleve_kwartz[:nlogin]
			eleve[:droits]			= eleve_kwartz[:droits]
			eleve[:invite]			= eleve_kwartz[:invite]
			eleve[:responsable]		= eleve_kwartz[:responsable]
			eleve[:serveurmailext]		= eleve_kwartz[:serveurmailext]
			eleve[:loginmailext]		= eleve_kwartz[:loginmailext]
			eleve[:mdpmailext]		= eleve_kwartz[:mdpmailext]
			eleve[:mail]			= eleve_kwartz[:mail]
			eleve[:idext]			= eleve_kwartz[:idext]
			eleve[:profilwin]		= eleve_kwartz[:profilwin]
			#eleve[:profilweb]		= eleve_kwartz[:profilweb]
			eleve[:profilweb]		= $profil_web_eleve
			eleve[:droits]			= eleve_kwartz[:droits]
			eleve[:invite]			= eleve_kwartz[:invite]
			eleve[:responsable]		= eleve_kwartz[:responsable]




			inchanges.push eleve
		end
	end

	return inchanges
end






def trouver_doublons(login, liste_kwartz)
	doublons = []
	liste_kwartz.each do |eleve_kwartz|
		if (login == eleve_kwartz[:login])
			doublons.push eleve_kwartz
		end
	end
	return doublons
end


# créer les logins des nouveaux utilisateurs
def creer_logins(liste_nouveaux, liste_kwartz)
	liste_completee = liste_kwartz
	liste_nouveaux_avec_login = []
	# pour tous les nouveaux, proposer un login
	# voir dans liste complétée si le login existe déjà. si existant, proposer un nouveau login et rester
	liste_nouveaux.each do |nouveau|
		login = suppr_accents(nouveau[:iprenom]).downcase + "." + suppr_accents(nouveau[:nom]).downcase
		login_ok = false
		i = 0
		while login_ok == false
			if trouver_doublons(login, liste_completee).length == 0
				login_ok = true
				nouveau[:login] = login
				nouveau[:nlogin] = i

				liste_completee.push nouveau
				liste_nouveaux_avec_login.push nouveau
			else
				i += 1
				login = nouveau[:iprenom].downcase + i.to_s + "." + nouveau[:nom].downcase
				puts "  -> doublon trouvé : #{login} (essai ##{i.to_s}) pour #{nouveau[:nom]} #{nouveau[:prenom]} !"
			end
		end
	end
end

# affecter les bons logins (depuis kwartz) aux eleves de sconet
def trouver_logins(liste_sconet, liste_kwartz)

end


# compter les élèves non sortants et marqués comme doublants
def compter_doublants(liste_sconet)
	doublants = 0
	liste_sconet.each do |eleve_sconet|
		if (eleve_sconet[:doublant] == "1") and (eleve_sconet[:sortie] == "")
			doublants = doublants + 1
		end
	end
	return doublants
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

def affecter_id_national liste_sconet, liste_kwartz
# pour tous les élèves KWARTZ non exclus sans IDEXT, chercher tous les homonymes NOM/PRENOM dans liste sconet
# et PROPOSER un choix d'affectation/correspondance
# la liste_kwartz est modifiée avec la nouvelle donnée

	liste_kwartz_sans_idext = liste_kwartz.select { |k| k[:idext] == "" && (not $div_exclues.include? k[:div]) }

	puts "Eleves sans IDEXT :"
	afficher_10_premiers liste_kwartz_sans_idext

	liste_kwartz_sans_idext.each do |eleve_kwartz_sans_idext|
		puts "Pour l'élève :"
		afficher_eleve eleve_kwartz_sans_idext
		propositions = liste_sconet.select { |eleve_sconet| eleve_sconet[:nom] == eleve_kwartz_sans_idext[:nom] && eleve_sconet[:prenom] == eleve_kwartz_sans_idext[:prenom]}
		if propositions.length > 0
			puts "\nCorrepondances possibles :"
			afficher_tous propositions

			puts "Faire correspondre ? (1, 2, 3... pour choisir l'élève. 0 ou <entrée> pour ne pas choisir) :"

			reponse = STDIN.gets.chomp

			if reponse.to_i > 0
				eleve_kwartz_sans_idext[:idext]	= propositions[reponse.to_i - 1][:idnat]
				# marqué l'élève comme modifié, afin de le faire apparaitre dans la liste des modifiés :
				eleve_kwartz_sans_idext[:modifie] = true
			end



		else
			puts "Pas de correspondance détectée...\n\n"
		end
	end

	return liste_kwartz
end

titre = "  MouliNET version " + $VersionMoulinet
puts "\n"
puts "=" * (titre.length + 2)
puts titre
puts "=" * (titre.length + 2)
puts "\n\n"

fichier_kwartz = ARGV[0].to_s
fichier_sconet = ARGV[1].to_s

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
	puts "Utilisateurs Kwartz exclus de la moulinette :"
	exclus = trouver_exclus(liste_kwartz, $div_exclues)
	afficher_10_premiers exclus


	# tester si absence de idnat/idext dans liste_kwartz
	if liste_kwartz.any? { |eleve| eleve[:idext] == "" && (not $div_exclues.include? eleve[:div]) }
		puts "Des élèves KWARTZ n'ont pas d'ID National !"

		liste_kwartz = affecter_id_national liste_sconet, liste_kwartz

	else
		puts "Tous les élèves KWARTZ ont un ID National, Ok."
	end



	puts "Élèves à supprimer (sortants) :"
	sortants = trouver_sortants liste_sconet, liste_kwartz
	afficher_10_premiers sortants

	puts "Élèves à supprimer (disparus) :"
	disparus = trouver_disparus liste_sconet, liste_kwartz
	afficher_10_premiers disparus
	
	puts "Élèves à modifier :"
#	modifies = trouver_modifies liste_sconet, liste_kwartz - sortants - exclus
	modifies = trouver_modifies liste_sconet, liste_kwartz
	afficher_10_premiers modifies
	
	puts "Élèves à ajouter :"
#	nouveaux = trouver_nouveaux liste_sconet, {:sur_nom_prenom => true}, liste_kwartz - sortants - exclus
	nouveaux = trouver_nouveaux liste_sconet, liste_kwartz
	nouveaux = creer_logins nouveaux, liste_kwartz - sortants - exclus
	afficher_10_premiers nouveaux
	
	puts "Élèves inchangés :"
	#inchanges = liste_kwartz - modifies - sortants - exclus
#	inchanges = trouver_inchanges liste_kwartz, modifies, sortants, exclus
	inchanges = trouver_inchanges liste_sconet, liste_kwartz
	afficher_10_premiers inchanges

	puts "Élèves doublants :"
	doublants = compter_doublants liste_sconet
	puts doublants.to_s


	puts "\n\n"
	puts "Vérifications :\n\n"

	puts "Nombre d'élèves Kwartz (sans les exclus) : #{liste_kwartz.length - exclus.length}"
	puts "modifiés + inchangés + sortants + disparus == kwartz"
	puts "  modifiés  : #{modifies.length}"
	puts "  + inchangés : #{inchanges.length}"
	puts "  + sortants : #{sortants.length}"
	puts "  + disparus : #{disparus.length}"
	puts "-------------------------"
	puts modifies.length + inchanges.length + sortants.length + disparus.length

	puts "\n\n\n"

	nbre_sconet = compter_eleves_sconet_presents liste_sconet
	puts "Nombre d'élèves à atteindre : sconet = #{nbre_sconet}"
	puts "nouveaux + modifiés + inchangés == sconet"
	puts "  nouveaux  : #{nouveaux.length}"
	puts "  + modifiés  : #{modifies.length}"
	puts "  + inchangés : #{inchanges.length}"
	puts "-------------------------"
	puts nouveaux.length + modifies.length + inchanges.length



	
	ecrire_fichier_nouveaux 	nouveaux, 	"comptes_a_ajouter.txt"
	ecrire_fichier_modifies 	modifies, 	"comptes_a_modifier.txt"
	ecrire_fichier_supprimes 	sortants, 	"comptes_a_supprimer.txt"
	ecrire_fichier_info	 	inchanges, 	"pour_info_comptes_inchanges.txt"
	ecrire_fichier_info		exclus, 	"pour_info_comptes_exclus.txt"
	ecrire_fichier_info	 	disparus, 	"pour_info_comptes_disparus.txt"

else
	puts "Usage :"
	puts " moulinet.rb export_kwartz export_sconet"
	puts ""
	puts "Les fichiers traités doivent être au format UTF-8"
	puts ""
	puts "Les traiter ainsi :"
	puts "iconv -f ISO-8859-1 -t UTF-8 ElevesSansAdresses.xml.csv > ElevesSansAdresses.xml.csv.utf8"
	puts "iconv -f ISO-8859-1 -t UTF-8 20170901.export.txt > 20170901.export.txt.utf8"
	puts ""

end
