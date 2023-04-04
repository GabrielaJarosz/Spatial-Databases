--Create extension postgis;

--4.	Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty) położonych 
--w odległości mniejszej niż 1000 m od głównych rzek. Budynki spełniające to kryterium zapisz do osobnej tabeli tableB.

SELECT COUNT(popp.f_codedesc)
FROM popp, majrivers 
WHERE ST_Distance(popp.geom,majrivers.geom) < 1000 AND popp.f_codedesc = 'Building'

SELECT popp.f_codedesc
INTO tableB
FROM popp, majrivers 
WHERE ST_Distance(popp.geom,majrivers.geom) < 1000 AND popp.f_codedesc = 'Building'

SELECT * FROM tableB
--5.	Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, 
--ich geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.  

SELECT name, geom, elev 
INTO airportsNew	
FROM airports

--a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód. 
SELECT name, ST_Y(airportsNew.geom) as zachod 
FROM airportsNew
ORDER BY zachod
LIMIT 1

SELECT name, ST_Y(airportsNew.geom) as wschod 
FROM airportsNew
ORDER BY wschod DESC
LIMIT 1

--b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie środkowym 
--drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB. Wysokość n.p.m. przyjmij dowolną.

INSERT INTO airportsNew(name, geom, elev) VALUES
	('airportB',
	(SELECT ST_Centroid(ST_ShortestLine(y1.geom,y2.geom))
		FROM airportsNew y1, airportsNew y2
		WHERE y1.name = 'NOATAK' AND y2.name = 'NIKOLSKI AS'),00000);
				
--wyswietlanie 3 lotnisk w ramach spr.
SELECT name, airportsNew.geom
FROM airportsNew  
WHERE name = 'airportB'	
UNION 
SELECT name, airportsNew.geom
FROM airportsNew  
WHERE name = 'NOATAK'
UNION
SELECT name, airportsNew.geom
FROM airportsNew  
WHERE name = 'NIKOLSKI AS'

--6.	Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej
--linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”

SELECT ST_Area(ST_Buffer((SELECT ST_ShortestLine(lakes.geom, airports.geom)
							FROM lakes, airports
							WHERE  lakes.names = 'Iliamna Lake' 
						  			AND airports.name = 'AMBLER'),1000)) AS POLE
				
--7.	Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów 
--reprezentujących poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).  

SELECT trees.vegdesc, SUM(ST_Area(trees.geom)) AS pole
FROM trees, swamp, tundra 
WHERE ST_Contains(trees.geom, swamp.geom) OR ST_Contains(trees.geom, tundra.geom)
GROUP BY trees.vegdesc;










