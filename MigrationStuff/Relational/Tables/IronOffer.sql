CREATE TABLE [Relational].[IronOffer] (
    [ID]                    INT            NOT NULL,
    [OfferID]               INT            NULL,
    [IronOfferName]         NVARCHAR (100) NULL,
    [StartDate]             DATETIME       NULL,
    [EndDate]               DATETIME       NULL,
    [PartnerID]             SMALLINT       NULL,
    [IsSignedOff]           BIT            NULL,
    [ClubID]                SMALLINT       NULL,
    [IsAppliedToAllMembers] BIT            NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_PID]
    ON [Relational].[IronOffer]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_OID]
    ON [Relational].[IronOffer]([OfferID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_CID]
    ON [Relational].[IronOffer]([ClubID] ASC);


GO
DENY ALTER
    ON OBJECT::[Relational].[IronOffer] TO [OnCall]
    AS [dbo];


GO
DENY DELETE
    ON OBJECT::[Relational].[IronOffer] TO [OnCall]
    AS [dbo];

