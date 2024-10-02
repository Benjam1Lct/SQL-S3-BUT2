-- exercice 1 question A
CREATE OR REPLACE TRIGGER empecher_diminution_salaire
AFTER UPDATE OF salaire ON employe
FOR EACH ROW
BEGIN
    IF :NEW.salaire < :OLD.salaire THEN
        RAISE_APPLICATION_ERROR(-20001, 'Vous ne pouvez pas diminuier le salaire de l''employer');
    END IF;
END;

-- Jeux d'essai pour le trigger empecher_diminution_salaire
-- Cas où la diminution du salaire est interdite
UPDATE employe SET salaire = salaire - 100 WHERE NUEMPL = 20;


-- exercice 1 question B
CREATE OR REPLACE TRIGGER empecher_augmentation_hebdo
AFTER UPDATE OF HEBDO ON employe
FOR EACH ROW
BEGIN
    IF :NEW.HEBDO > :OLD.HEBDO THEN
        RAISE_APPLICATION_ERROR(-20002, 'Vous ne pouvez pas augmenter la durée hebdomadaire de l''employé');
    END IF;
END;

-- Jeux d'essai pour le trigger empecher_augmentation_hebdo
-- Cas où l'augmentation de la durée hebdomadaire est interdite
UPDATE employe SET HEBDO = HEBDO + 1 WHERE NUEMPL = 20;

-- exercice 2 question A
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
        RAISE_APPLICATION_ERROR(-20003, 'Aucune ligne n''a été supprimée car l''employé est soit chef de projet soit chef de service, ou n''a pas de travail associé.');
    END IF;
END;


-- Cas où la suppression de l'employé est interdite car il est chef de service
DELETE FROM employe WHERE NUEMPL = 41;

-- Cas où la suppression de l'employé est interdite car il est responsable de projet
DELETE FROM employe WHERE NUEMPL = 30;
DELETE FROM employe WHERE NUEMPL = 14;

-- exercice 2 question B
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
        RAISE_APPLICATION_ERROR(-20004, 'Aucune ligne supprimée dans travail ou concerne pour ce projet.');
    END IF;
END;

-- Suppression d'un projet (par exemple, Projet Alpha)
DELETE FROM projet WHERE NUPROJ = 1;

-- Vérification des suppressions dans les autres tables
SELECT * FROM travail WHERE NUPROJ = 1;  -- Devrait retourner 0 ligne
SELECT * FROM concerne WHERE NUPROJ = 1;  -- Devrait retourner 0 ligne


-- exercice 3 question A
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
/


-- exercice 3 question A
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
/

-- exercice 3 question A
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
/

INSERT INTO TRAVAIL VALUES (20, 237, 90);

UPDATE travail
SET DUREE = 99
WHERE NUEMPL = 20 AND NUPROJ = 492;

UPDATE employe
SET HEBDO = 5
WHERE NUEMPL = 20;


-- exercice 3 question B
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
/

INSERT INTO PROJET VALUES (103, 'Projet 103', 30);

-- exercice 3 question C
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
/

INSERT INTO CONCERNE VALUES (1, 492);
INSERT INTO CONCERNE VALUES (1, 160);

-- exercice 3 question D
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
/



-- exercice 4
CREATE TABLE employe_alerte AS
SELECT *
FROM employe
WHERE 1 = 0;

CREATE OR REPLACE TRIGGER alerte_salaire
BEFORE INSERT OR UPDATE OF salaire ON employe
FOR EACH ROW
BEGIN
    IF :NEW.SALAIRE > 5000 THEN
        INSERT INTO employe_alerte
        VALUES (:NEW.NUEMPL, :NEW.NOMEMPL, :NEW.HEBDO, :NEW.AFFECT, :NEW.SALAIRE);

    END IF;
END;
/


update employe set salaire = 20000 where NUEMPL = 41;



