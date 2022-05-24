CREATE TABLE [SmartEmail].[ValentinesDay_ControlGroup] (
    [FanID]       INT         NOT NULL,
    [TestSplit]   VARCHAR (1) NOT NULL,
    [ControlFlag] INT         NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [SmartEmail].[ValentinesDay_ControlGroup]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_TestSplitFanID]
    ON [SmartEmail].[ValentinesDay_ControlGroup]([TestSplit] ASC, [FanID] ASC);

