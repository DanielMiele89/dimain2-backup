CREATE TABLE [Staging].[Customer_ReducedFrequencySegmentation] (
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [Fanid]             INT          NOT NULL,
    [RunDate]           DATE         NOT NULL,
    [EngagementSegment] VARCHAR (20) NULL,
    [OverrideSegment]   SMALLINT     NOT NULL,
    [FrequencySegment]  VARCHAR (20) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ReducedFrequencySegmentation_FanIDRunDate]
    ON [Staging].[Customer_ReducedFrequencySegmentation]([Fanid] ASC, [RunDate] ASC)
    INCLUDE([FrequencySegment]) WITH (FILLFACTOR = 80);

