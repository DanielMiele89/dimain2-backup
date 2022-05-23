CREATE TABLE [dbo].[RedemptionIntervals_HR] (
    [CustomerID]     INT          NOT NULL,
    [RedemptionPin]  BIGINT       NULL,
    [ReductionDate]  VARCHAR (10) NOT NULL,
    [ReductionID]    BIGINT       NULL,
    [ReductionValue] INT          NOT NULL,
    [R_From]         INT          NULL,
    [R_to]           INT          NULL,
    [MinPin]         BIGINT       NULL,
    [MaxPin]         BIGINT       NULL,
    [EndEarnings]    MONEY        NULL,
    [Carry]          VARCHAR (1)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_Stuff]
    ON [dbo].[RedemptionIntervals_HR]([CustomerID] ASC, [RedemptionPin] ASC) WITH (FILLFACTOR = 90);


GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_Stuff]
    ON [dbo].[RedemptionIntervals_HR]([CustomerID] ASC, [ReductionDate] ASC, [ReductionID] ASC)
    INCLUDE([ReductionValue], [R_to], [R_From], [MinPin], [MaxPin], [EndEarnings], [Carry]) WITH (FILLFACTOR = 90);

