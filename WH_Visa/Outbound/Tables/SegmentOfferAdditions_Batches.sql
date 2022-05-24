CREATE TABLE [Outbound].[SegmentOfferAdditions_Batches] (
    [CustomerID]   VARCHAR (20) NULL,
    [HydraOfferID] VARCHAR (40) NULL,
    [StartDate]    DATETIME     NOT NULL,
    [EndDate]      DATETIME     NULL,
    [rw]           BIGINT       NULL
);

