CREATE TABLE [InsightArchive].[RiverIsland_AllExcludingMenswear_FanIDs_20171030] (
    [ID]          VARCHAR (50)  NULL,
    [HashedEmail] VARCHAR (500) NULL,
    [FanID]       INT           NOT NULL,
    [Email]       VARCHAR (30)  NULL
);


GO
CREATE CLUSTERED INDEX [cix_RI_MenswearActive_FanID]
    ON [InsightArchive].[RiverIsland_AllExcludingMenswear_FanIDs_20171030]([FanID] ASC);

