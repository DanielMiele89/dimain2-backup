CREATE TABLE [Relational].[Archived_IronOffer_20210422] (
    [IronOfferID]                 INT            NOT NULL,
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
    [AboveBase]                   BIT            NULL,
    [Clubs]                       NVARCHAR (7)   NULL,
    [CampaignType]                NVARCHAR (50)  NULL,
    PRIMARY KEY CLUSTERED ([IronOfferID] ASC)
);




GO
CREATE NONCLUSTERED INDEX [ix_IsTriggerOffer]
    ON [Relational].[Archived_IronOffer_20210422]([IsTriggerOffer] ASC, [AboveBase] ASC)
    INCLUDE([IronOfferName], [StartDate], [EndDate], [PartnerID]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_IsTriggerOffer_New]
    ON [Relational].[Archived_IronOffer_20210422]([IsTriggerOffer] ASC, [AboveBase] ASC, [IronOfferName] ASC, [StartDate] ASC, [EndDate] ASC)
    INCLUDE([PartnerID]) WITH (FILLFACTOR = 80);


GO
DENY DELETE
    ON OBJECT::[Relational].[Archived_IronOffer_20210422] TO [OnCall]
    AS [dbo];


GO
DENY ALTER
    ON OBJECT::[Relational].[Archived_IronOffer_20210422] TO [OnCall]
    AS [dbo];

