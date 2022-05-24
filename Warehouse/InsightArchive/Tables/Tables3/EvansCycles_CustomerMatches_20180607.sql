CREATE TABLE [InsightArchive].[EvansCycles_CustomerMatches_20180607] (
    [FanID]              INT           NOT NULL,
    [Email]              VARCHAR (100) NULL,
    [EmailHashed_Reward] VARCHAR (64)  NULL
);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[EvansCycles_CustomerMatches_20180607] TO [New_PIIRemoved]
    AS [dbo];

