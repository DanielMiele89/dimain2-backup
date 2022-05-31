CREATE TABLE [kevinc].[AdjustmentFactor] (
    [AdjFactorID]      INT           NOT NULL,
    [OfferTypeID]      INT           NOT NULL,
    [PartnerID]        INT           NOT NULL,
    [StartDate]        DATETIME2 (7) NULL,
    [EndDate]          DATETIME2 (7) NULL,
    [Adjustmentfactor] DECIMAL (18)  NULL,
    PRIMARY KEY CLUSTERED ([AdjFactorID] ASC)
);

