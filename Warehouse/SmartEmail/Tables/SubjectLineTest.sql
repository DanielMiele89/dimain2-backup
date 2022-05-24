CREATE TABLE [SmartEmail].[SubjectLineTest] (
    [ID]                  INT          IDENTITY (1, 1) NOT NULL,
    [SubjectLineTestID]   INT          NULL,
    [SubjectLineTestName] VARCHAR (50) NULL
);


GO
GRANT VIEW DEFINITION
    ON OBJECT::[SmartEmail].[SubjectLineTest] TO [New_PIIRemoved]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[SmartEmail].[SubjectLineTest] TO [New_PIIRemoved]
    AS [dbo];

