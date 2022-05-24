CREATE TABLE [Derived].[IronOffer] (
    [IronOfferID]                 INT              NOT NULL,
    [IronOfferName]               NVARCHAR (200)   NULL,
    [HydraOfferID]                UNIQUEIDENTIFIER NULL,
    [StartDate]                   DATETIME         NULL,
    [EndDate]                     DATETIME         NULL,
    [PartnerID]                   INT              NULL,
    [IsAboveTheLine]              BIT              NULL,
    [AutoAddToNewRegistrants]     BIT              NULL,
    [IsDefaultCollateral]         BIT              NULL,
    [IsSignedOff]                 BIT              NULL,
    [AreEligibleMembersCommitted] BIT              NULL,
    [AreControlMembersCommitted]  BIT              NULL,
    [IsTriggerOffer]              BIT              NULL,
    [Continuation]                BIT              NULL,
    [TopCashBackRate]             REAL             NULL,
    [AboveBase]                   BIT              NULL,
    [Clubs]                       NVARCHAR (7)     NULL,
    [CampaignType]                NVARCHAR (50)    NULL,
    [SegmentName]                 VARCHAR (25)     NULL,
    [ClubID]                      INT              NULL,
    PRIMARY KEY CLUSTERED ([IronOfferID] ASC) WITH (FILLFACTOR = 90)
);




GO
CREATE NONCLUSTERED INDEX [IX_OfferPartner]
    ON [Derived].[IronOffer]([HydraOfferID] ASC, [IronOfferID] ASC, [PartnerID] ASC) WITH (FILLFACTOR = 90);


GO
GRANT SELECT
    ON OBJECT::[Derived].[IronOffer] TO [visa_etl_user]
    AS [New_DataOps];

