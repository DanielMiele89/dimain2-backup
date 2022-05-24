CREATE TABLE [SmartEmail].[SubjectLineTestCustomers] (
    [ID]                     INT    IDENTITY (1, 1) NOT NULL,
    [SubjectLineTestID]      INT    NULL,
    [SubjectLineTestGroupID] INT    NULL,
    [FanID]                  BIGINT NULL
);


GO
GRANT VIEW DEFINITION
    ON OBJECT::[SmartEmail].[SubjectLineTestCustomers] TO [New_PIIRemoved]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[SmartEmail].[SubjectLineTestCustomers] TO [New_PIIRemoved]
    AS [dbo];

