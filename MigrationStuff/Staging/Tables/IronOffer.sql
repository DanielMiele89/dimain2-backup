CREATE TABLE [Staging].[IronOffer] (
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
    ON [Staging].[IronOffer]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_OID]
    ON [Staging].[IronOffer]([OfferID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_CID]
    ON [Staging].[IronOffer]([ClubID] ASC);

