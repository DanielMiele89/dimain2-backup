CREATE TABLE [Derived].[__SmartFocusUnSubscribes_Archived] (
    [FanID]     INT            NOT NULL,
    [email]     NVARCHAR (150) NOT NULL,
    [StartDate] DATE           NOT NULL,
    [EndDate]   DATE           NULL,
    CONSTRAINT [pk_EmailStart] PRIMARY KEY CLUSTERED ([email] ASC, [StartDate] ASC) WITH (FILLFACTOR = 80)
);

