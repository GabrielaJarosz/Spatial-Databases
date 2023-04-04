#Data utworzenia skryptu: 09.12.2021r.

#Skrypt zawiera działania na plikach csv takie jak np. eksportowanie,
#łączy się z bazą danych i wykonuje w niej zapytania,
#wysyła raport za pomocą maila 

$TIMESTAMP = ((Get-Date).toString("MM/dd/yyyy"))
$sciezka = 'D:\studia\BazyDanychPrzestrzennych\cw8'

New-Item -Path "$sciezka\PROCESSED" -ItemType Directory
"             === BAZY DANYCH ===          `n`n " > "$sciezka\PROCESSED\skrypt_403548_${TIMESTAMP}.log"
$log = "D:\studia\BazyDanychPrzestrzennych\cw8\PROCESSED\skrypt_403548_${TIMESTAMP}.log"


#=====================Pobieranie pliku z internetu===========================

$adres_url = „https://home.agh.edu.pl/~wsarlej/Customers_Nov2021.zip”
$zapisz_jako = „D:\studia\BazyDanychPrzestrzennych\cw8\Customers_Nov2021.zip”

$wc=New-Object system.net.webclient
$wc.UseDefaultCredentials = $true
$wc.downloadfile($adres_url,$zapisz_jako)
If ($?)
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Dane zostały pobrane!"
}
else
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Dane nie zostały pobrane - błąd!"
}


#=====================Rozpakowanie pliku .zip ================================

$shell = New-Object -ComObject shell.application
$zip = $shell.NameSpace("D:\studia\BazyDanychPrzestrzennych\cw8\Customers_Nov2021.zip")
foreach ($item in $zip.items()) {
  $shell.Namespace("D:\studia\BazyDanychPrzestrzennych\cw8").CopyHere($item)
}
If ($?)
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Dane zostały rozpakowane!"
}
else
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Dane nie zostały rozpakowane - błąd!"
}


#====================Sprawdzanie poprawności pliku odrzucając błędne wiersze do pliku======================================== 

$NazwaPliku = 'D:\studia\BazyDanychPrzestrzennych\cw8\Customers_Nov2021.bad_' + ${TIMESTAMP} + '.csv' #nazwa pliku z aktualną datą

$tmp1 = New-Item -Path 'D:\studia\BazyDanychPrzestrzennych\cw8\tmp1.csv' -ItemType File
$tmp2 = New-Item -Path 'D:\studia\BazyDanychPrzestrzennych\cw8\tmp2.txt' -ItemType File
$BlednyPlik = New-Item -Path $NazwaPliku -ItemType File

$plik = 'D:\studia\BazyDanychPrzestrzennych\cw8\Customers_Nov2021.csv'
$plik1 = 'D:\studia\BazyDanychPrzestrzennych\cw8\Customers_old.csv'

#tworzy plik bez pustych wierszy 
Get-Content $plik | Where-Object { $_.Trim() -ne '' } > $tmp1

#znajduje różnice między zawartością pliku Customers_Nov2021.csv i Customers_old.csv
$compare = Compare-Object -referenceObject $(Get-Content $tmp1) -differenceObject $(Get-Content $Plik1) 
$compare | Where-Object {$_.SideIndicator -eq '<='} | Select-Object InputObject | Out-File -FilePath $tmp2

#usuwa zbędne 3 pierwsze wiersze 
(Get-Content $tmp2) | 
    Where-Object { -not $_.Contains('InputObject') } | 
        Where-Object { -not $_.Contains('-----------') } | 
            Select-Object -Skip 1 |
                Out-File -FilePath $tmp2

#znajduje część wspólną i przenosi do pliku błędnego Customers_Nov2021.bad_${TIMESTAMP}.csv

Compare-Object -ReferenceObject (Get-Content $tmp1) -IncludeEqual (Get-Content $plik1) | 
    Where-Object {$_.SideIndicator -eq '=='} | 
        Select-Object InputObject | 
            Out-File -FilePath $BlednyPlik

#usuwa zbędne 3 pierwsze wiersze 
(Get-Content $BlednyPlik) | 
    Where-Object { -not $_.Contains('InputObject') } | 
        Where-Object { -not $_.Contains('-----------') } | 
            Select-Object -Skip 1 |
                Out-File -FilePath $BlednyPlik

Get-Content $tmp2 > $plik 
If ($?)
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Dane zostały sprawdzone!"
}
else
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Dane nie zostały sprawdzone - błąd!"
}


#=================Tworzenie tabeli w bazie danych PostgreSQL CUSTOMERS_${NUMERINDEKSU}=========================

$NUMERINDEKSU = 403548
$Password = "Gabrysia2000"
$User = "postgres"
$Database = "cw8"
$Server = "127.0.0.1"
$Port = "5432"
$Table = "customers_$NUMERINDEKSU"

#instalowanie modułu:
#Install-Module PostgreSQLCmdlets
#Connect-PostgreSQL -User postgres -Password Gabrysia2000 -Database cw8 -Port 5432

#łączenie z postgresql
$postgresql = Connect-PostgreSQL -User "$User" -Password "$Password" -Database "$Database" -Server "$Server" -Port "$Port"

Invoke-PostgreSQL -Connection $postgresql -Query "DROP TABLE IF EXISTS $Table"

$i_p = Invoke-PostgreSQL -Connection $postgresql -Query "CREATE TABLE IF NOT EXISTS $Table 
                                      (first_name VARCHAR(50), last_name VARCHAR(50), email VARCHAR(50), lat float, long float)"

If ($?)
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Tabela została utworzona!"
}
else
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Tabela nie została utworzona - błąd!"
}


#================Ładowanie danych ze zweryfikowanego pliku do tabeli CUSTOMERS_403548=============================

Set-Location 'D:\pobrane\postgreSQL\bin\'

$env:PGPASSWORD = $Password

$PoprawnyPlik = Get-Content $tmp2
$PoprawnyPlik1 = $PoprawnyPlik -replace ",", "','"

for($i=0; $i -lt $PoprawnyPlik.Count-2; $i++)
    {
        $PoprawnyPlik1[$i] = "'" + $PoprawnyPlik1[$i] + "'"
        $czytaj = $PoprawnyPlik1[$i]
        psql -U postgres -d $Database -w -c "INSERT INTO $Table (first_name, last_name, email, lat, long) VALUES($czytaj)"
    }

If ($?)
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Dane zostały załadowane do tabeli!"
}
else
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Dane nie zostały załadowane do tabeli - błąd!"
}


#=================Przeniesienie przetworzonego pliku do pokatalogu PROCESSED===========================================================

    Set-Location $sciezka

    ${TIMESTAMP1} = ${TIMESTAMP} + "_"

    Move-Item -Path "$sciezka\Customers_Nov2021.csv" -Destination "$sciezka\PROCESSED" -PassThru -ErrorAction Stop

    Rename-Item -Path "$sciezka\PROCESSED\Customers_Nov2021.csv" "${TIMESTAMP1}Customers_Nov2021.csv"

If ($?)
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Plik został przeniesiony do podkatalogu!"
}
else
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Plik został przeniesiony do podkatalogu - błąd!"
}

#==================Wysyłanie maila z raportem=================================================================================


    $PlikPobrany = Get-Content $tmp1 #plik bez pustych linii 
    $PlikPoprawny = Get-Content "$sciezka\PROCESSED\${TIMESTAMP1}Customers_Nov2021.csv"
    $PlikBledny = Get-Content $BlednyPlik

    #	liczba wierszy w pliku pobranym z internetu,
    $liczbaWierszy = ($PlikPobrany).length

    #	liczba poprawnych wierszy (po czyszczeniu),
    $liczbaPoprawnychWierszy = ($PlikPoprawny[2..$plikPoprawny.length]).length

    #	liczba duplikatów w pliku wejściowym,
    $liczbaDuplikatow = ($plikBledny[3..$plikBledny.length]).length 

    #	ilość danych załadowanych do tabeli CUSTOMERS_${NUMERINDEKSU}.
    $iloscDanych = ($PoprawnyPlik[2..$PoprawnyPlik.length]).length


    $HasloPoczta = "Gabrysia2000"
    $Nadawca = “gjarosz.testowa@gmail.com”
    $Odbiorca = “gjarosz.testowa@gmail.com”
    $Temat = "CUSTOMERS LOAD - ${TIMESTAMP}"
    $Tresc ="Liczba wierszy w pliku pobranych z internetu wynosi: $liczbaWierszy.`n Liczba poprawnych wierszy: $liczbaPoprawnychWierszy.`n Liczba duplikatów w pliku wejściowym: $liczbaDuplikatow.`n Ilość danych załadowanych do tabeli $Table : $iloscDanych `n"
              

    $Message = New-Object Net.Mail.MailMessage 

    $smtp = New-Object Net.Mail.SmtpClient("smtp.gmail.com", 587) 
    $smtp.Credentials = New-Object System.Net.NetworkCredential("$Nadawca", "$HasloPoczta"); 
    $smtp.EnableSsl = $true 
    $smtp.Timeout = 500000  
    $Message.From = "$Nadawca" 
    $Message.To.Add("$Odbiorca") 
    $Message.Subject = "$Temat"
    $Message.Body = "$Tresc"
    $smtp.Send($Message)

If ($?)
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Mail został wysłany!"
}
else
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Mail został wysłany - błąd!"
}

#=======================Uruchamianie kwerendy SQL, która znajduje imiona i nazwiska=======================================

Set-Location 'D:\pobrane\postgreSQL\bin\'

$Password = "Gabrysia2000"
$User = "postgres"
$Database = "cw8"
$Server = "PostgreSQL 13"
$Port = "5432"
$newtable = "best_customers_$NUMERINDEKSU"
$PlikSQL = "D:\studia\BazyDanychPrzestrzennych\cw8\sql.txt"

$env:PGPASSWORD = $Password

psql -U $User -d $Database -w -f $PlikSQL

If ($?)
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Kwerenda została poprawnie uruchomiona!"
}
else
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Kwerenda została uruchomiona - błąd!"
}

#=======================Wyeksportowanie zawartości tabeli BEST_CUSTOMERS_403548 do pliku csv ======================


    $zapisz = psql -U postgres -d $Database -w -c "SELECT * FROM $newtable" 
    $tab = @()

    for ($i=2; $i -lt $zapisz.Count-2; $i++)
    {
        $zawartosc = New-Object -TypeName PSObject
        $zawartosc | Add-Member -Name 'first_name' -MemberType Noteproperty -Value $zapisz[$i].Split( "|")[0].replace(" ", "")
        $zawartosc | Add-Member -Name 'last_name' -MemberType Noteproperty -Value $zapisz[$i].Split( "|")[1].replace(" ", "")
        $zawartosc | Add-Member -Name 'odleglosc' -MemberType Noteproperty -Value $zapisz[$i].Split( "|")[2].replace(" ", "")
        $tab += $zawartosc
    }

    $tab | Export-Csv -Path "$sciezka\$newtable.csv" -NoTypeInformation

If ($?)
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Dane zostały poprawnie wyeksportowane!"
}
else
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Eksport danych - błąd!"
}

   
#=======================Skompresowanie wyeksportowanego plik csv============================================================

Compress-Archive -Path "$sciezka\$newtable.csv" -DestinationPath "$sciezka\$newtable.zip"

If ($?)
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Plik .csv poprawnie skompresowany!"
}
else
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Kompresja pliku .csv - błąd!"
}

#=======================Wysyłanie skompresowanego pliku do adresata poczty razem z raportem =============================

    Get-ItemProperty "$sciezka\$newtable.csv" | Format-Wide -Property CreationTime > "$sciezka\data.txt"
    $data = Get-Content "$sciezka\data.txt"
    Remove-Item -Path "$sciezka\data.txt"
    $data = "Data utworzenia pliku: $data`n"

    $liczbaWierszyEksport = ($zapisz[2..(($zapisz.Length)-3)]).Length
    $liczbaWierszyEksport = "Liczba wierszy w pliku: $liczbaWierszyEksport`n"

    $tresc = $data + $liczbaWierszyEksport

    $Message.To.Add("$Odbiorca") 
    $Message.Attachments.Add("$sciezka\$newtable.zip") 
    $Message.Subject = "$Temat"
    $Message.Body = "$Tresc"
    $smtp.Send($Message)

If ($?)
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Mail drugi został poprawnie wysłany!"
}
else
{
    Add-content $log -value "$(Get-Date -Format "MM/dd/yyyy HH:mm") Wysyłanie drugiego maila - błąd!"
}


#==========Usuwanie plików tymczasowych=============
Remove-Item -Path $tmp1
Remove-Item -Path $tmp2