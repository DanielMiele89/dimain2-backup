CREATE TABLE [InsightArchive].[Customers_NewDebitJoiners_MailHouse] (
    [ID]                 INT  IDENTITY (1, 1) NOT NULL,
    [FanID]              INT  NOT NULL,
    [DatetoMailingHouse] DATE NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

