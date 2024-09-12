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

-- Jeux d'essai pour le trigger empecher_diminution_salaire
-- Cas où la diminution du salaire est interdite
UPDATE employe
SET salaire = salaire - 100
WHERE NUEMPL = 20;


-- Jeux d'essai pour le trigger empecher_augmentation_hebdo
-- Cas où l'augmentation de la durée hebdomadaire est interdite
UPDATE employe
SET HEBDO = HEBDO + 1
WHERE NUEMPL = 20;


CREATE OR REPLACE TRIGGER supprimer_employe
BEFORE DELETE ON employe
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Vérifier si l'employé est chef de service
    SELECT COUNT(*)
    INTO v_count
    FROM service
    WHERE chef = :OLD.NUEMPL;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Impossible de supprimer l''employé car il est chef de service.');
    END IF;

    -- Vérifier si l'employé est responsable de projet
    SELECT COUNT(*)
    INTO v_count
    FROM projet
    WHERE RESP = :OLD.NUEMPL;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Impossible de supprimer l''employé car il est responsable de projet.');
    END IF;

    -- Supprimer les lignes correspondantes dans la table travail
    DELETE FROM travail
    WHERE NUEMPL = :OLD.NUEMPL;
END;

-- Cas où la suppression de l'employé est interdite car il est chef de service
DELETE FROM employe WHERE NUEMPL = 41;

-- Cas où la suppression de l'employé est interdite car il est responsable de projet
DELETE FROM employe WHERE NUEMPL = 30;


-- Supprimer les contraintes existantes
ALTER TABLE travail DROP CONSTRAINT FK_projet_travail;
ALTER TABLE concerne DROP CONSTRAINT FK_projet_concerne;

-- Recréer les contraintes avec l'option DEFERRABLE INITIALLY DEFERRED
ALTER TABLE travail ADD CONSTRAINT FK_projet_travail FOREIGN KEY (NUPROJ) REFERENCES projet(NUPROJ) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE concerne ADD CONSTRAINT FK_projet_concerne FOREIGN KEY (NUPROJ) REFERENCES projet(NUPROJ) DEFERRABLE INITIALLY DEFERRED;


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

-- Vérifier les données avant la suppression
SELECT * FROM projet WHERE NUPROJ = 103;
SELECT * FROM travail WHERE NUPROJ = 103;
SELECT * FROM concerne WHERE NUPROJ = 103;

-- Supprimer le projet
DELETE FROM projet WHERE NUPROJ = 103;

-- Vérifier les données après la suppression
SELECT * FROM projet WHERE NUPROJ = 103;
SELECT * FROM travail WHERE NUPROJ = 103;
SELECT * FROM concerne WHERE NUPROJ = 103;


