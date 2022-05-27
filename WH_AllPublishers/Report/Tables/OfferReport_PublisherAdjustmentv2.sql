CREATE TABLE [Report].[OfferReport_PublisherAdjustmentv2] (
    [IronOfferID]        INT        NULL,
    [ControlGroupTypeID] INT        NOT NULL,
    [StartDate]          DATE       NOT NULL,
    [EndDate]            DATE       DEFAULT ('2099-01-01') NOT NULL,
    [Adjustment]         FLOAT (53) NULL,
    [RowNum]             INT        IDENTITY (1, 1) NOT NULL
);

