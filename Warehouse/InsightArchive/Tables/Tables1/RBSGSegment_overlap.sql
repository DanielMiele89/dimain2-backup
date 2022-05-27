CREATE TABLE [InsightArchive].[RBSGSegment_overlap] (
    [ID]              INT         IDENTITY (1, 1) NOT NULL,
    [FanID]           INT         NULL,
    [CustomerSegment] VARCHAR (5) NULL,
    [StartDate]       DATE        NULL,
    [EndDate]         DATE        NULL
);

