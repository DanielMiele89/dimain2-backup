CREATE TABLE [SmartEmail].[SubjectLineTestGroup] (
    [ID]                     INT           IDENTITY (1, 1) NOT NULL,
    [SubjectLineTestID]      INT           NULL,
    [SubjectLineTestGroupID] INT           NULL,
    [Name]                   VARCHAR (50)  NULL,
    [CustomerTable]          VARCHAR (100) NULL,
    [SubjectLine]            VARCHAR (50)  NULL,
    [ClubID]                 INT           NULL,
    [IsLoyalty]              BIT           NULL,
    [ClubCashAvailableMin]   FLOAT (53)    NULL,
    [ClubCashAvailableMax]   FLOAT (53)    NULL
);




GO
GRANT VIEW DEFINITION
    ON OBJECT::[SmartEmail].[SubjectLineTestGroup] TO [New_PIIRemoved]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[SmartEmail].[SubjectLineTestGroup] TO [New_PIIRemoved]
    AS [dbo];

