CREATE TABLE [APW].[Retailer] (
    [ID]                   INT           NOT NULL,
    [RetailerName]         VARCHAR (100) NOT NULL,
    [Tier]                 TINYINT       NULL,
    [CumulativeStartDate]  DATE          NULL,
    [RedFraction]          FLOAT (53)    NOT NULL,
    [AmberFraction]        FLOAT (53)    NOT NULL,
    [UpliftMin]            FLOAT (53)    NULL,
    [UpliftMax]            FLOAT (53)    NULL,
    [BrandID]              SMALLINT      NULL,
    [OnlineDefault]        BIT           NOT NULL,
    [AccountManager]       VARCHAR (50)  NOT NULL,
    [FlashReportVariation] FLOAT (53)    NOT NULL,
    CONSTRAINT [PK_BI_Retailer] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [DF_BI_Retailer_RetailerNameUnique] UNIQUE NONCLUSTERED ([RetailerName] ASC)
);

