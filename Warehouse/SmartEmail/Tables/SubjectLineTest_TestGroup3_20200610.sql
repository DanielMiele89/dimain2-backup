CREATE TABLE [SmartEmail].[SubjectLineTest_TestGroup3_20200610] (
    [FanID] INT NOT NULL
);




GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [SmartEmail].[SubjectLineTest_TestGroup3_20200610]([FanID] ASC);


GO
GRANT VIEW DEFINITION
    ON OBJECT::[SmartEmail].[SubjectLineTest_TestGroup3_20200610] TO [New_PIIRemoved]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[SmartEmail].[SubjectLineTest_TestGroup3_20200610] TO [New_PIIRemoved]
    AS [dbo];

