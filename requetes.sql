
-- Organization : 
-- Vérifier que le théâtre qui accueille la représentation à une date donnée 
-- n'a pas déjà d'autre représentation à cette date
CREATE TRIGGER insertionRepresentation
   BEFORE INSERT ON REPRESENTATION
   FOR EACH ROW
DECLARE 
    nb NUMBER;
    insertException EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO nb
    FROM REPRESENTATION
    WHERE idTheaterHall = :NEW.idTheaterHall
    AND dat = :NEW.dat
    GROUP BY (idTheaterHall, dat); 
    IF (nb = 1) THEN
        RAISE insertException;
    END IF;
EXCEPTION 
    WHEN insertException THEN 
        raise_application_error(-20001,'Insertion impossible, il y a déjà une représentation dans cette salle ce jour');
END;


-- Vérifier que la compagnie n'a pas déjà programmé un spectacle dans une autre salle
CREATE TRIGGER insertionRepresentation2
   BEFORE INSERT ON REPRESENTATION
   FOR EACH ROW
DECLARE 
    nb NUMBER;
    insertException EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO nb
    FROM REPRESENTATION
    WHERE idShow = :NEW.idShow
    AND idTheaterCompany = :NEW.idTheaterCompany
    AND dat = :NEW.dat
    GROUP BY (idShow, idTheaterCompany, dat);
    IF (nb = 1) THEN
        RAISE insertException;
    END IF;
EXCEPTION 
    WHEN insertException THEN 
        raise_application_error(-20002,'Insertion impossible, il y a déjà une représentation de ce spectacle ce jour');
END;


-- What is the set of cities in which a company plays for a certain time period ?
-- Afficher les différentes villes dans lesquelles joue une compagnie de théâtre durant une période de temps donnée.
CREATE OR REPLACE PROCEDURE 
setOfCities(nametheater VARCHAR2, dateshow1 DATE, dateshow2 DATE) IS
BEGIN
    DECLARE
        CURSOR cities IS
            SELECT 
                tc.labelTheater
                ,th.cityHall
                ,r.dat
                ,s.labelShow
            FROM REPRESENTATION r
            JOIN THEATER_HALL th ON r.idTheaterHall = th.idTheater
            JOIN SHOWS s ON r.idShow = s.idShow AND r.idTheaterCompany = s.idTheater
            JOIN THEATER_COMPANY tc ON s.idTheater = tc.idTheater
            WHERE tc.labelTheater = nametheater
            AND r.dat BETWEEN dateshow1 AND dateshow2
            GROUP BY tc.labelTheater, th.cityHall, r.dat, s.labelShow;
    BEGIN
        FOR city IN cities LOOP
            DBMS_OUTPUT.PUT_LINE('La ville où joue la compagnie ' || city.labelTheater || ' à la date ' || city.dat 
                || ' est : ' || city.cityHall || ' . Le spectacle joué est : ' || city.labelShow);
            EXIT WHEN cities%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    setOfCities('Temple Solaire', '29-02-2012', '17-04-2021');
END;


-- Ticketing : 
-- What are the ticket prices today ? 
-- Afficher les tarifs des prix des tickets vendus du jour
CREATE OR REPLACE PROCEDURE 
ticketPriceToday(dateshow DATE) IS
BEGIN
    DECLARE
        CURSOR tickets IS
            SELECT priceTicket
            FROM TICKET_SHOW
            WHERE dat = dateshow
            ORDER BY priceTicket DESC;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Les prix des tickets du jour sont : ');
        FOR ticket IN tickets LOOP
            DBMS_OUTPUT.PUT_LINE(ticket.priceTicket);
            EXIT WHEN tickets%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    ticketPriceToday('30-08-2021');
END;


-- For each representation, what is the distribution of tickets by price ?
-- Afficher la distribution des tickets des différentes représentations par prix
CREATE OR REPLACE PROCEDURE 
ticketPriceDistribution IS
BEGIN
    DECLARE
        CURSOR tickets IS
            SELECT 
                s.labelShow
                ,tc.labelTheater
                ,ts.dat
                ,ts.priceTicket
                ,COUNT(ts.idTicket) AS distrib
            FROM TICKET_SHOW ts 
            JOIN TICKETS t ON ts.idTicket = t.idTicket AND ts.idShow = t.idShow AND ts.idTheaterCompany = t.idTheater
            JOIN SHOWS s ON t.idShow = s.idShow AND t.idTheater = s.idTheater
            JOIN THEATER_COMPANY tc ON s.idTheater = tc.idTheater
            GROUP BY s.labelShow, tc.labelTheater, ts.dat, ts.priceTicket 
            ORDER BY (s.labelShow) DESC, ts.priceTicket DESC;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('La distribution par prix des tickets des différentes représentations est la suivante : ');
        FOR ticket IN tickets LOOP
            DBMS_OUTPUT.PUT_LINE(ticket.labelShow || ', ' || ticket.labelTheater || ', à la date du ' || ticket.dat || ', au prix de ' || ticket.priceTicket || 
            ' : ' || ticket.distrib || ' places vendue(s) ');
            EXIT WHEN tickets%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    ticketPriceDistribution;
END;


-- For each representation, what is the distribution of tickets by tarif ? 
-- Afficher la distribution des tickets des différentes représentations par type de tarif
CREATE OR REPLACE PROCEDURE 
labelPriceDistribution IS
BEGIN
    DECLARE
        CURSOR tickets IS
            SELECT 
                s.labelShow
                ,tc.labelTheater
                ,ts.dat
                ,t.labelTicket
                ,COUNT(ts.idTicket) AS distrib
            FROM TICKET_SHOW ts 
            JOIN TICKETS t ON ts.idTicket = t.idTicket AND ts.idShow = t.idShow AND ts.idTheaterCompany = t.idTheater
            JOIN SHOWS s ON t.idShow = s.idShow AND t.idTheater = s.idTheater
            JOIN THEATER_COMPANY tc ON s.idTheater = tc.idTheater
            GROUP BY s.labelShow, tc.labelTheater, ts.dat, t.labelTicket 
            ORDER BY (s.labelShow) DESC, t.labelTicket DESC;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('La distribution par type de tarif des tickets des différentes représentations est la suivante : ');
        FOR ticket IN tickets LOOP
            DBMS_OUTPUT.PUT_LINE(ticket.labelShow || ', ' || ticket.labelTheater || ', à la date du ' || ticket.dat || ', au tarif de ' || ticket.labelTicket || 
            ' : ' || ticket.distrib || ' places vendue(s) ');
            EXIT WHEN tickets%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    labelPriceDistribution;
END;


-- For each theater, what is the average load factor ?
-- Afficher le remplissage moyen des salles pour chaque théâtre
CREATE OR REPLACE PROCEDURE 
showAverageLoadFactor IS
BEGIN
    DECLARE
        CURSOR loadFactors IS
            SELECT 
                cte.idTheaterHall
                ,hall.labelTheater
                ,ROUND(AVG(load_factor), 2) AS average_load_factor
            FROM (
                SELECT
                    idTheaterHall
                    ,(COUNT(idTicket) / hallCapacity) AS load_factor
                FROM TICKET_SHOW ts  
                GROUP BY ts.idShow, ts.idTheaterCompany, ts.dat, ts.hallCapacity, idTheaterHall
            ) cte
            JOIN THEATER_HALL hall ON cte.idTheaterHall = hall.idTheater
            GROUP BY cte.idTheaterHall, hall.labelTheater
            ORDER BY average_load_factor DESC;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Le taux de remplissage pour chaque théâtre est : ');
        FOR lf IN loadFactors LOOP
            DBMS_OUTPUT.PUT_LINE('Théâtre ' || lf.labelTheater || ', remplissage moyen de : 0' || lf.average_load_factor);
            EXIT WHEN loadFactors%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    showAverageLoadFactor;
END;


-- Accounting 
-- 1. The first date when the balance of a theater will move promptly to the red 
-- (in the hypothesis when no ticket is sold out).
-- Afficher la première date à laquelle le solde d'un théâtre sera dans le rouge (dans l'hypothèse où aucun billet n'est vendu)
CREATE OR REPLACE PROCEDURE 
firstRedBalanceDate(nametheater VARCHAR2) IS
BEGIN
    DECLARE
        CURSOR theaters IS
            SELECT 
                MIN(ts.dat) AS firstRedBalanceDate
                ,ts.idTheaterHall
                ,tc.labelTheater
            FROM TICKET_SHOW ts
            JOIN THEATER_HALL hall ON ts.idTheaterHall = hall.idTheater
            JOIN THEATER_COMPANY tc ON hall.idTheater = tc.idTheater 
            WHERE tc.labelTheater = nametheater
            GROUP BY ts.idTheaterHall, tc.labelTheater, ts.dat
            HAVING COUNT(ts.idTicket) = (
                SELECT COUNT(idTicket) 
                FROM TICKET_SHOW
                GROUP BY idTheaterHall, dat
                HAVING COUNT(idTicket) = 0
            );
    BEGIN
        FOR theater IN theaters LOOP
            DBMS_OUTPUT.PUT_LINE('La première date à laquelle le théâtre' || theater.labelTheater || ' se retrouve dans le rouge, 
            avec aucun billet de vendu, est : ' || theater.firstRedBalanceDate);
            EXIT WHEN theaters%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    firstRedBalanceDate('Café Rock');
END;


-- 2. The first date when the balance of a theater will move permanently to the red 
-- (in the hypothesis when no ticket is sold out, and the expected revenue does not offset enough).
-- Afficher la première date à laquelle le solde d'un théâtre passera définitivement dans le rouge 
-- (dans l'hypothèse où aucun billet n'est vendu, et où les recettes attendues ne compensent pas suffisamment)
CREATE OR REPLACE PROCEDURE 
firstPermanentlyRedBalanceDate(nametheater VARCHAR2, expectedRevenue NUMBER) IS
BEGIN
    DECLARE
        CURSOR theaters IS
            SELECT 
                MIN(ts.dat) AS firstPermanentlyRedBalanceDate
                ,ts.idTheaterHall
                ,tc.labelTheater
            FROM TICKET_SHOW ts
            JOIN THEATER_HALL hall ON ts.idTheaterHall = hall.idTheater
            JOIN THEATER_COMPANY tc ON hall.idTheater = tc.idTheater
            WHERE tc.labelTheater = nametheater
            AND tc.budget < expectedRevenue 
            GROUP BY ts.idTheaterHall, tc.labelTheater, ts.dat
            HAVING COUNT(ts.idTicket) = (
                SELECT COUNT(idTicket) 
                FROM TICKET_SHOW
                GROUP BY idTheaterHall, dat
                HAVING COUNT(idTicket) = 0
            );
    BEGIN
        FOR theater IN theaters LOOP
            DBMS_OUTPUT.PUT_LINE('La première date à laquelle le théâtre' || theater.labelTheater || ' se retrouve dans le rouge 
            de façon permanente, avec aucun billet de vendu et avec un revenu en-dessous de ' || expectedRevenue || ' 
            est : ' || theater.firstPermanentlyRedBalanceDate);
            EXIT WHEN theaters%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    firstPermanentlyRedBalanceDate('Euismod Enim Etiam', 2000);
END;


-- 3. Are there enough tickets for sale to avoid these situations ?  
-- Afficher le nombre de places vendus par un théâtre à différentes dates afin d'éviter les situations précédentes
CREATE OR REPLACE PROCEDURE 
enoughTickets(nametheater VARCHAR2, expectedRevenue NUMBER) IS
BEGIN
    DECLARE
        CURSOR theaters IS
            SELECT 
                COUNT(ts.idTicket) AS nbTicketsToSale
                ,tc.idTheater
                ,tc.labelTheater
                ,ts.dat
            FROM TICKET_SHOW ts
            JOIN THEATER_HALL hall ON ts.idTheaterHall = hall.idTheater
            JOIN THEATER_COMPANY tc ON hall.idTheater = tc.idTheater 
            WHERE tc.labelTheater = nametheater
            AND tc.budget >= expectedRevenue
            GROUP BY tc.idTheater, tc.labelTheater, ts.dat
            HAVING COUNT(idTicket) > 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Afin d''éviter cette situation, le théâtre ' || nametheater || ' vend : ');
        FOR theater IN theaters LOOP
            DBMS_OUTPUT.PUT_LINE(theater.nbTicketsToSale || ' places ');
            EXIT WHEN theaters%NOTFOUND;
        END LOOP;
    END;
END;
/


-- 4. A show given by a company was sold out with a certain price. Is it a cost effective for the company ? (Compared to costs incurred (salaries, travel, staging))
-- WHATEVER THE KIND OF EVENT (LOCAL PRODUCTION OR NOT), THE TICKET REVENUES GO TO THE THEATER WHERE THE SHOW TOOK PLACE !!
-- Afficher le solde potentiel de la représentation d''une compagnie de théâtre pour un soir donné, si le spectacle affiche complet
-- CAS N°1 : LA COMPAGNIE ACCUEILLE LE SPECTACLE QU''ELLE PRODUIT DANS SA PROPRE SALLE :
CREATE OR REPLACE PROCEDURE 
balanceSoldOut1(nameShow VARCHAR2, nametheater VARCHAR2, dateshow DATE) IS
BEGIN
    DECLARE
        CURSOR theaters IS
            SELECT 
                s.labelShow, tc.labelTheater, r.dat,
                SUM(r.hallCapacity*25) AS ticketingIncome
                ,(r.comFeesPerRep + r.prodCosts) AS costsIncurred
                ,SUM(r.hallCapacity*25) + (r.comFeesPerRep + r.prodCosts) AS diff
            FROM THEATER_HALL hall
            JOIN REPRESENTATION r ON r.idTheaterHall = hall.idTheater
            JOIN SHOWS s ON s.idShow = r.idShow AND s.idTheater = r.idTheaterCompany
            JOIN THEATER_COMPANY tc ON s.idTheater = tc.idTheater
            WHERE r.idTheaterCompany = r.idTheaterHall
            AND s.labelShow = nameShow AND tc.labelTheater = nametheater AND r.dat = dateshow
            GROUP BY s.labelShow, tc.labelTheater, r.dat, r.comFeesPerRep, r.prodCosts;
    BEGIN
        FOR theater IN theaters LOOP
            DBMS_OUTPUT.PUT_LINE('Le spectacle ' || theater.labelShow || ', de la compagnie productrice ' || theater.labelTheater || 
            ' a, s''il est complet, un solde potentiel de ' || theater.diff || ' au soir du : ' || dateshow);
            EXIT WHEN theaters%NOTFOUND;
            IF theater.diff < 0 THEN
                DBMS_OUTPUT.PUT_LINE('Ce spectacle n''est pas rentable pour la compagnie productrice');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Ce spectacle est rentable pour la compagnie productrice');
            END IF;
        END LOOP;
    END;
END;
/
BEGIN
    balanceSoldOut1('Croc Bagne', 'Euismod Enim Etiam', '23-07-2019');
END;

-- CAS N°2 : LA COMPAGNIE EXPORTE LE SPECTACLE QU''ELLE PRODUIT DANS UNE AUTRE SALLE :
CREATE OR REPLACE PROCEDURE 
balanceSoldOut2(nameShow VARCHAR2, nametheater VARCHAR2, dateshow DATE) IS
BEGIN
    DECLARE
        CURSOR theaters IS
            SELECT 
                s.labelShow, tc.labelTheater, r.dat
                ,(r.travelCostsPerRep + r.globalPrice + r.comFeesPerRep + r.prodCosts) AS costsIncurred
                ,(r.travelCostsPerRep + r.globalPrice + r.comFeesPerRep + r.prodCosts) AS diff
            FROM THEATER_HALL hall
            JOIN REPRESENTATION r ON r.idTheaterHall = hall.idTheater
            JOIN SHOWS s ON s.idShow = r.idShow AND s.idTheater = r.idTheaterCompany
            JOIN THEATER_COMPANY tc ON s.idTheater = tc.idTheater
            WHERE r.idTheaterCompany != r.idTheaterHall
            AND s.labelShow = nameShow AND tc.labelTheater = nametheater AND r.dat = dateshow
            GROUP BY s.labelShow, tc.labelTheater, r.dat, r.travelCostsPerRep, r.globalPrice, r.comFeesPerRep, r.prodCosts;         
    BEGIN
        FOR theater IN theaters LOOP
            DBMS_OUTPUT.PUT_LINE('Le spectacle ' || theater.labelShow || ', de la compagnie productrice ' || theater.labelTheater || 
            ' a, s''il est complet, un solde potentiel de ' || theater.diff || ' au soir du : ' || dateshow);
            EXIT WHEN theaters%NOTFOUND;
            IF theater.diff < 0 THEN
                DBMS_OUTPUT.PUT_LINE('Ce spectacle n''est pas rentable pour la compagnie productrice');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Ce spectacle est rentable pour la compagnie productrice');
            END IF;
        END LOOP;
    END;
END;
/
BEGIN
    balanceSoldOut2('Danhuile le conv', 'Euismod Enim Etiam', '06-03-2020');
END; 

-- CAS N°3 : LE THÉÂTRE ACCUEILLE UN SPECTACLE PRODUIT PAR UNE AUTRE COMPAGNIE DANS SA SALLE :
CREATE OR REPLACE PROCEDURE 
balanceSoldOut3(nameShow VARCHAR2, nametheater VARCHAR2, dateshow DATE) IS
BEGIN
    DECLARE
        CURSOR theaters IS
            SELECT 
                s.labelShow, tc.labelTheater, r.dat, 
                hall.labelTheater AS hall,
                SUM(r.hallCapacity*25) AS ticketingIncome
                ,-(r.globalPrice) AS costsIncurred
                ,SUM(r.hallCapacity*25) - (r.globalPrice) AS diff
            FROM THEATER_HALL hall
            JOIN REPRESENTATION r ON r.idTheaterHall = hall.idTheater
            JOIN SHOWS s ON s.idShow = r.idShow AND s.idTheater = r.idTheaterCompany
            JOIN THEATER_COMPANY tc ON s.idTheater = tc.idTheater
            WHERE r.idTheaterCompany != r.idTheaterHall
            AND s.labelShow = nameShow AND tc.labelTheater = nametheater AND r.dat = dateshow
            GROUP BY s.labelShow, tc.labelTheater, r.dat, hall.labelTheater, r.globalPrice;
    BEGIN
        FOR theater IN theaters LOOP
            DBMS_OUTPUT.PUT_LINE('Le spectacle ' || theater.labelShow || ', produit par la compagnie ' || theater.labelTheater || 
            ' a, s''il est complet, un solde potentiel de ' || theater.diff || ' pour le théâtre hôte ' || theater.hall || ' le soir du : ' || dateshow);
            EXIT WHEN theaters%NOTFOUND;
            IF theater.diff < 0 THEN
                DBMS_OUTPUT.PUT_LINE('Ce spectacle n''est pas rentable pour le théâtre hôte');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Ce spectacle est rentable pour le théâtre hôte');
            END IF;
        END LOOP;
    END;
END;
/
BEGIN
    balanceSoldOut3('Danhuile le conv', 'Euismod Enim Etiam', '06-03-2020');
END; 


-- 5. Was it the effective cost for the theater? (Costs / ticketing)
-- Afficher le solde réel de la représentation d''une compagnie de théâtre pour un soir donné
-- CAS N°1 : LA COMPAGNIE ACCUEILLE LE SPECTACLE QU''ELLE PRODUIT DANS SA PROPRE SALLE :
CREATE OR REPLACE PROCEDURE 
effectiveBalance1(nameShow VARCHAR2, nametheater VARCHAR2, dateshow DATE) IS
BEGIN
    DECLARE
        CURSOR theaters IS
            SELECT 
                s.labelShow, tc.labelTheater, ts.dat,
                SUM(ts.priceTicket) AS ticketingIncome
                ,(r.comFeesPerRep + r.prodCosts) AS costsIncurred
                ,SUM(ts.priceTicket) + (r.comFeesPerRep + r.prodCosts) AS diff
            FROM TICKET_SHOW ts 
            JOIN THEATER_HALL hall ON ts.idTheaterHall = hall.idTheater
            JOIN REPRESENTATION r ON r.idTheaterHall = hall.idTheater
            JOIN SHOWS s ON s.idShow = r.idShow AND s.idTheater = r.idTheaterCompany
            JOIN THEATER_COMPANY tc ON s.idTheater = tc.idTheater
            WHERE r.idTheaterCompany = r.idTheaterHall
            AND s.labelShow = nameShow AND tc.labelTheater = nametheater AND ts.dat = dateshow
            GROUP BY s.labelShow, tc.labelTheater, ts.dat, r.comFeesPerRep, r.prodCosts
            ORDER BY costsIncurred ASC
            FETCH FIRST 1 ROWS ONLY;
    BEGIN
        FOR theater IN theaters LOOP
            DBMS_OUTPUT.PUT_LINE('Le spectacle ' || theater.labelShow || ', de la compagnie productrice ' || theater.labelTheater || 
            ' a un solde réel de ' || theater.diff || ' au soir du : ' || dateshow);
            EXIT WHEN theaters%NOTFOUND;
            IF theater.diff < 0 THEN
                DBMS_OUTPUT.PUT_LINE('Ce spectacle n''est pas rentable pour la compagnie productrice');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Ce spectacle est rentable pour la compagnie productrice');
            END IF;
        END LOOP;
    END;
END;
/
BEGIN
    effectiveBalance1('Croc Bagne', 'Euismod Enim Etiam', '23-07-2019');
END;

-- CAS N°2 : LA COMPAGNIE EXPORTE LE SPECTACLE QU''ELLE PRODUIT DANS UNE AUTRE SALLE :
CREATE OR REPLACE PROCEDURE 
effectiveBalance2(nameShow VARCHAR2, nametheater VARCHAR2, dateshow DATE) IS
BEGIN
    DECLARE
        CURSOR theaters IS
            SELECT 
                s.labelShow, tc.labelTheater, ts.dat
                ,(r.travelCostsPerRep + r.globalPrice + r.comFeesPerRep + r.prodCosts) AS costsIncurred
                ,(r.travelCostsPerRep + r.globalPrice + r.comFeesPerRep + r.prodCosts) AS diff
            FROM TICKET_SHOW ts 
            JOIN THEATER_HALL hall ON ts.idTheaterHall = hall.idTheater
            JOIN REPRESENTATION r ON r.idTheaterHall = hall.idTheater
            JOIN SHOWS s ON s.idShow = r.idShow AND s.idTheater = r.idTheaterCompany
            JOIN THEATER_COMPANY tc ON s.idTheater = tc.idTheater
            WHERE r.idTheaterCompany != r.idTheaterHall
            AND s.labelShow = nameShow AND tc.labelTheater = nametheater AND ts.dat = dateshow
            GROUP BY s.labelShow, tc.labelTheater, ts.dat, r.travelCostsPerRep + r.globalPrice, r.comFeesPerRep, r.prodCosts
            ORDER BY costsIncurred ASC
            FETCH FIRST 1 ROWS ONLY;
    BEGIN
        FOR theater IN theaters LOOP
            DBMS_OUTPUT.PUT_LINE('Le spectacle ' || theater.labelShow || ', de la compagnie productrice ' || theater.labelTheater || 
            ' a un solde réel de ' || theater.diff || ' au soir du : ' || dateshow);
            EXIT WHEN theaters%NOTFOUND;
            IF theater.diff < 0 THEN
                DBMS_OUTPUT.PUT_LINE('Ce spectacle n''est pas rentable pour la compagnie productrice');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Ce spectacle est rentable pour la compagnie productrice');
            END IF;
        END LOOP;
    END;
END;
/
BEGIN
    effectiveBalance2('Danhuile le conv', 'Euismod Enim Etiam', '06-03-2020');
END;

-- CAS N°3 : LE THÉÂTRE ACCUEILLE UN SPECTACLE PRODUIT PAR UNE AUTRE COMPAGNIE DANS SA SALLE :
CREATE OR REPLACE PROCEDURE 
effectiveBalance3(nameShow VARCHAR2, nametheater VARCHAR2, dateshow DATE) IS
BEGIN
    DECLARE
        CURSOR theaters IS
            SELECT 
                s.labelShow, tc.labelTheater, ts.dat,
                hall.labelTheater AS hall,
                SUM(ts.priceTicket) AS ticketingIncome
                ,-(r.globalPrice) AS costsIncurred
                ,SUM(ts.priceTicket) - (r.globalPrice) AS diff
            FROM TICKET_SHOW ts 
            JOIN THEATER_HALL hall ON ts.idTheaterHall = hall.idTheater
            JOIN REPRESENTATION r ON r.idTheaterHall = hall.idTheater
            JOIN SHOWS s ON s.idShow = r.idShow AND s.idTheater = r.idTheaterCompany
            JOIN THEATER_COMPANY tc ON s.idTheater = tc.idTheater
            WHERE r.idTheaterCompany != r.idTheaterHall
            AND s.labelShow = nameShow AND tc.labelTheater = nametheater AND ts.dat = dateshow
            GROUP BY s.labelShow, tc.labelTheater, ts.dat, hall.labelTheater, r.globalPrice
            ORDER BY costsIncurred ASC
            FETCH FIRST 1 ROWS ONLY;
    BEGIN
        FOR theater IN theaters LOOP
            DBMS_OUTPUT.PUT_LINE('Le spectacle ' || theater.labelShow || ', produit par la compagnie ' || theater.labelTheater || 
            ' a un solde réel de ' || theater.diff || ' pour le théâtre hôte ' || theater.hall || ' le soir du : ' || dateshow);
            EXIT WHEN theaters%NOTFOUND;
            IF theater.diff < 0 THEN
                DBMS_OUTPUT.PUT_LINE('Ce spectacle n''est pas rentable pour le théâtre hôte');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Ce spectacle est rentable pour le théâtre hôte');
            END IF;
        END LOOP;
    END;
END;
/
BEGIN
    effectiveBalance3('Danhuile le conv', 'Euismod Enim Etiam', '06-03-2020');
END;


-- Network :
-- Are there companies that will never play in their theater ? 
-- Afficher les compagnies de théâtre qui ne jouent jamais dans leur propre théâtre
CREATE OR REPLACE PROCEDURE 
companiesNotAtHome IS
BEGIN
    DECLARE
        CURSOR theaters IS
            SELECT
                tc.idTheater
                ,tc.labelTheater
            FROM THEATER_COMPANY tc
            JOIN SHOWS s ON s.idTheater = tc.idTheater
            JOIN REPRESENTATION r ON s.idShow = r.idShow AND s.idTheater = r.idTheaterCompany
            JOIN THEATER_HALL hall ON hall.idTheater = r.idTheaterHall 
            WHERE r.idTheaterHall != r.idTheaterCompany   
            GROUP BY tc.idTheater, tc.labelTheater
            HAVING tc.idTheater NOT IN (
                SELECT
                    tc.idTheater
                FROM THEATER_COMPANY tc
                JOIN SHOWS s ON s.idTheater = tc.idTheater
                JOIN REPRESENTATION r ON s.idShow = r.idShow AND s.idTheater = r.idTheaterCompany
                JOIN THEATER_HALL hall ON hall.idTheater = r.idTheaterHall 
                WHERE r.idTheaterHall = r.idTheaterCompany  
                GROUP BY tc.idTheater
            );
    BEGIN
    DBMS_OUTPUT.PUT_LINE('Les compagnies de théâtre qui ne jouent jamais à domicile sont : ');
        FOR theater IN theaters LOOP
            DBMS_OUTPUT.PUT_LINE(theater.labelTheater);
            EXIT WHEN theaters%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    companiesNotAtHome;
END;


-- Which ones make systematically their first show at home ?
-- Afficher les compagnies de théâtre qui jouent systématiquement leur première représentation dans leur propre salle
CREATE OR REPLACE PROCEDURE 
companiesFirstShowAtHome IS
BEGIN
    DECLARE
        CURSOR theaters IS
            select 
            LABELTHEATER, 
            dat 
            from 
            representation r, 
            THEATER_COMPANY t 
            where 
            t.IDTHEATER = r.IDTHEATERCOMPANY 
            and r.IDTHEATERCOMPANY = r.IDTHEATERHALL 
            and r.dat = (
                select 
                min (dat) 
                from 
                representation 
                where 
                IDTHEATERCOMPANY = r.IDTHEATERCOMPANY
            );
    BEGIN
    DBMS_OUTPUT.PUT_LINE('Les compagnies de théâtre qui jouent systématiquement leur première représentation à domicile sont : ');
        FOR theater IN theaters LOOP
            DBMS_OUTPUT.PUT_LINE(theater.labelTheater);
            EXIT WHEN theaters%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    companiesFirstShowAtHome;
END;


-- And outside ?
-- Afficher les compagnies de théâtre qui jouent systématiquement leur première représentation dans une salle extérieure
CREATE OR REPLACE PROCEDURE 
companiesFirstShowOutside IS
BEGIN
    DECLARE
        CURSOR theaters IS
            select 
            t.LABELTHEATER, 
            dat 
            from 
            representation r, 
            THEATER_COMPANY t 
            where 
            t.IDTHEATER = r.IDTHEATERCOMPANY 
            and r.IDTHEATERCOMPANY <> r.IDTHEATERHALL 
            and r.dat = (
                select 
                min (dat) 
                from 
                representation 
                where 
                IDTHEATERCOMPANY = r.IDTHEATERCOMPANY
            );
    BEGIN
    DBMS_OUTPUT.PUT_LINE('Les compagnies de théâtre qui jouent systématiquement leur première représentation à l''extérieur sont : ');
        FOR theater IN theaters LOOP
            DBMS_OUTPUT.PUT_LINE(theater.labelTheater);
            EXIT WHEN theaters%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    companiesFirstShowOutside;
END;


-- What are the most popular shows in a certain period ?
-- • Number of representation
-- Afficher le nombre de représentations d''un même spectacle pendant une période de temps donnée
CREATE OR REPLACE PROCEDURE 
nbOfRep(dateshow1 DATE, dateshow2 DATE) IS
BEGIN
    DECLARE
        CURSOR seats IS
            SELECT 
                s.labelShow
                ,COUNT(r.idShow) AS nbOfRep
            FROM REPRESENTATION r
            JOIN SHOWS s ON r.idShow = s.idShow AND r.idTheaterCompany = s.idTheater  
            WHERE r.dat BETWEEN dateshow1 AND dateshow2
            GROUP BY s.labelShow
            ORDER BY COUNT(r.idShow) DESC
            FETCH FIRST 3 ROWS ONLY;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Les spectacles les plus joués entre le ' || dateshow1 || ' et le ' || dateshow2 || ' sont : ');
        FOR seat IN seats LOOP
            DBMS_OUTPUT.PUT_LINE(seat.labelShow || ', avec ' || seat.nbOfRep || ' représentations');
            EXIT when seats%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    nbOfRep('29-02-2012', '17-04-2018');
END;


-- • Number of potential viewers
-- Afficher le nombre de spectateurs potentiels d''un même spectacle pendant une période de temps donnée
CREATE OR REPLACE PROCEDURE 
nbOfSeatstoSell(dateshow1 DATE, dateshow2 DATE) IS
BEGIN
    DECLARE
        CURSOR seats IS
            SELECT 
                s.labelShow
                ,SUM(r.hallCapacity) AS nbOfSeats
            FROM REPRESENTATION r
            JOIN SHOWS s ON r.idShow = s.idShow AND r.idTheaterCompany = s.idTheater  
            WHERE r.dat BETWEEN dateshow1 AND dateshow2
            GROUP BY s.labelShow
            ORDER BY SUM(r.hallCapacity) DESC
            FETCH FIRST 5 ROWS ONLY;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Les spectacles potentiellement les plus populaires entre le ' || dateshow1 || ' et le ' || dateshow2 || ' sont : ');
        FOR seat IN seats LOOP
            DBMS_OUTPUT.PUT_LINE(seat.labelShow || ', avec ' || seat.nbOfSeats || ' places à vendre');
            EXIT when seats%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    nbOfSeatstoSell('29-02-2012', '17-04-2018');
END;


-- • Number of seats sold
-- Afficher le nombre de sièges vendus pour un même spectace pendant une période de temps donnée
CREATE OR REPLACE PROCEDURE 
nbOfSeatsSold(dateshow1 DATE, dateshow2 DATE) IS
BEGIN
    DECLARE
        CURSOR seats IS
            SELECT 
                s.idShow,
                s.labelShow
                ,tc.labelTheater
                ,COUNT(ts.idTicket) AS nbMaxOfSeatsSold
            FROM REPRESENTATION r
            JOIN SHOWS s ON r.idShow = s.idShow AND r.idTheaterCompany = s.idTheater 
            JOIN TICKET_SHOW ts ON s.idShow = ts.idShow AND s.idTheater = ts.idTheaterCompany
            JOIN THEATER_COMPANY tc ON s.idTheater = tc.idTheater 
            WHERE r.dat BETWEEN '29-02-2012' AND '17-04-2018'
            GROUP BY s.idShow, s.labelShow, tc.labelTheater
            ORDER BY COUNT(ts.idTicket) DESC
            FETCH FIRST 5 ROWS ONLY;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Les spectacles les plus populaires entre le ' || dateshow1 || ' et le ' || dateshow2 || ' sont : ');
        FOR seat IN seats LOOP
            DBMS_OUTPUT.PUT_LINE(seat.labelShow || ', (' || seat.labelTheater || '), avec ' || seat.nbMaxOfSeatsSold || ' places vendues');
            EXIT when seats%NOTFOUND;
        END LOOP;
    END;
END;
/

BEGIN
    nbOfSeatsSold('29-02-2012', '17-04-2018');
END;


























