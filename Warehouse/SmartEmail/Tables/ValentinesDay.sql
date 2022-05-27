CREATE TABLE [SmartEmail].[ValentinesDay] (
    [FanID]       INT         NOT NULL,
    [TestSplit]   VARCHAR (1) NOT NULL,
    [ControlFlag] INT         NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [SmartEmail].[ValentinesDay]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_TestSplitFanID]
    ON [SmartEmail].[ValentinesDay]([TestSplit] ASC, [FanID] ASC);

