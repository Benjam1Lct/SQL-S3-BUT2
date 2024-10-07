# Rapport TD3 : Procédure Stockées dans un package

## Exercice 1 :

```sql
create or replace package MAJ is
PROCEDURE CREER_EMPLOYE (LE_NUEMPL IN NUMBER, LE_NOMEMPL IN VARCHAR2, LE_HEBDO IN NUMBER, LE_AFFECT IN NUMBER,LE_SALAIRE IN NUMBER);
END;
```

```sql
create or replace package  BODY MAJ is
    PROCEDURE CREER_EMPLOYE (LE_NUEMPL IN NUMBER, LE_NOMEMPL IN VARCHAR2, LE_HEBDO IN NUMBER, LE_AFFECT IN NUMBER,LE_SALAIRE IN NUMBER) is
    BEGIN
        SET TRANSACTION READ WRITE;
        INSERT INTO employe VALUES(LE_NUEMPL, LE_NOMEMPL, LE_HEBDO, LE_AFFECT,LE_SALAIRE);
        COMMIT;
    EXCEPTION WHEN OTHERS THEN ROLLBACK;
        IF SQLCODE=-00001 THEN ROLLBACK;
              RAISE_APPLICATION_ERROR (-20101, 'Un employe avec le meme numero existe deja');
        ELSIF SQLCODE=-2291 THEN ROLLBACK;
              RAISE_APPLICATION_ERROR (-20102, 'Le service auquel il est affecté n''existe pas');
        ELSIF SQLCODE=-02290 THEN ROLLBACK;
              RAISE_APPLICATION_ERROR (-20103, 'La durée hebdomadaire d''un employé doit être inférieure ou égale à 35h');
        ELSIF SQLCODE=-1438 THEN ROLLBACK;
              RAISE_APPLICATION_ERROR (-20104, 'Une valeur dépasse le nombre de caractères autorises (nombre)');
        ELSIF SQLCODE=-12899 THEN ROLLBACK;
              RAISE_APPLICATION_ERROR (-20105, 'Une valeur dépasse le nombre de caractères autorisés chaine de caractère');
        ELSIF SQLCODE=-20010 OR SQLCODE=-20009 THEN ROLLBACK;
              RAISE_APPLICATION_ERROR (-20106, 'Le salaire de cet employé dépasse celui de son chef de service');
        ELSE  RAISE_APPLICATION_ERROR(-20999,'Erreur inconnue ' || SQLCODE || ' : ' || SQLERRM);
        END IF;
    END;
END;
```

**_Test de la procedure_**

```sql 
BEGIN
   MAJ.CREER_EMPLOYE(103, 'Pol8', 35, 5, 1999);
END;
```

**B.** Codes et erreurs correspondantes

| Erreur Oracle | Code erreur retourné | Message personnalisé                                                   |
|---------------|----------------------|-------------------------------------------------------------------------|
| PK -0001      | -20101               | Un employé avec le même numéro existe déjà                              |
| FK -2291      | -20102               | Le service auquel il est affecté n'existe pas                           |
| CHECK -2290   | -20103               | La durée hebdomadaire d’un employé doit être inférieure ou égale à 35h  |
| -1438         | -20104               | Une valeur dépasse le nombre de caractères autorisés (nombre)           |
| -12899        | -20105               | Une valeur dépasse le nombre de caractères autorisés (chaîne de caractère) |
| Trigger Salaire | -20106               | Le salaire de cet employé dépasse celui de son chef de service          |
| Autres        | -20999               | Erreur inattendue                                                      |

### Création des employés et gestion des erreurs :
La procédure CREER_EMPLOYE gère l'insertion d'employés dans la base de données. Pour garantir l'intégrité des données, des contrôles d'erreur robustes sont mis en place, en renvoyant des codes d'erreur personnalisés selon les différentes contraintes.

### Justification :
- Dans le TD1, on a configuré la structure de base des tables, notamment la table employee, avec les clés primaires 
et les clés étrangères. Dans cette structure, l'intégrité des données est assurée par les contraintes sur les clés étrangères 
(comme l’affectation à un service). Cela est renforcé par les contrôles d'erreurs que l'on a mises en place dans la procédure 
CREER_EMPLOYE pour vérifier l’existence du service lors de l’affectation (FOREIGN KEY FK_affect).
- Le TD2 met en avant les triggers tels que empecher_diminution_salaire et empecher_augmentation_hebdo, qui garantissent 
qu’un employé respecte des limites salariales et horaires. En TD3, la procédure stockée CREER_EMPLOYE s'assure également
que les valeurs comme la durée hebdomadaire (inférieure ou égale à 35h) et le salaire sont conformes aux règles métiers, 
en capturant les erreurs liées à ces limites dans le bloc EXCEPTION.

### Exercice 2 :

Pour éviter de supprimer la procédure creer precedement je préfère réexécuter toute les procedure en meme temps dans une unique requete.

```sql
CREATE OR REPLACE PACKAGE MAJ IS
    PROCEDURE CREER_EMPLOYE (LE_NUEMPL IN NUMBER, LE_NOMEMPL IN VARCHAR2, LE_HEBDO IN NUMBER, LE_AFFECT IN NUMBER,LE_SALAIRE IN NUMBER);

   -- Modifier la durée hebdomadaire d'un employé
   PROCEDURE MODIFIER_DUREE_HEBDO(LE_NUEMPL IN NUMBER, LA_NOUVELLE_DUREE IN NUMBER);

   -- Modifier le salaire d'un employé
   PROCEDURE MODIFIER_SALAIRE(LE_NUEMPL IN NUMBER, LE_NOUVEAU_SALAIRE IN NUMBER);

   -- Modifier la durée dans la table travail
   PROCEDURE MODIFIER_DUREE_TRAVAIL(LE_NUEMPL IN NUMBER, LE_NUPROJ IN NUMBER, LA_NOUVELLE_DUREE IN NUMBER);

   -- Insérer un enregistrement dans la table travail
   PROCEDURE INSERER_TRAVAIL(LE_NUEMPL IN NUMBER, LE_NUPROJ IN NUMBER, LA_DUREE IN NUMBER);

   -- Ajouter un enregistrement dans la table service et affecter un chef
   PROCEDURE AJOUTER_SERVICE(LE_NUSERV IN NUMBER, LE_NOMSERV IN VARCHAR2, LE_CHEF IN NUMBER);
END MAJ;
```

```sql
CREATE OR REPLACE PACKAGE BODY MAJ IS
    PROCEDURE CREER_EMPLOYE (LE_NUEMPL IN NUMBER, LE_NOMEMPL IN VARCHAR2, LE_HEBDO IN NUMBER, LE_AFFECT IN NUMBER,LE_SALAIRE IN NUMBER) is
    BEGIN
        SET TRANSACTION READ WRITE;
        INSERT INTO employe VALUES(LE_NUEMPL, LE_NOMEMPL, LE_HEBDO, LE_AFFECT,LE_SALAIRE);
        COMMIT;
    EXCEPTION WHEN OTHERS THEN ROLLBACK;
        IF SQLCODE=-00001 THEN ROLLBACK;
              RAISE_APPLICATION_ERROR (-20101, 'Un employe avec le meme numero existe deja');
        ELSIF SQLCODE=-2291 THEN ROLLBACK;
              RAISE_APPLICATION_ERROR (-20102, 'Le service auquel il est affecté n''existe pas');
        ELSIF SQLCODE=-02290 THEN ROLLBACK;
              RAISE_APPLICATION_ERROR (-20103, 'La durée hebdomadaire d''un employé doit être inférieure ou égale à 35h');
        ELSIF SQLCODE=-1438 THEN ROLLBACK;
              RAISE_APPLICATION_ERROR (-20104, 'Une valeur dépasse le nombre de caractères autorises (nombre)');
        ELSIF SQLCODE=-12899 THEN ROLLBACK;
              RAISE_APPLICATION_ERROR (-20105, 'Une valeur dépasse le nombre de caractères autorisés chaine de caractère');
        ELSIF SQLCODE=-20010 OR SQLCODE=-20009 THEN ROLLBACK;
              RAISE_APPLICATION_ERROR (-20106, 'Le salaire de cet employé dépasse celui de son chef de service');
        ELSE  RAISE_APPLICATION_ERROR(-20999,'Erreur inconnue ' || SQLCODE || ' : ' || SQLERRM);
        END IF;
    END CREER_EMPLOYE;
```

### Procedure n°1 : Modification de la durée hebdomadaire de la table « employe »

```sql
-- procedure 1
   PROCEDURE MODIFIER_DUREE_HEBDO(LE_NUEMPL IN NUMBER, LA_NOUVELLE_DUREE IN NUMBER) IS
    BEGIN
       UPDATE employe
       SET hebdo = LA_NOUVELLE_DUREE
       WHERE nuempl = LE_NUEMPL;
    
       IF SQL%NOTFOUND THEN
          RAISE_APPLICATION_ERROR(-20101, 'Aucun employé trouvé avec ce numéro.');
       END IF;
    
       COMMIT;  -- Ajout du commit
    
    EXCEPTION
       WHEN OTHERS THEN
          IF SQLCODE = -20002 THEN
             -- Correspond à l'erreur du trigger empecher_augmentation_hebdo
             RAISE_APPLICATION_ERROR(-20102, 'Durée hebdomadaire non modifiable : ' || SQLERRM);
          ELSIF SQLCODE = -20007 THEN
             RAISE_APPLICATION_ERROR (-20112, 'Durée hebdomadaire non modifiable : ' || SQLERRM);
          ELSE
             RAISE_APPLICATION_ERROR(-20999, 'Erreur inconnue : ' || SQLERRM);
          END IF;
    END MODIFIER_DUREE_HEBDO;
```

_**Tests :**_

```sql
EXEC MAJ.MODIFIER_SALAIRE(1, 35);  -- Il n'y a pas d'employé
EXEC MAJ.MODIFIER_DUREE_HEBDO(17, 30);  -- Ça fonctionne
EXEC MAJ.MODIFIER_DUREE_HEBDO(17, 45);  -- C'est interdit
EXEC MAJ.MODIFIER_DUREE_HEBDO(23, 15);  -- C'est interdit
```

| Code erreur Oracle | Code erreur retourné | Message d'erreur personnalisé                                                                       |
|--------------------|----------------------|-----------------------------------------------------------------------------------------------------|
| ORA-20002          | -20101               | Aucun employé trouvé avec ce numéro.                                                                |
| ORA-20002          | -20102               | Durée hebdomadaire non modifiable : Vous ne pouvez pas augmenter la durée hebdomadaire de l'employé. |
| ORA-20002          | -20112               | Durée hebdomadaire non modifiable |
| ORA-20999          | -20999               | Erreur inconnue : Erreur non prévue capturée dans la procédure.                                     |


### Justification :
- Dans le TD1, tu as utilisé des requêtes pour identifier les employés dont la somme des heures de travail dépasse leur durée hebdomadaire. Ces vérifications manuelles dans les requêtes sont maintenant automatisées dans la procédure MODIFIER_DUREE_HEBDO, qui met à jour cette durée en tenant compte des erreurs potentielles liées aux contraintes.
- Le TD2 présente le trigger empecher_augmentation_hebdo, qui bloque toute tentative d’augmenter la durée hebdomadaire au-delà des limites. En TD3, la procédure MODIFIER_DUREE_HEBDO complète cette logique en capturant les violations potentielles des règles de durée dans le bloc EXCEPTION.

### Procedure n°2 : Modification du salaire d’un employé.
```sql
-- procedure 2
    PROCEDURE MODIFIER_SALAIRE(LE_NUEMPL IN NUMBER, LE_NOUVEAU_SALAIRE IN NUMBER) IS
    BEGIN
       UPDATE employe
       SET salaire = LE_NOUVEAU_SALAIRE
       WHERE nuempl = LE_NUEMPL;
    
       IF SQL%NOTFOUND THEN
          RAISE_APPLICATION_ERROR(-20101, 'Aucun employé trouvé avec ce numéro.');
       END IF;
    
       COMMIT;  -- Ajout du commit
    
    EXCEPTION
       WHEN OTHERS THEN
          IF SQLCODE = -20001 THEN
             -- Correspond à l'erreur du trigger empecher_diminution_salaire
             RAISE_APPLICATION_ERROR(-20103, 'Impossible de diminuer le salaire : ' || SQLERRM);
          ELSIF SQLCODE = -20009 THEN
             -- Correspond à l'erreur du trigger check_chef_salaire
             RAISE_APPLICATION_ERROR(-20104, 'Le chef de service doit gagner plus que les employés de son service.');
          ELSE
             RAISE_APPLICATION_ERROR(-20999, 'Erreur inconnue : ' || SQLERRM);
          END IF;
    END MODIFIER_SALAIRE;

```
| Code erreur Oracle | Code erreur retourné | Message d'erreur personnalisé                                              |
|--------------------|----------------------|-----------------------------------------------------------------------------|
| ORA-20001          | -20101               | Aucun employé trouvé avec ce numéro.     |
| ORA-20001          | -20103               | Impossible de diminuer le salaire |
| ORA-20009          | -20104                | Le chef de service doit gagner plus que les employés de son service.         |
| ORA-20999          | -20999               | Erreur inconnue : Erreur non prévue capturée dans la procédure.              |

### Justification :
- Dans le TD1, tu as mis en place une mise à jour des salaires basée sur les responsabilités des employés (chefs de service et responsables de projets). La procédure MODIFIER_SALAIRE en TD3 s’appuie sur cette logique en contrôlant que les règles de hiérarchie salariale sont respectées.
- Le trigger empecher_diminution_salaire du TD2 est crucial ici. Il empêche la diminution du salaire d’un employé, une logique que l'on retrouve dans la procédure MODIFIER_SALAIRE, qui contrôle et renvoie une erreur si une telle tentative est effectuée.

### Procedure n°3 : Modification de la durée de la table travail correspondant à un ''nuempl'' et ''nuproj''.
```sql
-- procedure 3
    PROCEDURE MODIFIER_DUREE_TRAVAIL(LE_NUEMPL IN NUMBER, LE_NUPROJ IN NUMBER, LA_NOUVELLE_DUREE IN NUMBER) IS
    BEGIN
       UPDATE travail
       SET duree = LA_NOUVELLE_DUREE
       WHERE nuempl = LE_NUEMPL AND nuproj = LE_NUPROJ;
    
       IF SQL%NOTFOUND THEN
          RAISE_APPLICATION_ERROR(-20105, 'Aucun enregistrement trouvé pour cet employé et projet.');
       END IF;
    
       COMMIT;  -- Ajout du commit
    
    EXCEPTION
       WHEN OTHERS THEN
          IF SQLCODE = -20003 THEN
             -- Correspond à l'erreur du trigger supprimer_employe
             RAISE_APPLICATION_ERROR(-20106, 'Erreur lors de la suppression de l''employé : ' || SQLERRM);
          ELSE
             RAISE_APPLICATION_ERROR(-20999, 'Erreur inconnue : ' || SQLERRM);
          END IF;
    END MODIFIER_DUREE_TRAVAIL;
```
| Code erreur Oracle | Code erreur retourné | Message d'erreur personnalisé                                             |
|--------------------|----------------------|----------------------------------------------------------------------------|
| ORA-20003          | -20105               | Aucun enregistrement trouvé pour cet employé et projet. |
| ORA-20003          | -20106               | Erreur lors de la suppression de l'employé |
| ORA-20999          | -20999               | Erreur inconnue : Erreur non prévue capturée dans la procédure.             |

### Justification :
- Dans le TD1, tu as utilisé des requêtes pour détecter les employés dont le travail total dépasse leur durée hebdomadaire. Ici, la procédure MODIFIER_DUREE_TRAVAIL vérifie cela en mettant à jour les données tout en contrôlant que la somme des heures n’excède pas la limite.
- Le TD2 introduit des triggers comme check_duree_insert et check_duree_update, qui valident la somme des heures de travail. En TD3, cette procédure continue cette logique en garantissant que les mises à jour des durées respectent ces contraintes.

### Procedure n°4 : Insertion d’un enregistrement dans la table travail.
```sql
-- procedure 4
    PROCEDURE INSERER_TRAVAIL(LE_NUEMPL IN NUMBER, LE_NUPROJ IN NUMBER, LA_DUREE IN NUMBER) IS
    BEGIN
       INSERT INTO travail (nuempl, nuproj, duree)
       VALUES (LE_NUEMPL, LE_NUPROJ, LA_DUREE);
    
       IF SQL%ROWCOUNT = 0 THEN
          RAISE_APPLICATION_ERROR(-20107, 'Insertion échouée pour cet employé et projet.');
       END IF;
    
       COMMIT;  -- Ajout du commit
    
    EXCEPTION
       WHEN OTHERS THEN
          IF SQLCODE = -20009 THEN
             -- Correspond à l'erreur du trigger limitant le nombre de projets d'un service
             RAISE_APPLICATION_ERROR(-20108, 'Un service ne peut être concerné par plus de 3 projets.');
          ELSE
             RAISE_APPLICATION_ERROR(-20999, 'Erreur inconnue : ' || SQLERRM);
          END IF;
    END INSERER_TRAVAIL;
```
| Code erreur Oracle | Code erreur retourné | Message d'erreur personnalisé                                               |
|--------------------|----------------------|------------------------------------------------------------------------------|
| ORA-20009          | -20107               | Insertion échouée pour cet employé et projet.                       |
| ORA-20009          | -20108               | Un service ne peut être concerné par plus de 3 projets.                       |
| ORA-20999          | -20999               | Erreur inconnue : Erreur non prévue capturée dans la procédure.               |

### Justification :
- La table travail créée dans le TD1 est au cœur de la gestion des tâches attribuées aux employés. Les requêtes visant à identifier les employés surchargés sont maintenant optimisées avec cette procédure d’insertion qui inclut des contrôles pour éviter d’assigner trop d’heures à un employé.
- Le trigger check_duree_insert du TD2 garantit que l’insertion de nouvelles tâches ne viole pas les contraintes de durée. Cette vérification est désormais intégrée dans la procédure INSERER_TRAVAIL.

### Procedure n°5 : Ajout d’un enregistrement dans la table service. Dans ce cas vous affectez le chef dans ce service avec un insert ou un update d’un employé qui existe déjà.
```sql
-- procedure 5
   PROCEDURE AJOUTER_SERVICE(LE_NUSERV IN NUMBER, LE_NOMSERV IN VARCHAR2, LE_CHEF IN NUMBER) IS
    BEGIN
       INSERT INTO service (nuserv, nomserv, chef)
       VALUES (LE_NUSERV, LE_NOMSERV, LE_CHEF);
    
       -- Mise à jour de l'employé pour l'affecter comme chef de service
       UPDATE employe
       SET affect = LE_NUSERV
       WHERE nuempl = LE_CHEF;
    
       IF SQL%NOTFOUND THEN
          RAISE_APPLICATION_ERROR(-20109, 'Aucun employé trouvé pour être affecté comme chef.');
       END IF;
    
       COMMIT;  -- Ajout du commit
    
    EXCEPTION
       WHEN OTHERS THEN
          IF SQLCODE = -20009 THEN
             -- Correspond à l'erreur du trigger lié au salaire du chef de service
             RAISE_APPLICATION_ERROR(-20110, 'Le chef de service doit gagner plus que les employés de son service.');
          ELSE
             RAISE_APPLICATION_ERROR(-20999, 'Erreur inconnue : ' || SQLERRM);
          END IF;
    END AJOUTER_SERVICE;
```

| Code erreur Oracle | Code erreur retourné | Message d'erreur personnalisé                                               |
|--------------------|----------------------|------------------------------------------------------------------------------|
| ORA-20009          | -20110               | Le chef de service doit gagner plus que les employés de son service.          |
| ORA-20999          | -20999               | Erreur inconnue : Erreur non prévue capturée dans la procédure.               |

### Justification :
- La table service, avec sa clé étrangère sur la table employe, nécessite une gestion stricte pour assurer que les chefs de service sont correctement assignés. La procédure AJOUTER_SERVICE en TD3 tient compte de cela, en vérifiant qu’un chef de service est correctement affecté et en mettant à jour l’employé concerné.
- Le TD2 introduit des triggers comme check_chef_salaire, qui garantit qu’un chef de service gagne plus que ses subordonnés. La procédure AJOUTER_SERVICE en TD3 reprend cette logique en vérifiant et en gérant les salaires des chefs de service lors de l’affectation.

# Annexe
## TD1
### Introduction
Ce TP de SQL porte sur la création, la gestion et l'interrogation de tables dans un système de base de 
données pour la gestion des employés. La base de données suit les informations relatives aux employés, 
services, projets, et aux relations entre eux, comme les projets sur lesquels travaillent les employés et les 
services responsables de ces projets.

### Tables utilisées :
- employe : Stocke les informations sur les employés.
- service : Stocke les informations sur les services ou départements.
- projet : Stocke les informations sur les projets.
- travail : Suit l'implication des employés dans les projets, y compris la durée du travail.
- concerne : Suit les services responsables de chaque projet. 

### Partie 1 : Création des tables et contraintes
#### Étape 1 : Création des tables
Les tables suivantes ont été créées en se basant sur les données existantes du schéma basetd :

```sql
CREATE TABLE employe AS SELECT * FROM basetd.employe;
CREATE TABLE service AS SELECT * FROM basetd.service;
CREATE TABLE projet AS SELECT * FROM basetd.projet;
CREATE TABLE travail AS SELECT * FROM basetd.travail;
CREATE TABLE concerne AS SELECT * FROM basetd.concerne;
```

#### Étape 2 : Ajout des clés primaires et des clés étrangères
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

#### Étape 3 : Insertion et suppression de données
Des données d'exemple ont été insérées dans les tables et certaines lignes ont été supprimées pour simuler 
des opérations réelles :

```sql
INSERT INTO employe VALUES (12, 'marcel', 35, 39);
INSERT INTO service VALUES (6, 'compta', 200);
INSERT INTO projet VALUES (1, 'projet1', 200);
DELETE FROM employe WHERE NUEMPL = 30;
DELETE FROM service WHERE NUSERV = 3;
```

#### Étape 4 : Ajout d'une nouvelle colonne pour les salaires
Une nouvelle colonne salaire a été ajoutée à la table employe pour stocker les salaires des employés :

```sql
ALTER TABLE employe ADD salaire NUMBER;
```

### Partie 2 : Manipulation des données et requêtes
#### 2.a : Mise à jour des salaires des employés
Les salaires des employés ont été mis à jour en fonction de leur rôle (responsables de projets ou chefs de service) :

```sql
UPDATE employe SET salaire = 2500 WHERE NUEMPL IN (SELECT RESP FROM projet);
UPDATE employe SET salaire = 3500 WHERE NUEMPL IN (SELECT chef FROM service);
UPDATE employe SET salaire = 1999 WHERE NUEMPL NOT IN (SELECT RESP FROM projet) AND NUEMPL NOT IN (SELECT chef FROM service);
```

#### 2.b : Identification des employés surchargés
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

### Partie 3 : Contraintes liées aux projets et services
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

### Conclusion
Ce TP s'est concentré sur la création d'un système de base de données robuste pour la gestion des informations sur les employés et les projets, tout en garantissant l'intégrité des données grâce à des contraintes. En outre, des requêtes SQL ont été utilisées pour gérer et mettre à jour les données dans un scénario réaliste, incluant l'équilibrage des charges de travail et l'ajustement des salaires.

## TD2 : TRIGGER

*Liste des triggers*

| Nom Trigger                | Type : before ou after | Insert, delete, update | Nom table | For each row : oui ou non |
|----------------------------|------------------------|------------------------|-----------|---------------------------|
| empecher_diminution_salaire | after                  | update                 | employe   | oui                       |
| empecher_augmentation_hebdo | after                  | update                 | employe   | oui                       |
| supprimer_employe           | before                 | delete                 | employe   | non                       |
| supprimer_projet            | before                 | delete                 | projet    | non                       |
| check_duree_insert          | before                 | insert                 | travail   | oui                       |
| check_duree_update          | before & after         | update                 | travail   | oui                       |
| check_hebdo_update          | before                 | update                 | employe   | oui                       |
| check_responsable_projets   | before                 | insert & update        | projet    | oui                       |
| check_service_projets       | before                 | insert & update        | concerne  | oui                       |
| check_chef_salaire          | before                 | insert & update        | employe   | oui                       |
| alerte_salaire              | before                 | insert & update        | employe   | oui                       |


#### Exercice 1 :

**A. Jeux d'essai pour le trigger empecher_diminution_salaire**

*Trigger :*
```sql
CREATE OR REPLACE TRIGGER empecher_diminution_salaire
AFTER UPDATE OF salaire ON employe
FOR EACH ROW
BEGIN
    IF :NEW.salaire < :OLD.salaire THEN
        RAISE_APPLICATION_ERROR(-20001, 'Vous ne pouvez pas diminuier le salaire de l''employer');
    END IF;
END;
```
*Cas de test pour déclancher le trigger :*
```sql
UPDATE employe SET salaire = salaire - 100 WHERE NUEMPL = 20;
```

Résultat attendu : Une erreur est déclenchée car le salaire ne peut pas être diminué.

**B. Jeux d'essai pour le trigger empecher_augmentation_hebdo**

*Trigger :*
```sql
CREATE OR REPLACE TRIGGER empecher_augmentation_hebdo
AFTER UPDATE OF HEBDO ON employe
FOR EACH ROW
BEGIN
    IF :NEW.HEBDO > :OLD.HEBDO THEN
        RAISE_APPLICATION_ERROR(-20002, 'Vous ne pouvez pas augmenter la durée hebdomadaire de l''employé');
    END IF;
END;
```

*Cas de test pour déclancher le trigger :*

```sql
UPDATE employe SET HEBDO = HEBDO + 1 WHERE NUEMPL = 20;
```
Résultat attendu : Une erreur est déclenchée car la durée hebdomadaire ne peut pas être augmentée.

#### Exercice 2 :
**A. Cas où la suppression de l'employé est interdite :**

*Trigger :*
```sql
CREATE OR REPLACE TRIGGER supprimer_employe
BEFORE DELETE ON employe
DECLARE
    v_deleted_count NUMBER;
BEGIN
    -- Supprimer les lignes correspondantes dans la table travail
    -- seulement si l'employé n'est ni responsable de projet ni chef de service
    DELETE FROM travail
    WHERE NUEMPL IN (SELECT NUEMPL FROM employe) -- L'employé doit exister dans la table employe
    AND NUEMPL NOT IN (SELECT RESP FROM projet) -- Pas responsable de projet
    AND NUEMPL NOT IN (SELECT CHEF FROM service); -- Pas chef de service

    -- Vérifier combien de lignes ont été supprimées
    v_deleted_count := SQL%ROWCOUNT;

    -- Si aucune ligne n'a été supprimée, lever une exception
    IF v_deleted_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Aucune ligne n''a été supprimée car l''employé est soit chef de projet soit chef de service, ou n''a pas de travail associé.');
    END IF;
END;
```

*Cas de test pour déclancher le trigger :*
```sql
DELETE FROM employe WHERE NUEMPL = 41;
```
Résultat attendu : Une erreur est déclenchée car l'employé est chef de service.

*Cas de test pour déclancher le trigger :*
```sql
DELETE FROM employe WHERE NUEMPL = 30;
```
Résultat attendu : Une erreur est déclenchée car l'employé est responsable d'un projet.

**B. Vérifier les données avant la suppression du projet :**

*Trigger :*
```sql
CREATE OR REPLACE TRIGGER supprimer_projet
BEFORE DELETE ON projet
DECLARE
    v_deleted_count_travail NUMBER;
    v_deleted_count_concerne NUMBER;
BEGIN
    -- Supprimer les lignes dans la table travail où le projet n'existe plus dans la table projet
    DELETE FROM travail
    WHERE NUPROJ NOT IN (SELECT NUPROJ FROM projet);

    -- Enregistrer le nombre de lignes supprimées dans travail
    v_deleted_count_travail := SQL%ROWCOUNT;

    -- Supprimer les lignes dans la table concerne où le projet n'existe plus dans la table projet
    DELETE FROM concerne
    WHERE NUPROJ NOT IN (SELECT NUPROJ FROM projet);

    -- Enregistrer le nombre de lignes supprimées dans concerne
    v_deleted_count_concerne := SQL%ROWCOUNT;

    -- Optionnel: lever une erreur si aucune ligne n'a été supprimée
    IF v_deleted_count_travail = 0 AND v_deleted_count_concerne = 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Aucune ligne supprimée dans travail ou concerne pour ce projet.');
    END IF;
END;
```

*Cas de test pour déclancher le trigger :*

*Suppression d'un projet (par exemple, Projet 1)*
```sql
DELETE FROM projet WHERE NUPROJ = 1;
```

*Vérification des suppressions dans les autres tables*
*Devrait retourner 0 ligne*
```sql
SELECT * FROM travail WHERE NUPROJ = 1; 
SELECT * FROM concerne WHERE NUPROJ = 1; 
```
Résultat attendu : Les lignes associées au projet supprimé sont également supprimées dans les tables travail et concerne.

#### Exercice 3 :
**A - La somme des durées de travail d'un
employé ne doit pas excéder son temps de travail hebdomadaire**

Pour vérifier la contrainte **SUM(duree) <= hebdo**, nous devons mettre en place des triggers qui se déclenchent lors des opérations INSERT et UPDATE sur les tables employe et travail.

**Opérations sur la table travail :**

* INSERT : Lorsqu'une nouvelle ligne est insérée dans la table travail, nous devons vérifier que la somme des durées de travail de l'employé ne dépasse pas son temps de travail hebdomadaire.
* UPDATE : Lorsqu'une ligne existante est mise à jour dans la table travail, nous devons vérifier que la somme des durées de travail de l'employé ne dépasse pas son temps de travail hebdomadaire.
Opérations sur la table employe :
* UPDATE : Lorsqu'un employé met à jour son temps de travail hebdomadaire (hebdo), nous devons vérifier que la somme des durées de travail de l'employé ne dépasse pas son nouveau temps de travail hebdomadaire.

*Triggers :*
```sql
CREATE OR REPLACE TRIGGER check_duree_insert
BEFORE INSERT ON travail
FOR EACH ROW
DECLARE
    v_sum_duree NUMBER;
    v_hebdo employe.hebdo%TYPE;
BEGIN
    -- Calculer la somme des durées pour l'employé
    SELECT SUM(duree) INTO v_sum_duree
    FROM travail
    WHERE nuempl = :NEW.nuempl;

    -- Ajouter la nouvelle durée
    v_sum_duree := v_sum_duree + :NEW.duree;

    -- Obtenir le temps de travail hebdomadaire de l'employé
    SELECT hebdo INTO v_hebdo
    FROM employe
    WHERE nuempl = :NEW.nuempl;

    -- Vérifier si la somme des durées dépasse le temps de travail hebdomadaire
    IF v_sum_duree > v_hebdo THEN
        RAISE_APPLICATION_ERROR(-20005, 'La somme des durées de travail dépasse le temps de travail hebdomadaire.');
    END IF;
END;
```

```sql
CREATE OR REPLACE TRIGGER check_duree_update
FOR UPDATE ON travail
COMPOUND TRIGGER

    -- Variable to hold the sum of durations for each employee
    TYPE emp_duree_type IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    emp_duree emp_duree_type;

    -- Before each row is updated
    BEFORE EACH ROW IS
    BEGIN
        -- Initialize or reset the sum for the employee if it's the first row being processed
        IF emp_duree.EXISTS(:NEW.nuempl) THEN
            emp_duree(:NEW.nuempl) := emp_duree(:NEW.nuempl) + :NEW.duree - NVL(:OLD.duree, 0);
        ELSE
            emp_duree(:NEW.nuempl) := :NEW.duree;
        END IF;
    END BEFORE EACH ROW;

    -- After the entire statement (to avoid mutating table error)
    AFTER STATEMENT IS
        v_hebdo employe.hebdo%TYPE;
        v_sum_duree NUMBER;
    BEGIN
        -- Loop through each employee whose records were modified
        FOR indx IN emp_duree.FIRST..emp_duree.LAST LOOP
            -- Get the weekly limit for the employee
            SELECT hebdo INTO v_hebdo
            FROM employe
            WHERE nuempl = indx;

            -- Get the total duration for the employee from the table (now allowed after the mutation phase)
            SELECT SUM(duree) INTO v_sum_duree
            FROM travail
            WHERE nuempl = indx;

            -- Check if the sum of durations exceeds the weekly limit
            IF v_sum_duree > v_hebdo THEN
                RAISE_APPLICATION_ERROR(-20006, 'La somme des durées de travail dépasse le temps de travail hebdomadaire pour l''employé ' || indx || '.');
            END IF;
        END LOOP;
    END AFTER STATEMENT;

END check_duree_update;
```

```sql
CREATE OR REPLACE TRIGGER check_hebdo_update
BEFORE UPDATE OF hebdo ON employe
FOR EACH ROW
DECLARE
    v_sum_duree NUMBER;
BEGIN
    -- Calculer la somme des durées pour l'employé
    SELECT SUM(duree) INTO v_sum_duree
    FROM travail
    WHERE nuempl = :NEW.nuempl;

    -- Vérifier si la somme des durées dépasse le nouveau temps de travail hebdomadaire
    IF v_sum_duree > :NEW.hebdo THEN
        RAISE_APPLICATION_ERROR(-20007, 'La somme des durées de travail dépasse le nouveau temps de travail hebdomadaire.');
    END IF;
END;
```

*Cas de test pour déclancher le trigger :*
```sql
INSERT INTO travail VALUES (20, 237, 90);
```
Résultat attendu : Une erreur est déclenchée car la somme des durées de travail dépasse le temps de travail hebdomadaire.


```sql
UPDATE travail SET DUREE = 99 WHERE NUEMPL = 20 AND NUPROJ = 492;
```

Résultat attendu : Une erreur est déclenchée car la somme des durées de travail dépasse le temps de travail hebdomadaire.


```sql
UPDATE employe SET HEBDO = 5 WHERE NUEMPL = 20;
```
Résultat attendu : Une erreur est déclenchée car la somme des durées de travail dépasse le nouveau temps de travail hebdomadaire.

**B. Un employé est responable au plus sur 3 projets**

*Trigger :*

```sql
CREATE OR REPLACE TRIGGER check_responsable_projets
BEFORE INSERT OR UPDATE OF resp ON projet
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Calculer le nombre de projets pour lesquels l'employé est responsable
    SELECT COUNT(*)
    INTO v_count
    FROM projet
    WHERE resp = :NEW.resp;

    -- Ajouter le nouveau projet si c'est une insertion
    IF INSERTING THEN
        v_count := v_count + 1;
    END IF;

    -- Vérifier si le nombre de projets dépasse 3
    IF v_count > 3 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Un employé ne peut pas être responsable de plus de 3 projets.');
    END IF;
END;
```

*Insertion d'un projet :*
```sql
INSERT INTO PROJET VALUES (103, 'Projet 103', 30);
```

**C - Un service ne peut être concerné par plus de 3 projets**

*Trigger :*
```sql
CREATE OR REPLACE TRIGGER check_service_projets
BEFORE INSERT OR UPDATE OF NUSERV ON concerne
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Calculer le nombre de projets pour lesquels le service est concerné
    SELECT COUNT(*)
    INTO v_count
    FROM concerne
    WHERE NUSERV = :NEW.NUSERV;

    -- Ajouter le nouveau projet si c'est une insertion
    IF INSERTING THEN
        v_count := v_count + 1;
    END IF;

    -- Vérifier si le nombre de projets dépasse 3
    IF v_count > 3 THEN
        RAISE_APPLICATION_ERROR(-20009, 'Un service ne peut être concerné par plus de 3 projets.');
    END IF;
END;
```

*Insertion d'une association de projet avec un service :*
```sql
INSERT INTO CONCERNE VALUES (1, 492);
INSERT INTO CONCERNE VALUES (1, 160);
```
Résultat attendu : Le projet est bien associé au service.

**D - un chef de service gagne plus que
les employés de son service**

```sql
CREATE OR REPLACE TRIGGER trg_check_salaire_chef_service
AFTER INSERT OR UPDATE OF salaire ON employe

DECLARE
    ligne_chef employe%ROWTYPE;
BEGIN
    -- Rechercher les chefs de service gagnant moins que les employés de leur service
    SELECT * INTO ligne_chef
    FROM employe e
    WHERE e.salaire <= (SELECT MAX(salaire) FROM employe emp WHERE emp.affect = e.affect AND emp.nuempl != e.nuempl)
    AND EXISTS (SELECT 1 FROM service s WHERE s.chef = e.nuempl);

    -- Lever une exception si un enregistrement est trouvé
    RAISE_APPLICATION_ERROR(-20009, 'Le chef de service doit gagner plus que les employés de son service.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;  -- Aucune violation trouvée
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20010, 'Plusieurs chefs de service gagnent moins que leurs employés.');
END;
```

**E - un chef de service gagne plus que
les employés responsables de projets**

**F - Est-il possible de regrouper les deux derniers trigger**

#### Exercice 5 :
**A. Trigger alerte_salaire**

*Trigger :*
```sql
CREATE OR REPLACE TRIGGER alerte_salaire
BEFORE INSERT OR UPDATE OF salaire ON employe
FOR EACH ROW
BEGIN
    IF :NEW.SALAIRE > 5000 THEN
        INSERT INTO employe_alerte
        VALUES (:NEW.NUEMPL, :NEW.NOMEMPL, :NEW.HEBDO, :NEW.AFFECT, :NEW.SALAIRE);

    END IF;
END;
```

Ce trigger insère une ligne dans la table employe_alerte lorsque le salaire d'un employé dépasse 5000.

```sql
INSERT INTO employe (NUEMPL, NOMEMPL, HEBDO, AFFECT, SALAIRE)
VALUES (50, 'Dupont', 35, 1, 6000);
```

Résultat attendu : Une nouvelle ligne est ajoutée dans la table employe_alerte pour cet employé.






