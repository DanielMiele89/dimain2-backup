CREATE TABLE [Relational].[CustomerCards_PfL] (
    [CustomerCards_PfL_ID] INT  IDENTITY (1, 1) NOT NULL,
    [FanID]                INT  NOT NULL,
    [PrimaryCard]          BIT  NOT NULL,
    [NonPrimaryCards]      INT  NOT NULL,
    [StartDate]            DATE NULL,
    [EndDate]              DATE NULL,
    PRIMARY KEY CLUSTERED ([CustomerCards_PfL_ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_CustomerCards_PfL_FanID]
    ON [Relational].[CustomerCards_PfL]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CustomerCards_PfL_StartDate]
    ON [Relational].[CustomerCards_PfL]([StartDate] ASC);

