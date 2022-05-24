CREATE TABLE [Inbound].[WelcomeIronOfferMembers] (
    [WelcomeIronOfferMembersID] BIGINT           IDENTITY (1, 1) NOT NULL,
    [HydraOfferID]              UNIQUEIDENTIFIER NULL,
    [SourceUID]                 VARCHAR (20)     NULL,
    [StartDate]                 DATETIME         NULL,
    [EndDate]                   DATETIME         NULL,
    [ImportDate]                DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_Inbound_WelcomeIronOfferMembers] PRIMARY KEY CLUSTERED ([WelcomeIronOfferMembersID] ASC) WITH (FILLFACTOR = 90)
);




GO
GRANT UPDATE
    ON OBJECT::[Inbound].[WelcomeIronOfferMembers] TO [crtimport]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Inbound].[WelcomeIronOfferMembers] TO [crtimport]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Inbound].[WelcomeIronOfferMembers] TO [crtimport]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[Inbound].[WelcomeIronOfferMembers] TO [crtimport]
    AS [dbo];

