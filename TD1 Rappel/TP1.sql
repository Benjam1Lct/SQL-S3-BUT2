create table employe as select * from basetd.employe;
create table service as select * from basetd.service;
create table projet as select * from basetd.projet;
create table travail as select * from basetd.travail;
create table concerne as select * from basetd.concerne;

alter table employe add constraint PK_employe primary key (NUEMPL); #
alter table employe add constraint FK_affect foreign key (AFFECT) references service(NUSERV); #

alter table service add constraint PK_service primary key (NUSERV);#
alter table service add constraint FK_chef foreign key (chef) references employe(NUEMPL) deferrable initially deferred;#

alter table projet add constraint PK_projet primary key (NUPROJ);#
ALTER TABLE projet ADD CONSTRAINT FK_resp FOREIGN KEY (RESP) REFERENCES employe(NUEMPL);

ALTER TABLE travail ADD CONSTRAINT PK_travail PRIMARY KEY (NUEMPL, NUPROJ);#
ALTER TABLE travail ADD CONSTRAINT FK_employe FOREIGN KEY (NUEMPL) REFERENCES employe(NUEMPL); #

ALTER TABLE concerne ADD CONSTRAINT PK_concerne PRIMARY KEY (NUPROJ, NUSERV);#
ALTER TABLE concerne ADD CONSTRAINT FK_service FOREIGN KEY (NUSERV) REFERENCES service(NUSERV);

ALTER TABLE travail ADD CONSTRAINT FK_projet_travail FOREIGN KEY (NUPROJ) REFERENCES projet(NUPROJ);
ALTER TABLE concerne ADD CONSTRAINT FK_projet_concerne FOREIGN KEY (NUPROJ) REFERENCES projet(NUPROJ);


INSERT INTO employe VALUES (12,'marcel',35,39);
INSERT into employe values (21,'jean',35,41);
Delete from employe where NUEMPL=41;
DELETE from service where NUSERV=1;
INSERT INTO service VALUES (6,'compta',200);
insert into projet values (1,'projet1',200);
INSERT INTO travail VALUES (20, 492, 10);
INSERT INTO concerne VALUES (2, 160);
INSERT INTO projet VALUES (2, 'projet2', 999);
INSERT INTO travail VALUES (21, 999, 10);
INSERT INTO concerne VALUES (2, 999);
INSERT INTO concerne VALUES (99, 1);
DELETE FROM employe WHERE NUEMPL = 30;
DELETE FROM projet WHERE NUPROJ = 103;
DELETE FROM service WHERE NUSERV = 3;
DELETE FROM projet WHERE NUPROJ = 103;

alter table employe add salaire number;

-- Partie 2.a

UPDATE employe
SET salaire = 2500
WHERE NUEMPL IN (SELECT RESP FROM projet);

UPDATE employe
SET salaire = 3500
WHERE NUEMPL IN (SELECT chef FROM service);

UPDATE employe
SET salaire = 1999
WHERE NUEMPL NOT IN (SELECT RESP FROM projet)
  AND NUEMPL NOT IN (SELECT chef FROM service);

-- Partie 2.b

SELECT *
FROM employe e
WHERE e.NUEMPL IN (
    SELECT t.NUEMPL
    FROM travail t
    GROUP BY t.NUEMPL
    HAVING SUM(t.DUREE) > (SELECT e2.HEBDO FROM employe e2 WHERE e2.NUEMPL = t.NUEMPL)
);

-- Mettre à jour les durées dans la table travail pour respecter la contrainte
UPDATE travail t
SET t.DUREE = t.DUREE - 1
WHERE t.NUEMPL IN (
    SELECT e.NUEMPL
    FROM employe e
    JOIN travail t ON e.NUEMPL = t.NUEMPL
    GROUP BY e.NUEMPL, e.HEBDO
    HAVING SUM(t.DUREE) > e.HEBDO
);

-- Mettre à jour la durée hebdomadaire dans la table employe pour respecter la contrainte
UPDATE employe e
SET e.HEBDO = e.HEBDO + 1
WHERE e.NUEMPL IN (
    SELECT t.NUEMPL
    FROM travail t
    GROUP BY t.NUEMPL
    HAVING SUM(t.DUREE) > (SELECT e2.HEBDO FROM employe e2 WHERE e2.NUEMPL = t.NUEMPL)
);

SELECT e.NUEMPL, e.HEBDO, SUM(t.DUREE) AS total_heures
FROM employe e
LEFT JOIN travail t ON e.NUEMPL = t.NUEMPL
GROUP BY e.NUEMPL, e.HEBDO;

-- Mettre à jour les durées dans la table travail pour respecter la contrainte
UPDATE travail t
SET t.DUREE = t.DUREE - 1
WHERE t.NUEMPL IN (
    SELECT e.NUEMPL
    FROM employe e
    JOIN travail t ON e.NUEMPL = t.NUEMPL
    GROUP BY e.NUEMPL, e.HEBDO
    HAVING SUM(t.DUREE) > e.HEBDO
);

-- Répéter la mise à jour jusqu'à ce que la contrainte soit respectée
BEGIN
    LOOP
        UPDATE travail t
        SET t.DUREE = t.DUREE - 1
        WHERE t.DUREE > 0
        AND t.NUEMPL IN (
            SELECT e.NUEMPL
            FROM employe e
            JOIN travail t ON e.NUEMPL = t.NUEMPL
            GROUP BY e.NUEMPL, e.HEBDO
            HAVING SUM(t.DUREE) > e.HEBDO
        );

        -- Sortir de la boucle si aucune ligne n'est mise à jour
        EXIT WHEN SQL%ROWCOUNT = 0;
    END LOOP;
END;
-- Trouver les employés responsables de plus de 3 projets
SELECT RESP
FROM projet
HAVING COUNT(*) > 3
GROUP BY RESP;

-- Mettre à jour les projets pour respecter la contrainte
UPDATE projet p
SET p.RESP = NULL
WHERE p.RESP IN (
    SELECT RESP
    FROM projet
    GROUP BY RESP
    HAVING COUNT(*) > 3
);

-- Trouver les chefs de service qui ne gagnent pas plus que les employés de leur service
SELECT s.chef, e.salaire
FROM service s
JOIN employe e ON s.chef = e.NUEMPL
WHERE e.salaire <= (
    SELECT MAX(e2.salaire)
    FROM employe e2
    WHERE e2.AFFECT = s.NUSERV
);

-- Mettre à jour les salaires des chefs de service pour respecter la contrainte
UPDATE employe e
SET e.salaire = e.salaire + 500
WHERE e.NUEMPL IN (
    SELECT s.chef
    FROM service s
    JOIN employe e ON s.chef = e.NUEMPL
    WHERE e.salaire <= (
        SELECT MAX(e2.salaire)
        FROM employe e2
        WHERE e2.AFFECT = s.NUSERV
    )
);

-- Trouver les services concernés par plus de 3 projets
SELECT NUSERV
FROM concerne
GROUP BY NUSERV
HAVING COUNT(*) > 3;
-- Trouver les services concernés par plus de 3 projets
WITH ServicesTropProjets AS (
    SELECT NUSERV
    FROM concerne
    GROUP BY NUSERV
    HAVING COUNT(*) > 3
),
ServicesMoinsProjets AS (
    SELECT NUSERV
    FROM concerne
    GROUP BY NUSERV
    HAVING COUNT(*) < 3
);

-- Sélectionner les services pour vérifier les résultats des CTE
SELECT * FROM ServicesTropProjets;
SELECT * FROM ServicesMoinsProjets;

-- Réattribuer les projets en excès
UPDATE concerne c
SET c.NUSERV = (
    SELECT NUSERV
    FROM ServicesMoinsProjets
    WHERE ROWNUM = 1
)
WHERE c.NUSERV IN (SELECT NUSERV FROM ServicesTropProjets)
AND (SELECT COUNT(*) FROM concerne c2 WHERE c2.NUSERV = c.NUSERV) > 3;