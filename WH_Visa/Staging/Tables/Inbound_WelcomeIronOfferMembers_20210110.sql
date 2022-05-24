CREATE TABLE [Staging].[Inbound_WelcomeIronOfferMembers_20210110] (
    [WelcomeIronOfferMembersID] UNIQUEIDENTIFIER NOT NULL,
    [OfferGUID]                 UNIQUEIDENTIFIER NULL,
    [CustomerGUID]              UNIQUEIDENTIFIER NULL,
    [StartDate]                 DATETIME2 (7)    NULL,
    [EndDate]                   DATETIME2 (7)    NULL,
    [LoadDate]                  DATETIME2 (7)    NULL,
    [FileName]                  NVARCHAR (100)   NULL
);

