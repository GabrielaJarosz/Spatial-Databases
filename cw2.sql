CREATE DATABASE cw2;
CREATE EXTENSION postgis;
CREATE SCHEMA map;

CREATE TABLE map.buildings(
	buildings_id INTEGER,
	buildings_geom GEOMETRY,
	buildings_name VARCHAR
	);
	
CREATE TABLE map.roads(
	roads_id INTEGER,
	roads_geom GEOMETRY,
	roads_name VARCHAR
	);
	
CREATE TABLE map.poi(
	poi_id INTEGER,
	poi_geom GEOMETRY,
	poi_name VARCHAR
	);
	
INSERT INTO map.buildings(buildings_id, buildings_geom, buildings_name) VALUES 
	(1, ST_GeomFromText('POLYGON ((8 1.5, 10.5 1.5,10.5 4, 8 4, 8 1.5))', 0), 'BuildingA'),
	(2, ST_GeomFromText('POLYGON ((4 5, 6 5, 6 7, 4 7, 4 5))', 0), 'BuildingB'),
	(3, ST_GeomFromText('POLYGON ((3 6, 5 6, 5 8, 3 8, 3 6))', 0), 'BuildingC'),
	(4, ST_GeomFromText('POLYGON ((9 8, 10 8, 10 9, 9 9, 9 8))', 0), 'BuildingD'),
	(5, ST_GeomFromText('POLYGON ((1 1, 2 1, 2 2, 1 2, 1 1))', 0), 'BuildingF');

INSERT INTO map.roads(roads_id, roads_geom, roads_name) VALUES 
	(6, ST_GeomFromText('LINESTRING(0 4.5,12 4.5)', 0),'RoadX'),
	(7, ST_GeomFromText('LINESTRING(7.5 0,7.5 10.5)', 0),'RoadY');

INSERT INTO map.poi(poi_id, poi_geom, poi_name) VALUES
	(8, ST_GeomFromText('POINT(1 3.5)', 0), 'G'),
	(9, ST_GeomFromText('POINT(5.5 1.5)', 0), 'H'),
	(10, ST_GeomFromText('POINT(9.5 6)', 0), 'I'),
	(11, ST_GeomFromText('POINT(6.5 6)', 0), 'J'),
	(12, ST_GeomFromText('POINT(6 9.5)', 0), 'K');
	
--a.	Wyznacz całkowitą długość dróg w analizowanym mieście.
SELECT SUM(ST_Length(roads_geom)) 
FROM map.roads

--b.	Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego budynek o nazwie BuildingA. 
SELECT buildings_geom, ST_Area(buildings_geom), ST_Perimeter(buildings_geom)
FROM map.buildings
WHERE buildings.buildings_name = 'BuildingA'

--c.	Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie.  
SELECT buildings_name, ST_Area(buildings_geom)
FROM map.buildings
ORDER BY buildings_name

--d.	Wypisz nazwy i obwody 2 budynków o największej powierzchni. 
SELECT buildings_name, ST_Perimeter(buildings_geom)
FROM map.buildings
ORDER BY ST_Area(buildings_geom) DESC
LIMIT 2

--e.	Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G.  
SELECT MIN(ST_Distance(buildings.buildings_geom, poi.poi_geom))
FROM map.buildings, map.poi
WHERE buildings_name = 'BuildingC' AND poi_name = 'G'

--f.	Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej niż 0.5 od budynku BuildingB. 
SELECT ST_Area(ST_Difference 
				((SELECT buildings_geom 
				 FROM map.buildings 
				 WHERE buildings_name = 'BuildingC'), ST_Buffer((SELECT buildings_geom 
																 FROM map.buildings 
																 WHERE buildings_name = 'BuildingB'),0.5)))
 
--g.	Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi 
--      o nazwie RoadX.  

SELECT buildings_name, ST_Centroid(buildings.buildings_geom)
FROM map.buildings, map.roads
WHERE ST_Y(ST_Centroid(buildings.buildings_geom)) > ST_Y(ST_Centroid(roads.roads_geom)) 
AND roads_name = 'RoadX';


--h. Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.
  SELECT ((SELECT ST_Area(ST_Difference(ST_GeomFromText('POLYGON ((4 7, 6 7, 6 8, 4 8, 4 7))', 0), buildings.buildings_geom)))
		  + (SELECT ST_Area(ST_Difference(buildings.buildings_geom, ST_GeomFromText('POLYGON ((4 7, 6 7, 6 8, 4 8, 4 7))', 0)))))
		      FROM map.buildings 
  				WHERE buildings_name = 'BuildingC'
