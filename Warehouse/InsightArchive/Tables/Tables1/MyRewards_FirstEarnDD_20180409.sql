CREATE TABLE [InsightArchive].[MyRewards_FirstEarnDD_20180409] (
    [Customer ID]         INT            NOT NULL,
    [Email]               NVARCHAR (100) NOT NULL,
    [MyRewardAccount]     VARCHAR (40)   NULL,
    [FirstEarnType]       VARCHAR (22)   NOT NULL,
    [ActualFirstEarnDate] DATE           NOT NULL,
    [FirstEarnDate]       DATETIME       NULL
);

