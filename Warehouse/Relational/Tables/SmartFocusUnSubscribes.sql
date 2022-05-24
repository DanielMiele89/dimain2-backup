CREATE TABLE [Relational].[SmartFocusUnSubscribes] (
    [FanID]     INT            NOT NULL,
    [email]     NVARCHAR (150) NOT NULL,
    [StartDate] DATE           NOT NULL,
    [EndDate]   DATE           NULL,
    CONSTRAINT [pk_EmailStart] PRIMARY KEY CLUSTERED ([email] ASC, [StartDate] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[SmartFocusUnSubscribes]([FanID] ASC);

