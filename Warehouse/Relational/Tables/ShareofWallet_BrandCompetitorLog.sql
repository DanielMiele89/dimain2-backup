CREATE TABLE [Relational].[ShareofWallet_BrandCompetitorLog] (
    [ID]              INT            IDENTITY (1, 1) NOT NULL,
    [ShareOfWalletID] INT            NOT NULL,
    [CompetitorID]    INT            NOT NULL,
    [CompetitorName]  NVARCHAR (150) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

