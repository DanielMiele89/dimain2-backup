CREATE TABLE [InsightArchive].[Amex_Actuals_20171128_upload] (
    [RetailerID]     VARCHAR (50) NULL,
    [BrandID]        VARCHAR (50) NULL,
    [RetailerName]   VARCHAR (50) NULL,
    [IronOfferID]    VARCHAR (50) NULL,
    [AmexOfferID]    VARCHAR (50) NULL,
    [Segment]        VARCHAR (50) NULL,
    [StartDate]      DATETIME     NULL,
    [EndDate]        DATETIME     NULL,
    [Cycle]          VARCHAR (50) NULL,
    [CycleStartDate] DATETIME     NULL,
    [CycleEndDate]   DATETIME     NULL,
    [Cardholders]    VARCHAR (50) NULL,
    [Spenders]       NUMERIC (18) NULL,
    [Spend]          NUMERIC (18) NULL,
    [Transactions]   NUMERIC (18) NULL,
    [RR]             NUMERIC (18) NULL,
    [SPS]            NUMERIC (18) NULL,
    [SPC]            NUMERIC (18) NULL,
    [TPC]            NUMERIC (18) NULL,
    [IsPartial]      VARCHAR (50) NULL
);

