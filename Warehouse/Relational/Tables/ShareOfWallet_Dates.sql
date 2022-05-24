CREATE TABLE [Relational].[ShareOfWallet_Dates] (
    [ID]              INT  IDENTITY (1, 1) NOT NULL,
    [ShareofWalletID] INT  NULL,
    [StartDate]       DATE NULL,
    [EndDate]         DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

