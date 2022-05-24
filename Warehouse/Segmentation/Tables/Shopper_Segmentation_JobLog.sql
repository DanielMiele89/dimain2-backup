CREATE TABLE [Segmentation].[Shopper_Segmentation_JobLog] (
    [ID]                  INT           IDENTITY (1, 1) NOT NULL,
    [StoredProcedureName] VARCHAR (250) NOT NULL,
    [StartDate]           DATETIME      NOT NULL,
    [EndDate]             DATETIME      NOT NULL,
    [Duration]            VARCHAR (5)   NOT NULL,
    [PartnerID]           INT           NOT NULL,
    [ShopperCount]        INT           NULL,
    [LapsedCount]         INT           NULL,
    [AcquireCount]        INT           NOT NULL,
    [IsRanked]            INT           NULL,
    [LapsedDate]          INT           NOT NULL,
    [AcquireDate]         INT           NOT NULL,
    [ErrorCode]           INT           NULL,
    [ErrorMessage]        VARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

