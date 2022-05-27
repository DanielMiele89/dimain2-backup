CREATE TABLE [Inbound].[nFI_IronOffer] (
    [ID]                    INT            NOT NULL,
    [OfferID]               INT            NULL,
    [IronOfferName]         NVARCHAR (100) NULL,
    [StartDate]             DATETIME       NULL,
    [EndDate]               DATETIME       NULL,
    [PartnerID]             SMALLINT       NULL,
    [IsSignedOff]           BIT            NULL,
    [ClubID]                SMALLINT       NULL,
    [IsAppliedToAllMembers] BIT            NULL
);

