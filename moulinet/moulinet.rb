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

$VersionMoulinet = "20100906"

=begin
	Les fichiers traités doivent être au format UTF-8

	Les traiter ainsi :
	iconv -f ISO-8859-1 -t UTF-8 EXP_Liste_des_eleves_par_division.csv > EXP_Liste_des_eleves_par_division.csv.utf8
=end

$div_exclues = "PROFS INFO SETUP GRETA STAGE TOS"

$ClassesLycee = "1CEC 1COM1 1COM2 1COM3 1EL 1EL1 1PC 1PEL 1PMA 1PMEI 1PMRI 1PSEN 1PTCI 1PROC 1PTU 1RCI 1SEN 1TCI1 1TCI2 1TU 2CEC 2COM1 2COM2 2EL 2ELEC 2MEI 2MPMI 2MSMA 2ROC 2SEID 2SEN 2TCI 2TU 2VAMA 2VAMB 3DP6 TCEC TCOM TEL TEL1 TEL2 TELA TELB TELEC TMEI TSEID TMPMI TMSMA TPC TPEL TPMA TPMEI TPROC TPSEN TPTU TRCI TROC TSEN TTU TVAMA TVAMB"

$EnteteKwartz = "#Nom;Prénom;groupe d'affectation;login actuel;nouveau login;mot de passe;droits;groupes invités;groupes responsable;serveur mail externe; login mail externe; mot de passe mail externe; adresse email; identifiant externe; profil windows; profil d'accès à internet"

def suppr_accents (chaine)
	accents 	= ['à', 'â', 'ç', 'è', 'é', 'ê', 'ë', 'î', 'ô', 'ù', 'û', 'ï', 'À', 'Â', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Î', 'Ô', 'Ù', 'Û', 'Ï']
	sansAccents	= ['a', 'a', 'c', 'e', 'e', 'e', 'e', 'i', 'o', 'u', 'u', 'i', 'a', 'a', 'c', 'e', 'e', 'e', 'e', 'i', 'o', 'u', 'u', 'i']

	i = 0
	accents.length.times do
		chaine = chaine.gsub(accents[i], sansAccents[i])
		i += 1
	end

	return chaine
end

def lire_liste_kwartz(fichier)
	eleves = []
	
	File.open(fichier).each do |record|
		fields = []
		record.split(";").each do |field|
			field.chomp!
			fields.push field
		end
		if fields[0] != "#Nom"	#ne pas prendre l'entête

#Nom 0;Pr�nom 1;groupe d'affectation 2;login actuel 3;nouveau login 4;mot de passe 5;droits 6;groupes invit�s 7;groupes responsable 8;serveur mail externe 9; login mail externe 10; mot de passe mail externe 11; adresse email 12; identifiant externe 13; profil windows 14; profil d'acc�s � internet 15
			eleve = {
				:nom => fields[0].gsub(/[\s']/, ''),
				:prenom => fields[1],
				:iprenom => fields[1], #[0].chr,
				:date => "",	# la date n'est pas fournie par kwartz
				:div => fields[2].upcase, #.gsub(/["=]/, ''),
				:login => fields[3],
				:nlogin => fields[3].scan(/[\d]/)[0],	# numéro ajouté en cas de doublon
				:divprec => "",		# non fourni par kwartz
				:doublant => "",	# non fourni par kwartz
				:droits => fields[6],
				:invite => fields[7],
				:responsable => fields[8],
				:serveurmailext => fields[9],
				:loginmailext => fields[10],
				:mdpmailext => fields[11],
				:mail => fields[12],
				:idext => fields[13],
				:profilwin => fields[14],
				:profilweb => fields[15]
			}

			eleve[:nlogin] = 0 if eleve[:nlogin] == nil
			eleve[:iprenom] = eleve[:iprenom][0].chr unless eleve[:iprenom][0] == nil	# supprimer les numéros anti doublons

			eleves.push eleve
		end
	end

	return eleves
end


def lire_liste_sconet(fichier)
	eleves = []

# déterminer la version du fichier sconet importé en fonction de la première ligne
# puis affecter à chaque champs le numéro de colone correspondant

	col_NOM = 0
	col_PRENOM = 0
	col_DATE = 0
	col_DIV = 0
	col_DIVPREC = 0
	col_DOUBLANT = 0

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
			eleve = {
				:nom => fields[col_NOM].gsub(/[-'\s]/, ''),	# pas d'espaces ni de ' ni de -
				:prenom => fields[col_PRENOM], #.suppr_accents, #.tr($Accents, $SansAccents),
				:iprenom => fields[col_PRENOM][0].chr,
				:date => fields[col_DATE].gsub("/", ''),
				:div => fields[col_DIV].gsub(/["=]/, '').upcase,
#				:div => fields[3].scan(/"="".*"""/).to_s,".+"
				:login => "",
				:nlogin => 0,
				:divprec => fields[col_DIVPREC].gsub(/["=]/, '').upcase,
				:doublant => fields[col_DOUBLANT]
			}

			eleve[:nom] = suppr_accents(eleve[:nom])
			eleve[:prenom] = suppr_accents(eleve[:prenom])

			eleves.push eleve
		end
	end

	return eleves
end

def ecrire_fichier_nouveaux(eleves, fichier)
	f = File.open(fichier, "w")
	f.puts "#Fichier créé avec moulinet.rb version #{$VersionMoulinet}, le #{Time.now}. Vérifiez l'exactitude du contenu avant d'utiliser ce fichier !"
	f.puts $EnteteKwartz # "#Nom;Pr�nom;groupe d'affectation;login actuel;nouveau login;mot de passe;droits;groupes invit�s;groupes responsable;serveur mail externe; login mail externe; mot de passe mail externe; adresse email; identifiant externe; profil windows; profil d'acc�s � internet"

	n = 0
	eleves.each do |e|
		f.puts "#{e[:nom]};#{e[:prenom]};#{e[:div]};#{e[:login]};#{e[:login]};#{e[:date]};;;;;;;;;;"
		n += 1
	end

	return n
end


def ecrire_fichier_modifies(eleves, fichier)
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
	f = File.open(fichier, "w")
	f.puts "#Fichier créé avec moulinet.rb version #{$VersionMoulinet}, le #{Time.now}. Vérifiez l'exactitude du contenu avant d'utiliser ce fichier !"
	f.puts $EnteteKwartz

	n = 0
	eleves.each do |e|
		f.puts "#{e[:nom]};#{e[:prenom]};#{e[:div]};#{e[:login]};#{e[:login]};;;;;;;;;;;"
		n += 1
	end

	return n
end

def ecrire_fichier_info(eleves, fichier)
	f = File.open(fichier, "w")
	f.puts "#Fichier créé avec moulinet.rb version #{$VersionMoulinet}, le #{Time.now}. Fichier pour information uniquement ! Ne pas importer !"
	f.puts $EnteteKwartz

	n = 0
	eleves.each do |e|
		f.puts "#{e[:nom]};#{e[:prenom]};#{e[:div]};#{e[:login]};#{e[:login]};;;;;;;;;;;"
		n += 1
	end

	return n
end

=begin
def ecrire_fichier_exclus(eleves, fichier)
	f = File.open(fichier, "w")
	f.puts "#Fichier créé avec moulinet.rb version #{$VersionMoulinet}, le #{Time.now}. Fichier pour information uniquement ! Ne pas importer !"
	f.puts $EnteteKwartz

	n = 0
	eleves.each do |e|
		f.puts "#{e[:nom]};#{e[:prenom]};#{e[:div]};#{e[:login]};#{e[:login]};;;;;;;;;;;"
		n += 1
	end

	return n
end
=end

def afficher_eleve(eleve)
	puts eleve[:nom] + " " + eleve[:prenom] + " " + eleve[:iprenom] + " " + eleve[:login] + " " + eleve[:div] + " " + eleve[:date] + "\n" unless eleve == nil
end

def afficher_tous(eleves)
	eleves.each do |e|
		afficher_eleve e
	end
end

def afficher_10_premiers(eleves)
	# afficher les 10 premiers élèves
	i = 0
	10.times do
		afficher_eleve eleves[i]
		i += 1
	end

	puts " = " + eleves.length.to_s + "\n\n"
end

#trouver les nouveaux
def trouver_nouveaux(liste_sconet, options = [], liste_kwartz = [])
# anciens est la liste des élèves importées depuis kwartz
# actuels est la liste des élèves d'après sconet
	nouveaux = []

	if options[:sur_div_prec] == true
		liste_sconet.each do |eleve|
			unless $ClassesLycee.include? eleve_sconet[:divprec]
				# si la précédente classe de l'élève n'appartient pas au lycée on dit qu'il est nouveau
				nouveaux.push eleve_sconet
			end
		end
	elsif options[:sur_nom_prenom] == true
		liste_sconet.each do |eleve_sconet|
			trouve = false
			liste_kwartz.each do |eleve_kwartz|
				if (eleve_sconet[:nom] == eleve_kwartz[:nom]) and (eleve_sconet[:prenom] == eleve_kwartz[:prenom])
					trouve = true	# si l'élève correspond, on dit qu'il est trouvé
				end
			end
			if trouve == false	# s'il n'a pas été trouvé, c'est qu'il est nouveau
				nouveaux.push eleve_sconet
			end
		end
	end

	return nouveaux
end


#trouver les disparus
def trouver_disparus(liste_sconet, liste_kwartz)
# anciens est la liste des élèves importées depuis kwartz
# actuels est la liste des élèves d'après sconet
	disparus = []
	liste_kwartz.each do |eleve_kwartz|
		trouve = false	# l'élève est non trouvé par défaut
		liste_sconet.each do |eleve_sconet|
			if (eleve_kwartz[:nom] == eleve_sconet[:nom]) and (eleve_kwartz[:prenom] == eleve_sconet[:prenom])
				# si l'élève correspond, on dit qu'il est trouvé
				trouve = true
			end
		end
		if trouve == false
			# si au final l'élève n'a pas été trouvé, il s'agit donc d'un disparu, qu'on ajoute à la liste
			# si il fait partie d'un groupe dont les membres peuvent être supprimés !
			#puts an[:div]
			if $ClassesLycee.include? eleve_kwartz[:div]
				disparus.push eleve_kwartz
			end
		end
	end

	return disparus
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
			if (eleve_sconet[:nom] == eleve_kwartz[:nom]) and (eleve_sconet[:prenom] == eleve_kwartz[:prenom]) and (eleve_sconet[:div] != eleve_kwartz[:div]) and ($ClassesLycee.include? eleve_kwartz[:div])
				# si l'élève correspond,

				# on récupère les infos intéressantes
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

				# on l'ajoute aux élèves à modifier
				modifies.push eleve_sconet
			end
		end
	end
	return modifies
end

# trouver les inchangés
# inchanges = liste_kwartz - modifies - disparus
def trouver_inchanges(liste_kwartz, modifies, disparus, exclus)
	inchanges = []
	liste_kwartz.each do |eleve_kwartz|
		trouve = false
		modifies.each do |mod|
			if (eleve_kwartz[:nom] == mod[:nom]) and (eleve_kwartz[:prenom] == mod[:prenom]) and (eleve_kwartz[:div] == mod[:divprec])
				# si l'élève correspond,
				trouve = true
			end
		end
		disparus.each do |disp|
			if (eleve_kwartz[:nom] == disp[:nom]) and (eleve_kwartz[:prenom] == disp[:prenom]) and (eleve_kwartz[:div] == disp[:div])
				# si l'élève correspond,
				trouve = true
			end
		end

		exclus.each do |exc|
			if (eleve_kwartz[:nom] == exc[:nom]) and (eleve_kwartz[:prenom] == exc[:prenom]) and (eleve_kwartz[:div] == exc[:div])
				# si l'élève correspond,
				trouve = true
			end
		end

		if not trouve	# si pas trouvé,
			# on l'ajoute aux élèves inchanges
			inchanges.push eleve_kwartz
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
#		login = nouveau[:iprenom].downcase + "." + nouveau[:nom].downcase
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
				puts "  -> doublon trouvé : #{login} (essai ##{i.to_s} !"
			end
		end
	end
end

# affecter les bons logins (depuis kwartz) aux eleves de sconet
def trouver_logins(liste_sconet, liste_kwartz)

end

def compter_doublants(liste_sconet)
	doublants = 0
	liste_sconet.each do |eleve_sconet|
		if (eleve_sconet[:doublant] == "X")
			doublants = doublants + 1
		end
	end
	return doublants

end

puts "MouliNET version " + $VersionMoulinet
puts "\n"

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
	#liste = lire_liste_sconet "EXP_Liste_des_eleves_par_division_nouvelles_divisions.csv"
	#liste_sconet = lire_liste_sconet "EXP_Liste_des_eleves_par_division.csv"
	liste_sconet = lire_liste_sconet fichier_sconet
	afficher_10_premiers liste_sconet

	puts "Utilisateurs exclus :"
	exclus = trouver_exclus(liste_kwartz, $div_exclues)
	afficher_10_premiers exclus

	puts "Élèves à supprimer :"
	disparus = trouver_disparus liste_sconet, liste_kwartz - exclus
	afficher_10_premiers disparus
	
	puts "Élèves à modifier :"
	modifies = trouver_modifies liste_sconet, liste_kwartz - disparus - exclus
	afficher_10_premiers modifies
	
	puts "Élèves à ajouter :"
	nouveaux = trouver_nouveaux liste_sconet, {:sur_nom_prenom => true}, liste_kwartz - disparus - exclus
	nouveaux = creer_logins nouveaux, liste_kwartz - disparus - exclus
	afficher_10_premiers nouveaux
	
	puts "Élèves inchangés :"
	#inchanges = liste_kwartz - modifies - disparus - exclus
	inchanges = trouver_inchanges liste_kwartz, modifies, disparus, exclus
	afficher_10_premiers inchanges

	puts "Élèves doublants :"
	doublants = compter_doublants liste_sconet
	puts doublants.to_s
=begin
	puts "Élèves rescapés :"
	eleves_rescapes = trouver_rescapes eleves_ancienne_liste, nouvelle_liste
	nombre_eleves_rescapes = eleves_rescapes.length
	afficher_10_premiers eleves_rescapes
=end

	puts ""
	puts "Vérifications :"
	puts "  inchangés : #{inchanges.length} +"
	puts "  modifiés  : #{modifies.length} -"
	puts "  supprimés : #{disparus.length} +"
	puts "  nouveaux  : #{nouveaux.length} ="
	puts "-------------------------"
	puts inchanges.length + modifies.length - disparus.length + nouveaux.length
	puts liste_kwartz.length - exclus.length - disparus.length - modifies.length

#vérif supplémentaire, car j'y comprends plus rien :
	ideal = liste_sconet.length
	puts "nombre d'utilisateurs à atteindre : sconet = #{ideal}"
	reel = nouveaux.length + inchanges.length + modifies.length
	puts "nombre d'utilisateurs atteint     : nouveaux + inchanges + modifies = #{reel}"

	ideal = liste_sconet.length + exclus.length
	puts "nombre d'utilisateurs à atteindre : sconet + exclus = #{ideal}"
	reel = exclus.length + nouveaux.length + inchanges.length + modifies.length
	puts "nombre d'utilisateurs atteint     : exclus + nouveaux + inchanges + modifies = #{reel}"

=begin
	puts "nombre d'élèves de l'ancienne liste (#{nombre_eleves_ancienne_liste}) = nombre d'élèves à modifier (#{nombre_eleves_a_modifier}) + nombre d'élèves à supprimer (#{nombre_eleves_disparus}) + nombre d'élèves rescapés (#{nombre_eleves_rescapes})"
	puts nombre_eleves_ancienne_liste.to_s + " = " + (nombre_eleves_a_modifier + nombre_eleves_disparus + nombre_eleves_rescapes).to_s
	puts "OK" if nombre_eleves_ancienne_liste == (nombre_eleves_a_modifier + nombre_eleves_disparus + nombre_eleves_rescapes)
	
	puts "nombre d'élèves de la nouvelle liste (#{nouvelle_liste.length}) = nombre d'élèves à modifier (#{nombre_eleves_a_modifier}) + nombre d'élèves à ajouter (#{nombre_nouveaux_eleves})"
	puts nouvelle_liste.length.to_s + " = " + (nombre_eleves_a_modifier + nombre_nouveaux_eleves).to_s
	puts "OK" if nouvelle_liste.length == (nombre_eleves_a_modifier + nombre_nouveaux_eleves)
	
	#puts "reste à faire : trouver les homonymes (voir trouver_nouveaux)"
	nouveaux_eleves_dedoublones = trouver_et_modifier_doublons nouveaux_eleves, eleves_a_modifier, eleves_rescapes
=end
	
	ecrire_fichier_nouveaux 	nouveaux, 	"comptes_a_ajouter.txt"
	ecrire_fichier_modifies 	modifies, 	"comptes_a_modifier.txt"
	ecrire_fichier_supprimes 	disparus, 	"comptes_a_supprimer.txt"
	ecrire_fichier_info	 	inchanges, 	"pour_info_comptes_inchanges.txt"
	ecrire_fichier_info		exclus, 	"pour_info_comptes_exclus.txt"
else
	puts "Usage :"
	puts " moulinet.rb export_kwartz export_sconet"
end
