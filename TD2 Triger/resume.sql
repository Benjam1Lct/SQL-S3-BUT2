CREATE OR REPLACE TRIGGER empecher_diminution_salaire
AFTER UPDATE OF salaire ON employe
FOR EACH ROW
BEGIN
    IF :NEW.salaire < :OLD.salaire THEN
        RAISE_APPLICATION_ERROR(-20001, 'Vous ne pouvez pas diminuier le salaire de l''employer');
    END IF;
END;

CREATE OR REPLACE TRIGGER empecher_augmentation_hebdo
AFTER UPDATE OF HEBDO ON employe
FOR EACH ROW
BEGIN
    IF :NEW.HEBDO > :OLD.HEBDO THEN
        RAISE_APPLICATION_ERROR(-20002, 'Vous ne pouvez pas augmenter la durée hebdomadaire de l''employé');
    END IF;
END;

CREATE OR REPLACE TRIGGER supprimer_employe
BEFORE DELETE ON employe
DECLARE
    v_deleted_count NUMBER;
BEGIN
    -- Supprimer les lignes dans la table travail
    DELETE FROM travail
    WHERE NUEMPL IN (
        SELECT NUEMPL
        FROM employe
        WHERE NUEMPL NOT IN (SELECT RESP FROM projet)
        AND NUEMPL NOT IN (SELECT CHEF FROM service)
    );

    -- Vérifier combien de lignes ont été supprimées
    v_deleted_count := SQL%ROWCOUNT;

    -- Si aucune ligne n'a été supprimée, lever une exception
    IF v_deleted_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Aucune ligne n''a été supprimée dans la table travail.');
    END IF;
END;


DELETE FROM employe WHERE NUEMPL = 71;


CREATE OR REPLACE TRIGGER supprimer_projet
BEFORE DELETE ON projet
FOR EACH ROW
BEGIN
    -- Supprimer les lignes correspondantes dans la table travail
    DELETE FROM travail
    WHERE NUPROJ = :OLD.NUPROJ;

    -- Supprimer les lignes correspondantes dans la table concerne
    DELETE FROM concerne
    WHERE NUPROJ = :OLD.NUPROJ;
END;



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



CREATE OR REPLACE TRIGGER check_chef_salaire
BEFORE INSERT OR UPDATE OF salaire ON employe
FOR EACH ROW
DECLARE
    v_max_salaire_service NUMBER;
    v_max_salaire_projet NUMBER;
    v_nuserv NUMBER;
BEGIN
    -- Vérifier si l'employé est un chef de service
    SELECT COUNT(*) INTO v_nuserv FROM service WHERE chef = :NEW.NUEMPL;
    IF v_nuserv > 0 THEN
        -- Obtenir le numéro de service du chef
        SELECT NUSERV INTO v_nuserv FROM service WHERE chef = :NEW.NUEMPL;

        -- Obtenir le salaire maximum des employés du service
        SELECT MAX(salaire) INTO v_max_salaire_service
        FROM employe
        WHERE AFFECT = v_nuserv AND NUEMPL != :NEW.NUEMPL;

        -- Obtenir le salaire maximum des employés responsables de projets
        SELECT MAX(e.salaire) INTO v_max_salaire_projet
        FROM employe e
        JOIN projet p ON e.NUEMPL = p.RESP
        WHERE e.NUEMPL != :NEW.NUEMPL;

        -- Vérifier si le salaire du chef est supérieur aux salaires maximums
        IF :NEW.salaire <= v_max_salaire_service OR :NEW.salaire <= v_max_salaire_projet THEN
            RAISE_APPLICATION_ERROR(-20010, 'Le chef de service doit gagner plus que les employés de son service et les employés responsables de projets.');
        END IF;
    END IF;
END ;



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