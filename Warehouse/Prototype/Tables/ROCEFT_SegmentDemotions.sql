CREATE TABLE [Prototype].[ROCEFT_SegmentDemotions] (
    [ID]                  INT IDENTITY (1, 1) NOT NULL,
    [DateRow]             INT NULL,
    [BrandID]             INT NULL,
    [CurrentSegmentation] INT NULL,
    [NewSegmentation]     INT NULL,
    [Demotion]            INT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

