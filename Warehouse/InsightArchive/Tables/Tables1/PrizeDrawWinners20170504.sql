CREATE TABLE [InsightArchive].[PrizeDrawWinners20170504] (
    [FanID]     INT           NOT NULL,
    [ClubID]    INT           NULL,
    [FirstName] VARCHAR (50)  NULL,
    [Lastname]  VARCHAR (50)  NULL,
    [Email]     VARCHAR (100) NULL,
    [Address1]  VARCHAR (100) NULL,
    [Address2]  VARCHAR (100) NULL,
    [City]      VARCHAR (100) NULL,
    [County]    VARCHAR (100) NULL,
    [Postcode]  VARCHAR (10)  NULL,
    [Prize]     VARCHAR (45)  NOT NULL
);

