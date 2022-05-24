CREATE TABLE [Staging].[Partner_Acquirer_TransactionTracking] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID]   INT           NOT NULL,
    [PartnerName] VARCHAR (100) NOT NULL,
    [Acquirer]    VARCHAR (40)  NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

