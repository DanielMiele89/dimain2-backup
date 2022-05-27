CREATE TABLE [Relational].[AccountActivityExceptions_PfL] (
    [Exceptions_PfL_ID] INT     NOT NULL,
    [FanID]             INT     NOT NULL,
    [ReasonID]          TINYINT NOT NULL,
    [StartDate]         DATE    NOT NULL,
    [EndDate]           DATE    NULL,
    PRIMARY KEY CLUSTERED ([Exceptions_PfL_ID] ASC),
    UNIQUE NONCLUSTERED ([Exceptions_PfL_ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_AccountActivityExceptions_PfL_FanID]
    ON [Relational].[AccountActivityExceptions_PfL]([FanID] ASC);

