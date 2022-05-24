CREATE TABLE [Inbound].[Testing_WelcomeIronOfferMembers] (
    [WelcomeIronOfferMembersID] UNIQUEIDENTIFIER NOT NULL,
    [OfferGUID]                 UNIQUEIDENTIFIER NULL,
    [CustomerGUID]              UNIQUEIDENTIFIER NULL,
    [StartDate]                 DATETIME2 (7)    NULL,
    [EndDate]                   DATETIME2 (7)    NULL,
    [LoadDate]                  DATETIME2 (7)    NULL,
    [FileName]                  NVARCHAR (100)   NULL
);

