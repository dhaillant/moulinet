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

require "rexml/document"


$Versionxml2csv = "20100930"

=begin
	Transformer un fichier xml sconet (ElevesSansAdresses.xml) en fichier csv exploitable par moulinet.rb version 2.
=end




def afficher_eleve(eleve)
	affichage = eleve[:nom] + " " + eleve[:prenom] + " " + eleve[:date] unless eleve == nil
	affichage += " " + eleve[:div] unless eleve[:div].nil?
	affichage += " " + eleve[:divprec] unless eleve[:divprec].nil?

	puts affichage
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

def afficher_progression index=0
	STDOUT.sync = true
	print "."
end




def lire_fichier_xml nom_fichier
	fichier_xml = File.new(nom_fichier)
	doc = REXML::Document.new fichier_xml

	eleves = []
	structures = []

	puts "Chargement du fichier xml..."
	eleves_xml = doc.elements.to_a("BEE_ELEVES/DONNEES/ELEVES/ELEVE")

	puts ""
	puts "Lecture des élèves :"
	eleves_xml.each do |eleve_xml|

		eleve = {
			:nom => eleve_xml.elements["NOM"].text,
			:prenom => eleve_xml.elements["PRENOM"].text,
			:date => eleve_xml.elements["DATE_NAISS"].text,
			:doublant => eleve_xml.elements["DOUBLEMENT"].text,
		}
		eleve[:divprec] = eleve_xml.elements["SCOLARITE_AN_DERNIER/CODE_STRUCTURE"].text.gsub(/ /, '') unless eleve_xml.elements["SCOLARITE_AN_DERNIER/CODE_STRUCTURE"].nil?
		eleve[:date_entree] = eleve_xml.elements["DATE_ENTREE"].text unless eleve_xml.elements["DATE_ENTREE"].nil?
		eleve[:date_sortie] = eleve_xml.elements["DATE_SORTIE"].text unless eleve_xml.elements["DATE_SORTIE"].nil?
		eleve[:id_national] = eleve_xml.elements["ID_NATIONAL"].text unless eleve_xml.elements["ID_NATIONAL"].nil?
		eleve[:id_eleve_etab] = eleve_xml.elements["ID_ELEVE_ETAB"].text unless eleve_xml.elements["ID_ELEVE_ETAB"].nil?

		eleve[:eleve_id] = eleve_xml.attribute("ELEVE_ID").to_s

		eleves.push eleve
		afficher_progression
	end

	puts ""
	puts "Lecture des divisions :"

	structures_xml = doc.elements.to_a("BEE_ELEVES/DONNEES/STRUCTURES/STRUCTURES_ELEVE")
	structures_xml.each do |struct_xml|

		structure = {
			:eleve_id => struct_xml.attribute("ELEVE_ID").to_s,
			:div => struct_xml.elements["STRUCTURE/CODE_STRUCTURE"].text.gsub(/ /, '').strip
		}

		structures.push structure
		afficher_progression
	end
	
	puts ""
	puts "Mise en correspondance élèves <=> divisions :"

	eleves.each do |eleve|
		structures.each do |structure|
			if structure[:eleve_id] == eleve[:eleve_id]
				eleve[:div] = structure[:div]
			end
		end
		afficher_progression
	end

	return eleves
end

def ecrire_fichier_csv(nom_fichier, eleves)
	f = File.open(nom_fichier, "w")

	f.puts "NOM;PRENOM;NE(E) LE;DIV.;DIV. PREC.;Doublant;date_entree;date_sortie;id_national;id_eleve_etab"

	n = 0
	eleves.each do |e|
		f.puts "#{e[:nom]};#{e[:prenom]};#{e[:date]};#{e[:div]};#{e[:divprec]};#{e[:doublant]};#{e[:date_entree]};#{e[:date_sortie]};#{e[:id_national]};#{e[:id_eleve_etab]}"
		n += 1
		afficher_progression
	end

	return n
end



puts "xml2csv version " + $Versionxml2csv
puts "\n"

nom_fichier_xml = ARGV[0].to_s
nom_fichier_csv = ARGV[1].to_s

if nom_fichier_xml.length > 0 then
	if nom_fichier_csv.length == 0
		nom_fichier_csv = nom_fichier_xml + ".csv"
	end


	eleves = lire_fichier_xml ARGV[0].to_s
	puts ""
	afficher_10_premiers eleves

	puts ""
	puts "Ecriture du fichier csv :"
	ecrire_fichier_csv nom_fichier_csv, eleves
	puts ""
else
	puts "Usage :"
	puts " xml2csv.rb <fichier.xml> [<fichier.csv>]"
	puts ""
	puts "Si le fichier csv n'est pas indiqué, un fichier <fichier.xml>.csv sera créé"
	puts ""
end

