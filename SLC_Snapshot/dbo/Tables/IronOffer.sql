CREATE TABLE [dbo].[IronOffer] (
    [ID]                    INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Name]                  NVARCHAR (200) NOT NULL,
    [StartDate]             DATETIME       NULL,
    [EndDate]               DATETIME       NULL,
    [PartnerID]             INT            NOT NULL,
    [IsAboveTheLine]        BIT            NOT NULL,
    [IsDefaultCollateral]   BIT            NOT NULL,
    [IsSignedOff]           BIT            NOT NULL,
    [IsTriggerOffer]        BIT            NOT NULL,
    [DisplaySuppressed]     BIT            NOT NULL,
    [IsAppliedToAllMembers] BIT            NOT NULL,
    CONSTRAINT [PK_IronOffer] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[IronOffer] TO [virgin_etl_user]
    AS [dbo];

