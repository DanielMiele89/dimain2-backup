CREATE TABLE [SmartEmail].[SubjectLineTest_TestGroup3_20200610] (
    [FanID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [SmartEmail].[SubjectLineTest_TestGroup3_20200610]([FanID] ASC);

