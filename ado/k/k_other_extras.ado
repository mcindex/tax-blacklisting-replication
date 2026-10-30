// this text file contains user-added variations of long country names
// the file is converted to k_other_extras.ado and called by kountry.ado after k_other.ado

program k_other_extras
version 8.2

// to the user - if you ever decide to manually delete some entries, make sure you delete lines 
// from k_other_extras.TXT and delete the whole file k_other_extras.ADO
//                    -----                                        -----

* DO NOT DELETE ANYTHING ABOVE THIS LINE !!!! ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

replace NAMES_STD = `"China"' if NAMES_STD == `"china people's republic of"'
replace NAMES_STD = `"Curacao"' if NAMES_STD == `"curaÃ§ao"'
replace NAMES_STD = `"Cote d'Ivoire"' if NAMES_STD == `"cÃ´te d'ivoire"'
replace NAMES_STD = `"Macau"' if NAMES_STD == `"macau china"'
replace NAMES_STD = `"Venezuela"' if NAMES_STD == `"venezuela republica bolivariana de"'
replace NAMES_STD = `"Timor"' if NAMES_STD == `"timorleste dem rep of"'
replace NAMES_STD = `"Serbia"' if NAMES_STD == `"serbia republic of"'
replace NAMES_STD = `"Afghanistan"' if NAMES_STD == `"afghanistan islamic republic of"'
replace NAMES_STD = `"Armenia"' if NAMES_STD == `"armenia republic of"'
replace NAMES_STD = `"Azerbaijan"' if NAMES_STD == `"azerbaijan republic of"'
replace NAMES_STD = `"Bahrain"' if NAMES_STD == `"bahrain kingdom of"'
replace NAMES_STD = `"Hong Kong"' if NAMES_STD == `"china pr: hong kong"'
replace NAMES_STD = `"Macao"' if NAMES_STD == `"china pr: macao"'
replace NAMES_STD = `"Macao"' if NAMES_STD == `"macau china"'
replace NAMES_STD = `"China"' if NAMES_STD == `"china pr: mainland"'
replace NAMES_STD = `"Swaziland"' if NAMES_STD == `"eswatini kingdom of"'
replace NAMES_STD = `"Cape Verde"' if NAMES_STD == `"cabo verde"'
replace NAMES_STD = `"China"' if NAMES_STD == `"china peoples republic of"'
replace NAMES_STD = `"Cote d'Ivoire"' if NAMES_STD == `"cte divoire"'
replace NAMES_STD = `"Curacao"' if NAMES_STD == `"curaao"'
replace NAMES_STD = `"Swaziland"' if NAMES_STD == `"eswatini"'
replace NAMES_STD = `"Macedonia"' if NAMES_STD == `"north macedonia"'
replace NAMES_STD = `"Macedonia"' if NAMES_STD == `"former yugoslav republic of macedonia fyrom"'
replace NAMES_STD = `"Antigua and Barbuda"' if NAMES_STD == `"antigua y barbuda"'
replace NAMES_STD = `"Brunei"' if NAMES_STD == `"bruneidarussalam"'
replace NAMES_STD = `"Czech Republic"' if NAMES_STD == `"czechia"'
replace NAMES_STD = `"Lesotho"' if NAMES_STD == `"kingdom of lesotho"'
replace NAMES_STD = `"Marshall Islands"' if NAMES_STD == `"marshall islands republic of"'
replace NAMES_STD = `"Yemen"' if NAMES_STD == `"yemen republic of"'
replace NAMES_STD = `"Hong Kong"' if NAMES_STD == `"china hong kong sar"'
replace NAMES_STD = `"Macao"' if NAMES_STD == `"china macao sar"'
replace NAMES_STD = `"Democratic Republic of Congo"' if NAMES_STD == `"dem rep of congo"'
replace NAMES_STD = `"Laos"' if NAMES_STD == `"lao people's dem rep"'
replace NAMES_STD = `"North Korea"' if NAMES_STD == `"korea dem people's rep of"'
replace NAMES_STD = `"Taiwan"' if NAMES_STD == `"china taiwan province of"'
replace NAMES_STD = `"Venezuela"' if NAMES_STD == `"venezuela bolivarian rep of"'
replace NAMES_STD = `"Palestine"' if NAMES_STD == `"state of palestine"'
replace NAMES_STD = `"Bonaire"' if NAMES_STD == `"bonaire sint eustatius and saba"'
replace NAMES_STD = `"Lithuania"' if NAMES_STD == `"lithuani"'
replace NAMES_STD = `"Saint Vincent and the Grenadines"' if NAMES_STD == `"saint vinent and grenadines"'
replace NAMES_STD = `"British Virgin"' if NAMES_STD == `"british virgin"'
replace NAMES_STD = `"Czech Republic"' if NAMES_STD == `"czech republic"'
replace NAMES_STD = `"Cayman Islands"' if NAMES_STD == `"caymans islands"'
replace NAMES_STD = `"Hong Kong"' if NAMES_STD == `"hong kong sar"'
replace NAMES_STD = `"Macao"' if NAMES_STD == `"macau sar"'
replace NAMES_STD = `"Netherlands Antilles"' if NAMES_STD == `"nerlands antilles dissolved in 2010"'
replace NAMES_STD = `"Macedonia"' if NAMES_STD == `"republic of northmacedonia"'
replace NAMES_STD = `"Trinidad and Tobago"' if NAMES_STD == `"trinidad andtobago"'
replace NAMES_STD = `"United Kingdom"' if NAMES_STD == `"united kingdom6"'
replace NAMES_STD = `"Democratic Republic of Congo"' if NAMES_STD == `"congo dem rep of"'
replace NAMES_STD = `"Yemen"' if NAMES_STD == `"yemen democratic"'
replace NAMES_STD = `"Curacao"' if NAMES_STD == `"curacao"'
replace NAMES_STD = `"Macau"' if NAMES_STD == `"macau"'
replace NAMES_STD = `"Hong Kong"' if NAMES_STD == `"hong kong china"'
replace NAMES_STD = `"British Virgin Islands"' if NAMES_STD == `"british virgin"'
replace NAMES_STD = `"Curacao"' if NAMES_STD == `"curaçao"'
replace NAMES_STD = `"Cote d'Ivoire"' if NAMES_STD == `"côte d'ivoire"'
replace NAMES_STD = `"Cote d'Ivoire"' if NAMES_STD == `"côte d’ivoire"'
replace NAMES_STD = `"China"' if NAMES_STD == `"china people’s republic of"'

end
exit
