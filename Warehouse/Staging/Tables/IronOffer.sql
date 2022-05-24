CREATE TABLE [Staging].[IronOffer] (
    [IronOfferID]                 INT            NULL,
    [IronOfferName]               NVARCHAR (200) NULL,
    [StartDate]                   DATETIME       NULL,
    [EndDate]                     DATETIME       NULL,
    [PartnerID]                   INT            NULL,
    [IsAboveTheLine]              BIT            NULL,
    [AutoAddToNewRegistrants]     BIT            NULL,
    [IsDefaultCollateral]         BIT            NULL,
    [IsSignedOff]                 BIT            NULL,
    [AreEligibleMembersCommitted] BIT            NULL,
    [AreControlMembersCommitted]  BIT            NULL,
    [IsTriggerOffer]              BIT            NULL,
    [Continuation]                BIT            NULL,
    [TopCashBackRate]             REAL           NULL,
    [AboveBase]                   BIT            NULL
);

