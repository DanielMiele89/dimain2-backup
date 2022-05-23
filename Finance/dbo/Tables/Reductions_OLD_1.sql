CREATE TABLE [dbo].[Reductions_OLD] (
    [ReductionID]             INT           IDENTITY (1, 1) NOT NULL,
    [ReductionSourceSystemID] TINYINT       NOT NULL,
    [ReductionSourceID]       INT           NOT NULL,
    [ReductionTypeID]         TINYINT       NOT NULL,
    [CustomerID]              INT           NOT NULL,
    [ReductionValue]          MONEY         NOT NULL,
    [ReductionDate]           DATE          NOT NULL,
    [CreatedDateTime]         DATETIME2 (7) CONSTRAINT [DF_Reductions_CreatedDateTime] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_Reductions_OLD] PRIMARY KEY CLUSTERED ([ReductionID] ASC),
    CONSTRAINT [FK_Reductions_ReductionSourceSystemID_OLD] FOREIGN KEY ([ReductionSourceSystemID]) REFERENCES [dbo].[ReductionSourceSystem_OLD] ([ReductionSourceSystemID])
);

