CREATE TABLE [Prototype].[ROCP2_PublisherCombinations] (
    [WeekID]    SMALLINT      NOT NULL,
    [Publisher] VARCHAR (100) NULL,
    [Segment]   VARCHAR (100) NULL,
    [CycleID]   SMALLINT      NULL,
    [PeriodID]  SMALLINT      NULL
);


GO
CREATE NONCLUSTERED INDEX [IDX_Per]
    ON [Prototype].[ROCP2_PublisherCombinations]([PeriodID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_CID]
    ON [Prototype].[ROCP2_PublisherCombinations]([CycleID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_S]
    ON [Prototype].[ROCP2_PublisherCombinations]([Segment] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_PID]
    ON [Prototype].[ROCP2_PublisherCombinations]([Publisher] ASC);


GO
CREATE CLUSTERED INDEX [IDX_WID]
    ON [Prototype].[ROCP2_PublisherCombinations]([WeekID] ASC);

