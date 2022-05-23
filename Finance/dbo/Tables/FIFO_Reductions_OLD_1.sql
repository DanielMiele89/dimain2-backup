CREATE TABLE [dbo].[FIFO_Reductions_OLD] (
    [ReductionID]     INT     NULL,
    [ReductionTypeID] TINYINT NOT NULL,
    [CustomerID]      INT     NOT NULL,
    [ReductionValue]  MONEY   NOT NULL,
    [ReductionDate]   DATE    NOT NULL
);

