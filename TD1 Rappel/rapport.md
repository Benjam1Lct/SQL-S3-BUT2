# Compte Rendu TP1
## Introduction
Ce TP de SQL porte sur la création, la gestion et l'interrogation de tables dans un système de base de 
données pour la gestion des employés. La base de données suit les informations relatives aux employés, 
services, projets, et aux relations entre eux, comme les projets sur lesquels travaillent les employés et les 
services responsables de ces projets.

## Tables utilisées :
- employe : Stocke les informations sur les employés.
- service : Stocke les informations sur les services ou départements.
- projet : Stocke les informations sur les projets.
- travail : Suit l'implication des employés dans les projets, y compris la durée du travail.
- concerne : Suit les services responsables de chaque projet. 

## Partie 1 : Création des tables et contraintes
### Étape 1 : Création des tables
Les tables suivantes ont été créées en se basant sur les données existantes du schéma basetd :

```sql
CREATE TABLE employe AS SELECT * FROM basetd.employe;
CREATE TABLE service AS SELECT * FROM basetd.service;
CREATE TABLE projet AS SELECT * FROM basetd.projet;
CREATE TABLE travail AS SELECT * FROM basetd.travail;
CREATE TABLE concerne AS SELECT * FROM basetd.concerne;
```

### Étape 2 : Ajout des clés primaires et des clés étrangères
Des contraintes ont été ajoutées pour garantir l'intégrité des données :

```sql
ALTER TABLE employe ADD CONSTRAINT PK_employe PRIMARY KEY (NUEMPL);
ALTER TABLE employe ADD CONSTRAINT FK_affect FOREIGN KEY (AFFECT) REFERENCES service(NUSERV);

ALTER TABLE service ADD CONSTRAINT PK_service PRIMARY KEY (NUSERV);
ALTER TABLE service ADD CONSTRAINT FK_chef FOREIGN KEY (chef) REFERENCES employe(NUEMPL) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE projet ADD CONSTRAINT PK_projet PRIMARY KEY (NUPROJ);
ALTER TABLE projet ADD CONSTRAINT FK_resp FOREIGN KEY (RESP) REFERENCES employe(NUEMPL) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE travail ADD CONSTRAINT PK_travail PRIMARY KEY (NUEMPL, NUPROJ);
ALTER TABLE travail ADD CONSTRAINT FK_employe FOREIGN KEY (NUEMPL) REFERENCES employe(NUEMPL) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE concerne ADD CONSTRAINT PK_concerne PRIMARY KEY (NUPROJ, NUSERV);
ALTER TABLE concerne ADD CONSTRAINT FK_service FOREIGN KEY (NUSERV) REFERENCES service(NUSERV);
ALTER TABLE concerne ADD CONSTRAINT FK_projet_concerne FOREIGN KEY (NUPROJ) REFERENCES projet(NUPROJ);
```

### Étape 3 : Insertion et suppression de données
Des données d'exemple ont été insérées dans les tables et certaines lignes ont été supprimées pour simuler 
des opérations réelles :

```sql
INSERT INTO employe VALUES (12, 'marcel', 35, 39);
INSERT INTO service VALUES (6, 'compta', 200);
INSERT INTO projet VALUES (1, 'projet1', 200);
DELETE FROM employe WHERE NUEMPL = 30;
DELETE FROM service WHERE NUSERV = 3;
```

### Étape 4 : Ajout d'une nouvelle colonne pour les salaires
Une nouvelle colonne salaire a été ajoutée à la table employe pour stocker les salaires des employés :

```sql
ALTER TABLE employe ADD salaire NUMBER;
```

## Partie 2 : Manipulation des données et requêtes
### 2.a : Mise à jour des salaires des employés
Les salaires des employés ont été mis à jour en fonction de leur rôle (responsables de projets ou chefs de service) :

```sql
UPDATE employe SET salaire = 2500 WHERE NUEMPL IN (SELECT RESP FROM projet);
UPDATE employe SET salaire = 3500 WHERE NUEMPL IN (SELECT chef FROM service);
UPDATE employe SET salaire = 1999 WHERE NUEMPL NOT IN (SELECT RESP FROM projet) AND NUEMPL NOT IN (SELECT chef FROM service);
```

### 2.b : Identification des employés surchargés
Cette requête identifie les employés ayant des heures de travail supérieures à leur durée hebdomadaire contractuelle :

```sql
SELECT * FROM employe e
WHERE e.NUEMPL IN (
    SELECT t.NUEMPL
    FROM travail t
    GROUP BY t.NUEMPL
    HAVING SUM(t.DUREE) > (SELECT e2.HEBDO FROM employe e2 WHERE e2.NUEMPL = t.NUEMPL)
);
```

_Correction des heures de travail_

La table travail a été mise à jour pour réduire les durées de travail lorsque les employés sont surchargés :

```sql
UPDATE travail t
SET t.DUREE = t.DUREE - 1
WHERE t.NUEMPL IN (
    SELECT e.NUEMPL
    FROM employe e
    JOIN travail t ON e.NUEMPL = t.NUEMPL
    GROUP BY e.NUEMPL, e.HEBDO
    HAVING SUM(t.DUREE) > e.HEBDO
);
```

_Boucle de mise à jour pour respecter la contrainte des heures de travail_

Une boucle a été mise en place pour réduire les heures de travail jusqu'à ce que la contrainte soit respectée :

```sql
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
        EXIT WHEN SQL%ROWCOUNT = 0;
    END LOOP;
END;
```

_Vérification des salaires des chefs de service_

Cette requête identifie les chefs de service qui ne gagnent pas plus que les employés de leur propre service :

```sql
SELECT s.chef, e.salaire
FROM service s
JOIN employe e ON s.chef = e.NUEMPL
WHERE e.salaire <= (
    SELECT MAX(e2.salaire)
    FROM employe e2
    WHERE e2.AFFECT = s.NUSERV
);
```

## Partie 3 : Contraintes liées aux projets et services
**_Identification des services ayant trop de projets_**

La requête suivante identifie les services responsables de plus de trois projets :

```sql
SELECT NUSERV
FROM concerne
GROUP BY NUSERV
HAVING COUNT(*) > 3;
```

_Réattribution des projets_

Pour équilibrer la charge de travail, les projets en excès ont été réattribués à des services ayant moins de trois projets :

```sql
UPDATE concerne c
SET c.NUSERV = (
    SELECT NUSERV
    FROM ServicesMoinsProjets
    WHERE ROWNUM = 1
)
WHERE c.NUSERV IN (SELECT NUSERV FROM ServicesTropProjets)
AND (SELECT COUNT(*) FROM concerne c2 WHERE c2.NUSERV = c.NUSERV) > 3;
```

## Conclusion
Ce TP s'est concentré sur la création d'un système de base de données robuste pour la gestion des informations sur les employés et les projets, tout en garantissant l'intégrité des données grâce à des contraintes. En outre, des requêtes SQL ont été utilisées pour gérer et mettre à jour les données dans un scénario réaliste, incluant l'équilibrage des charges de travail et l'ajustement des salaires.






