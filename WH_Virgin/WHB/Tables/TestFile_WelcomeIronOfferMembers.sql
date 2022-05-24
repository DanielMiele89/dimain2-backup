CREATE TABLE [WHB].[TestFile_WelcomeIronOfferMembers] (
    [WelcomeIronOfferMembersID] BIGINT           IDENTITY (1, 1) NOT NULL,
    [HydraOfferID]              UNIQUEIDENTIFIER NULL,
    [SourceUID]                 VARCHAR (20)     NULL,
    [StartDate]                 DATETIME         NULL,
    [EndDate]                   DATETIME         NULL,
    [ImportDate]                DATETIME         NULL
);

