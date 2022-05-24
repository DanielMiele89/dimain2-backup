CREATE TABLE [InsightArchive].[MyRewardsDMStatementFile1] (
    [CIN]                  VARCHAR (50)  NULL,
    [Bank]                 VARCHAR (50)  NULL,
    [Customer type]        VARCHAR (50)  NULL,
    [Title]                VARCHAR (50)  NULL,
    [FirstName]            VARCHAR (50)  NULL,
    [Lastname]             VARCHAR (50)  NULL,
    [Address1]             VARCHAR (100) NULL,
    [Address2]             VARCHAR (50)  NULL,
    [City]                 VARCHAR (50)  NULL,
    [Postcode]             VARCHAR (50)  NULL,
    [Balance]              VARCHAR (50)  NULL,
    [Pending]              VARCHAR (50)  NULL,
    [DD_Earnings]          VARCHAR (50)  NULL,
    [DC_Earnings]          VARCHAR (50)  NULL,
    [CC_Earnings]          VARCHAR (50)  NULL,
    [Reward Credit card]   VARCHAR (50)  NULL,
    [Household bill]       VARCHAR (50)  NULL,
    [Joint account holder] VARCHAR (50)  NULL,
    [Type]                 VARCHAR (50)  NULL
);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[MyRewardsDMStatementFile1] TO [New_PIIRemoved]
    AS [dbo];

