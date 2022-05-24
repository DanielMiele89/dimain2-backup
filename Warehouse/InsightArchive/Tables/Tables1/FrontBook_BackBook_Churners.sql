CREATE TABLE [InsightArchive].[FrontBook_BackBook_Churners] (
    [FanID]          INT  NOT NULL,
    [CINID]          INT  NOT NULL,
    [ActivatedDate]  DATE NULL,
    [DeactivateDate] DATE NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

