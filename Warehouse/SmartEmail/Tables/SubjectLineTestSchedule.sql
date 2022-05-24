CREATE TABLE [SmartEmail].[SubjectLineTestSchedule] (
    [ID]                     INT          IDENTITY (1, 1) NOT NULL,
    [SubjectLineTestID]      INT          NULL,
    [SubjectLineTestGroupID] INT          NULL,
    [EmailDate]              DATE         NULL,
    [SubjectLineType]        VARCHAR (50) NULL,
    [LionSendID]             INT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT VIEW DEFINITION
    ON OBJECT::[SmartEmail].[SubjectLineTestSchedule] TO [New_PIIRemoved]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[SmartEmail].[SubjectLineTestSchedule] TO [New_PIIRemoved]
    AS [dbo];

