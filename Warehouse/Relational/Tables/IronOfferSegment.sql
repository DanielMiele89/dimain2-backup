CREATE TABLE [Relational].[IronOfferSegment] (
    [IronOfferID]          INT            NOT NULL,
    [OfferStartDate]       DATE           NOT NULL,
    [OfferEndDate]         DATE           NULL,
    [PartnerID]            INT            NOT NULL,
    [RetailerID]           INT            NOT NULL,
    [IronOfferName]        NVARCHAR (200) NOT NULL,
    [PublisherID]          INT            NOT NULL,
    [PublisherGroupID]     INT            NOT NULL,
    [PublisherGroupName]   VARCHAR (40)   NOT NULL,
    [SegmentID]            INT            NULL,
    [SegmentName]          VARCHAR (50)   NULL,
    [SegmentCode]          VARCHAR (10)   NULL,
    [SuperSegmentID]       INT            NULL,
    [SuperSegmentName]     VARCHAR (40)   NULL,
    [OfferTypeID]          INT            NULL,
    [OfferTypeDescription] VARCHAR (50)   NULL,
    [OfferTypeForReports]  VARCHAR (100)  NOT NULL,
    [ClientServicesRef]    VARCHAR (40)   NULL,
    [DateAdded]            DATE           NOT NULL,
    CONSTRAINT [PK_IronOfferSegment] PRIMARY KEY CLUSTERED ([IronOfferID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCIX_IronOfferSegment]
    ON [Relational].[IronOfferSegment]([OfferTypeForReports] ASC);

