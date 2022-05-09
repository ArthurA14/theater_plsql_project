
DROP TABLE TICKET_SHOW CASCADE CONSTRAINTS;
DROP TABLE REPRESENTATION CASCADE CONSTRAINTS;
DROP TABLE PAYMENT_DATE CASCADE CONSTRAINTS;
DROP TABLE DONATION CASCADE CONSTRAINTS;
DROP TABLE TICKETS CASCADE CONSTRAINTS;
DROP TABLE CUSTOMER CASCADE CONSTRAINTS;
DROP TABLE SHOWS CASCADE CONSTRAINTS;
DROP TABLE THEATER_COMPANY CASCADE CONSTRAINTS;
DROP TABLE THEATER_HALL CASCADE CONSTRAINTS;
DROP TABLE DATES CASCADE CONSTRAINTS;
DROP TABLE DONATORS CASCADE CONSTRAINTS;

-- ======================================================================
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY';
-- ======================================================================

CREATE TABLE DATES(
   dat DATE,
   PRIMARY KEY(dat)
);

CREATE TABLE DONATORS(
   idDonator NUMBER(4),
   labelDonator VARCHAR2(50),
   PRIMARY KEY(idDonator),
   UNIQUE(labelDonator)
);

CREATE TABLE CUSTOMER(
   idCustomer NUMBER(4),
   nameCustomer VARCHAR2(50),
   age NUMBER(4),
   status VARCHAR2(50),
   idStatus NUMBER(4),
   PRIMARY KEY(idCustomer, status)
);

CREATE TABLE THEATER_HALL(
   idTheater NUMBER(4),
   labelTheater VARCHAR2(50),
   hallCapacity NUMBER(4),
   cityHall VARCHAR2(50),
   PRIMARY KEY(idTheater, hallCapacity),
   UNIQUE(labelTheater)
);

CREATE TABLE THEATER_COMPANY(
   idTheater NUMBER(4),
   labelTheater VARCHAR2(50),
   hallCapacity NUMBER(4),
   budget NUMBER(9,2),
   budgetMonth DATE,
   PRIMARY KEY(idTheater),
   UNIQUE(idTheater, hallCapacity),
   UNIQUE(labelTheater),
   FOREIGN KEY(idTheater, hallCapacity) REFERENCES THEATER_HALL(idTheater, hallCapacity)
);

CREATE TABLE SHOWS(
   idShow NUMBER(4),
   labelShow VARCHAR2(50),
   idTheater NUMBER(4) NOT NULL,
   PRIMARY KEY(idShow, idTheater),
   FOREIGN KEY(idTheater) REFERENCES THEATER_COMPANY(idTheater)
);

CREATE TABLE TICKETS(
   idTicket NUMBER(4),
   labelTicket VARCHAR2(50),
   priceTicket DECIMAL(15,2),
   idShow NUMBER(4),
   idTheater NUMBER(4),
   idCustomer NUMBER(4) NOT NULL,
   statusCustomer VARCHAR2(50),
   PRIMARY KEY(idTicket, priceTicket, idShow, idTheater),
   FOREIGN KEY(idShow, idTheater) REFERENCES SHOWS(idShow, idTheater),
   FOREIGN KEY(idCustomer, statusCustomer) REFERENCES CUSTOMER(idCustomer, status)
);

CREATE TABLE DONATION(
   idDonator NUMBER(4),
   idTheater NUMBER(4),
   priceDonation DECIMAL(15,2),
   durationDonation NUMBER(4),
   PRIMARY KEY(idDonator, idTheater),
   FOREIGN KEY(idDonator) REFERENCES DONATORS(idDonator),
   FOREIGN KEY(idTheater) REFERENCES THEATER_COMPANY(idTheater)
);

CREATE TABLE PAYMENT_DATE(
   dat DATE,
   idTicket NUMBER(4),
   priceTicket DECIMAL(15,2),
   idShow NUMBER(4),
   idTheater NUMBER(4),
   PRIMARY KEY(dat, idTicket, priceTicket, idShow, idTheater),
   FOREIGN KEY(dat) REFERENCES DATES(dat),
   FOREIGN KEY(idTicket, priceTicket, idShow, idTheater) REFERENCES TICKETS(idTicket, priceTicket, idShow, idTheater)
);

CREATE TABLE REPRESENTATION(
   dat DATE,
   idShow NUMBER(4),
   idTheaterCompany NUMBER(4),
   idTheaterHall NUMBER(4),
   hallCapacity NUMBER(4),
   travelCostsPerRep DECIMAL(15,2),
   comFeesPerRep DECIMAL(15,2),
   globalPrice DECIMAL(15,2),
   prodCosts DECIMAL(15,2),
   PRIMARY KEY(dat, idShow, idTheaterCompany, idTheaterHall, hallCapacity),
   FOREIGN KEY(dat) REFERENCES DATES(dat),
   FOREIGN KEY(idShow, idTheaterCompany) REFERENCES SHOWS(idShow, idTheater),
   FOREIGN KEY(idTheaterHall, hallCapacity) REFERENCES THEATER_HALL(idTheater, hallCapacity)
);

CREATE TABLE TICKET_SHOW(
   dat DATE,
   idTicket NUMBER(4),
   priceTicket DECIMAL(15,2),
   idShow NUMBER(4),
   idTheaterCompany NUMBER(4),
   idTheaterHall NUMBER(4),
   hallCapacity NUMBER(4),
   PRIMARY KEY(dat, idTicket, priceTicket, idShow, idTheaterCompany, idTheaterHall, hallCapacity),
   FOREIGN KEY(dat) REFERENCES DATES(dat),
   FOREIGN KEY(idTicket, priceTicket, idShow, idTheaterCompany) REFERENCES TICKETS(idTicket, priceTicket, idShow, idTheater),
   FOREIGN KEY(idTheaterHall, hallCapacity) REFERENCES THEATER_HALL(idTheater, hallCapacity)
);


COMMIT;
