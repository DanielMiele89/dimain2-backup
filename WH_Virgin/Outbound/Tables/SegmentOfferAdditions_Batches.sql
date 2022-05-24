CREATE TABLE [Outbound].[SegmentOfferAdditions_Batches] (
    [CustomerID]   VARCHAR (20) NOT NULL,
    [HydraOfferID] VARCHAR (40) NOT NULL,
    [StartDate]    DATETIME     NOT NULL,
    [EndDate]      DATETIME     NOT NULL,
    [rw]           INT          IDENTITY (1, 1) NOT NULL
);


GO
CREATE CLUSTERED INDEX [cIX]
    ON [Outbound].[SegmentOfferAdditions_Batches]([rw] ASC);

