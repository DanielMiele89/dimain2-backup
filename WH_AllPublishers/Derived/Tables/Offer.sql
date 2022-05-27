CREATE TABLE [Derived].[Offer] (
    [OfferID]              INT            IDENTITY (1, 1) NOT NULL,
    [SourceSystemID]       INT            NOT NULL,
    [PublisherType]        VARCHAR (25)   NULL,
    [PublisherID]          INT            NULL,
    [RetailerID]           INT            NULL,
    [PartnerID]            INT            NULL,
    [IronOfferID]          INT            NULL,
    [OfferGUID]            VARCHAR (64)   NULL,
    [OfferCode]            VARCHAR (64)   NULL,
    [CODOfferID]           INT            NULL,
    [SourceOfferID]        VARCHAR (25)   NULL,
    [StartDate]            DATETIME       NULL,
    [EndDate]              DATETIME       NULL,
    [CampaignCode]         VARCHAR (25)   NULL,
    [OfferName]            VARCHAR (200)  NULL,
    [OfferDescription]     VARCHAR (200)  NULL,
    [SegmentID]            INT            NULL,
    [SegmentName]          VARCHAR (25)   NULL,
    [EarningChannel]       VARCHAR (9)    NULL,
    [EarningCount]         VARCHAR (9)    NULL,
    [EarningType]          VARCHAR (8)    NULL,
    [EarningLimit]         DECIMAL (8, 2) NULL,
    [TopCashBackRate]      DECIMAL (8, 2) NULL,
    [BaseCashBackRate]     DECIMAL (8, 2) NULL,
    [SpendStretchAmount_1] DECIMAL (8, 2) NULL,
    [SpendStretchRate_1]   DECIMAL (8, 2) NULL,
    [SpendStretchAmount_2] DECIMAL (8, 2) NULL,
    [SpendStretchRate_2]   DECIMAL (8, 2) NULL,
    [SegmentCode]          VARCHAR (10)   NULL,
    [SuperSegmentID]       INT            NULL,
    [SuperSegmentName]     VARCHAR (40)   NULL,
    [OfferTypeID]          INT            NULL,
    [OfferTypeDescription] VARCHAR (50)   NULL,
    [OfferTypeForReports]  VARCHAR (100)  NULL,
    [IsSignedOff]          BIT            NULL,
    [AddedDate]            DATETIME2 (7)  NOT NULL,
    [ModifiedDate]         DATETIME2 (7)  NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_OfferID_IncPubTypeOfferName]
    ON [Derived].[Offer]([OfferID] ASC)
    INCLUDE([PublisherType], [OfferName]) WITH (FILLFACTOR = 90);

