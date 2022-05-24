CREATE TABLE [Relational].[Customer_RBSGSegments] (
    [ID]              INT         IDENTITY (1, 1) NOT NULL,
    [FanID]           INT         NULL,
    [CustomerSegment] VARCHAR (5) NULL,
    [StartDate]       DATE        NULL,
    [EndDate]         DATE        NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Customer_RBSGSegments_FanID_EndDate]
    ON [Relational].[Customer_RBSGSegments]([FanID] ASC, [EndDate] ASC)
    INCLUDE([CustomerSegment]);

