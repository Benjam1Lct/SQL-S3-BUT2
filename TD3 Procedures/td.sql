

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
/

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

   PROCEDURE MODIFIER_DUREE_HEBDO(LE_NUEMPL IN NUMBER, LA_NOUVELLE_DUREE IN NUMBER) IS
   BEGIN
      UPDATE employe
      SET hebdo = LA_NOUVELLE_DUREE
      WHERE nuempl = LE_NUEMPL;

      IF SQL%NOTFOUND THEN
         RAISE_APPLICATION_ERROR(-20101, 'Aucun employé trouvé avec ce numéro.');
      END IF;

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

--------------------------------------------------------------------------------------------------------------

       PROCEDURE MODIFIER_SALAIRE(LE_NUEMPL IN NUMBER, LE_NOUVEAU_SALAIRE IN NUMBER) IS
   BEGIN

       IF SQL%NOTFOUND THEN
         RAISE_APPLICATION_ERROR(-20101, 'Aucun employé trouvé avec ce numéro.');
      END IF;


      UPDATE employe
      SET salaire = LE_NOUVEAU_SALAIRE
      WHERE nuempl = LE_NUEMPL;



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

--------------------------------------------------------------------------------------------------------------


    PROCEDURE MODIFIER_DUREE_TRAVAIL(LE_NUEMPL IN NUMBER, LE_NUPROJ IN NUMBER, LA_NOUVELLE_DUREE IN NUMBER) IS
   BEGIN
      UPDATE travail
      SET duree = LA_NOUVELLE_DUREE
      WHERE nuempl = LE_NUEMPL AND nuproj = LE_NUPROJ;

      IF SQL%NOTFOUND THEN
         RAISE_APPLICATION_ERROR(-20105, 'Aucun enregistrement trouvé pour cet employé et projet.');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         IF SQLCODE = -20003 THEN
            -- Correspond à l'erreur du trigger supprimer_employe
            RAISE_APPLICATION_ERROR(-20106, 'Erreur lors de la suppression de l\''employé : ' || SQLERRM);
         ELSE
            RAISE_APPLICATION_ERROR(-20999, 'Erreur inconnue : ' || SQLERRM);
         END IF;
   END MODIFIER_DUREE_TRAVAIL;

--------------------------------------------------------------------------------------------------------------

       PROCEDURE INSERER_TRAVAIL(LE_NUEMPL IN NUMBER, LE_NUPROJ IN NUMBER, LA_DUREE IN NUMBER) IS
   BEGIN
      INSERT INTO travail (nuempl, nuproj, duree)
      VALUES (LE_NUEMPL, LE_NUPROJ, LA_DUREE);

      IF SQL%ROWCOUNT = 0 THEN
         RAISE_APPLICATION_ERROR(-20107, 'Insertion échouée pour cet employé et projet.');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         IF SQLCODE = -20009 THEN
            -- Correspond à l'erreur du trigger limitant le nombre de projets d'un service
            RAISE_APPLICATION_ERROR(-20108, 'Un service ne peut être concerné par plus de 3 projets.');
         ELSE
                RAISE_APPLICATION_ERROR(-20999, 'Erreur inconnue : ' || SQLERRM);
         END IF;
   END INSERER_TRAVAIL;

--------------------------------------------------------------------------------------------------------------


       PROCEDURE AJOUTER_SERVICE(LE_NUSERV IN NUMBER, LE_NOMSERV IN VARCHAR2, LE_CHEF IN NUMBER) IS
   BEGIN
      INSERT INTO service (nuserv, nomserv, chef)
      VALUES (LE_NUSERV,LE_NOMSERV, LE_CHEF);

      -- Mise à jour de l'employé pour l'affecter comme chef de service
      UPDATE employe
      SET affect = LE_NUSERV
      WHERE nuempl = LE_CHEF;

      IF SQL%NOTFOUND THEN
         RAISE_APPLICATION_ERROR(-20109, 'Aucun employé trouvé pour être affecté comme chef.');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         IF SQLCODE = -20009 THEN
            -- Correspond à l'erreur du trigger lié au salaire du chef de service
            RAISE_APPLICATION_ERROR(-20110, 'Le chef de service doit gagner plus que les employés de son service.');
         ELSE
            RAISE_APPLICATION_ERROR(-20999, 'Erreur inconnue : ' || SQLERRM);
         END IF;
   END AJOUTER_SERVICE;
END MAJ;
/

BEGIN
   MAJ.CREER_EMPLOYE(103, 'Pol8', 35, 5, 1999);
END;
/

BEGIN
   MAJ.MODIFIER_SALAIRE(1, 35);  -- Il n'y a pas d'employé
END;
/
BEGIN
   MAJ.MODIFIER_DUREE_HEBDO(17, 30);  -- Ca fonctionne
END;
/
BEGIN
   MAJ.MODIFIER_DUREE_HEBDO(17, 45);  -- C'est interdit
END;
/
BEGIN
   MAJ.MODIFIER_DUREE_HEBDO(23, 15);  -- C'est interdit
END;
/


BEGIN
   MAJ.MODIFIER_SALAIRE(1, 4000);  -- Employé n'existe pas
END;
/
BEGIN
   MAJ.MODIFIER_SALAIRE(17, 1999);  -- C'est interdit
END;
/
BEGIN
   MAJ.MODIFIER_SALAIRE(42, 30000);  -- C'est interdit
END;







