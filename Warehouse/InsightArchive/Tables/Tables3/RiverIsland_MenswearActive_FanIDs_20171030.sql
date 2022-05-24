CREATE TABLE [InsightArchive].[RiverIsland_MenswearActive_FanIDs_20171030] (
    [Column 0] VARCHAR (50)  NULL,
    [Column 1] VARCHAR (500) NULL,
    [FanID]    INT           NOT NULL,
    [Email]    VARCHAR (30)  NULL
);


GO
CREATE CLUSTERED INDEX [cix_RI_MenswearActive_FanID]
    ON [InsightArchive].[RiverIsland_MenswearActive_FanIDs_20171030]([FanID] ASC);

