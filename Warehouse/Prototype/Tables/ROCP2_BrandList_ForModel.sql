CREATE TABLE [Prototype].[ROCP2_BrandList_ForModel] (
    [BrandName]   VARCHAR (150) NULL,
    [BrandID]     SMALLINT      NOT NULL,
    [AcquireL]    SMALLINT      NULL,
    [LapserL]     SMALLINT      NULL,
    [Acquire_Pct] INT           NULL,
    PRIMARY KEY CLUSTERED ([BrandID] ASC)
);

