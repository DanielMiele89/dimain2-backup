CREATE TABLE [Inbound].[RBS_IronOffer] (
    [IronOfferID]                 INT            NOT NULL,
    [IronOfferName]               NVARCHAR (200) NULL,
    [HydraOfferID]                VARCHAR (1)    NOT NULL,
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
    [SegmentName]                 VARCHAR (50)   NULL,
    [ClubID]                      INT            NULL
);

